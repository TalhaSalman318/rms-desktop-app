const models = require('./models');
const names = {
  categories: 'Category', products: 'Product', orders: 'Order',
  expense_categories: 'ExpenseCategory', expenses: 'Expense', deals: 'Deal',
};
const getModel = (resource) => {
  const model = models[names[resource]];
  if (!model) throw new Error(`Unknown resource: ${resource}`);
  return model;
};
module.exports = { getModel };
