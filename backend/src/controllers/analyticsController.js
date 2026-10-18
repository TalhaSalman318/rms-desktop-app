const { Order, Expense, Product, Category, ExpenseCategory } = require('../models/models');

const range = (req, field) => ({
	[field]: { $gte: req.query.from || '0000', $lt: req.query.to || '9999' },
});

const amount = (value) => Number(value) || 0;

const dashboard = async (req, res, next) => {
	try {
		const orders = await Order.find({ status: 'Completed' }).lean();
		const expenses = await Expense.find().lean();
		const now = new Date();
		const day = now.toISOString().slice(0, 10);
		const month = day.slice(0, 7);
		const year = day.slice(0, 4);
		const sales = (prefix) => orders
			.filter((order) => order.order_date?.startsWith(prefix))
			.reduce((sum, order) => sum + amount(order.total_amount), 0);
		res.json({ data: {
			today_sales: sales(day),
			today_orders: orders.filter((order) => order.order_date?.startsWith(day)).length,
			month_sales: sales(month),
			month_expenses: expenses
				.filter((expense) => expense.expense_date?.startsWith(month))
				.reduce((sum, expense) => sum + amount(expense.amount), 0),
			year_sales: sales(year),
			recent_orders: orders.sort((a, b) => b.order_date.localeCompare(a.order_date)).slice(0, 5),
			top_products: [],
		} });
	} catch (error) { next(error); }
};

const report = async (req, res, next) => {
	try {
		const [orders, expenses, products, categories, expenseCategories] = await Promise.all([
			Order.find(range(req, 'order_date')).lean(),
			Expense.find(range(req, 'expense_date')).lean(),
			Product.find().lean(),
			Category.find().lean(),
			ExpenseCategory.find().lean(),
		]);
		const completed = orders.filter((order) => order.status === 'Completed');
		const productById = new Map(products.map((product) => [product.id, product]));
		const categoryById = new Map(categories.map((category) => [category.id, category]));
		const expenseCategoryById = new Map(expenseCategories.map((category) => [category.id, category]));
		const productTotals = new Map();
		const categoryTotals = new Map();
		const paymentTotals = new Map();

		for (const order of completed) {
			const payment = order.payment_method || 'Unknown';
			const paymentRow = paymentTotals.get(payment) || { payment_method: payment, orders: 0, revenue: 0 };
			paymentRow.orders += 1;
			paymentRow.revenue += amount(order.total_amount);
			paymentTotals.set(payment, paymentRow);

			for (const item of order.items || []) {
				const product = productById.get(item.product_id);
				const revenue = amount(item.subtotal) || amount(item.unit_price) * amount(item.quantity);
				const productKey = item.product_id ?? `deal-${item.deal_id ?? item.deal_name ?? 'unknown'}`;
				const productRow = productTotals.get(productKey) || {
					product_id: item.product_id,
					name: product?.name || item.deal_name || 'Unknown product',
					quantity: 0,
					revenue: 0,
				};
				productRow.quantity += amount(item.quantity);
				productRow.revenue += revenue;
				productTotals.set(productKey, productRow);

				if (product?.category_id != null) {
					const category = categoryById.get(product.category_id);
					const categoryRow = categoryTotals.get(product.category_id) || {
						category_id: product.category_id,
						name: category?.name || 'Unknown category',
						revenue: 0,
					};
					categoryRow.revenue += revenue;
					categoryTotals.set(product.category_id, categoryRow);
				}
			}
		}

		const expenseTotals = new Map();
		for (const expense of expenses) {
			const category = expenseCategoryById.get(expense.expense_category_id);
			const key = expense.expense_category_id ?? 'uncategorized';
			const row = expenseTotals.get(key) || {
				expense_category_id: expense.expense_category_id,
				name: category?.name || 'Uncategorized',
				amount: 0,
			};
			row.amount += amount(expense.amount);
			expenseTotals.set(key, row);
		}

		const trendByDate = new Map();
		for (const order of completed) {
			const date = order.order_date?.slice(0, 10) || 'Unknown';
			const row = trendByDate.get(date) || { date, sales: 0, expenses: 0, profit: 0 };
			row.sales += amount(order.total_amount);
			trendByDate.set(date, row);
		}
		for (const expense of expenses) {
			const date = expense.expense_date?.slice(0, 10) || 'Unknown';
			const row = trendByDate.get(date) || { date, sales: 0, expenses: 0, profit: 0 };
			row.expenses += amount(expense.amount);
			trendByDate.set(date, row);
		}
		const trend = [...trendByDate.values()]
			.sort((a, b) => a.date.localeCompare(b.date))
			.map((row) => ({ ...row, profit: row.sales - row.expenses }));
		const sales = completed.reduce((sum, order) => sum + amount(order.total_amount), 0);
		const totalExpenses = expenses.reduce((sum, expense) => sum + amount(expense.amount), 0);

		res.json({ data: {
			summary: {
				total_orders: orders.length,
				completed_orders: completed.length,
				pending_orders: orders.filter((order) => order.status === 'Pending').length,
				cancelled_orders: orders.filter((order) => order.status === 'Cancelled').length,
				sales,
				expenses: totalExpenses,
				discount: completed.reduce((sum, order) => sum + amount(order.discount), 0),
			},
			products: [...productTotals.values()].sort((a, b) => b.revenue - a.revenue),
			payments: [...paymentTotals.values()].sort((a, b) => b.revenue - a.revenue),
			categories: [...categoryTotals.values()].sort((a, b) => b.revenue - a.revenue),
			expense_categories: [...expenseTotals.values()].sort((a, b) => b.amount - a.amount),
			trend,
		} });
	} catch (error) { next(error); }
};

const calendar = async (req, res, next) => {
	try {
		const [orders, expenses] = await Promise.all([
			Order.find(range(req, 'order_date')).lean(),
			Expense.find(range(req, 'expense_date')).lean(),
		]);
		res.json({ data: { orders, expenses } });
	} catch (error) { next(error); }
};

module.exports = { dashboard, report, calendar };
