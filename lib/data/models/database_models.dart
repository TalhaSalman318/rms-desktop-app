class Admin {
  const Admin({
    this.id,
    required this.username,
    required this.password,
    this.createdAt,
  });

  final int? id;
  final String username;
  final String password;
  final String? createdAt;

  factory Admin.fromMap(Map<String, Object?> map) => Admin(
    id: map['id'] as int?,
    username: map['username'] as String,
    password: map['password'] as String,
    createdAt: map['created_at'] as String?,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'username': username,
    'password': password,
    'created_at': createdAt,
  };
}

class Category {
  const Category({this.id, required this.name, this.createdAt});

  final int? id;
  final String name;
  final String? createdAt;

  factory Category.fromMap(Map<String, Object?> map) => Category(
    id: map['id'] as int?,
    name: map['name'] as String,
    createdAt: map['created_at'] as String?,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'created_at': createdAt,
  };
}

class Product {
  const Product({
    this.id,
    required this.name,
    required this.categoryId,
    required this.price,
    this.description = '',
    this.isActive = true,
    this.createdAt,
  });

  final int? id;
  final String name;
  final int categoryId;
  final double price;
  final String description;
  final bool isActive;
  final String? createdAt;

  factory Product.fromMap(Map<String, Object?> map) => Product(
    id: map['id'] as int?,
    name: map['name'] as String,
    categoryId: map['category_id'] as int,
    price: (map['price'] as num).toDouble(),
    description: map['description'] as String? ?? '',
    isActive: (map['is_active'] as int) == 1,
    createdAt: map['created_at'] as String?,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'category_id': categoryId,
    'price': price,
    'description': description,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt,
  };
}

class Order {
  const Order({
    this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.subtotal,
    this.discount = 0,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    this.createdAt,
  });

  final int? id;
  final int orderNumber;
  final String orderDate;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final String? createdAt;

  factory Order.fromMap(Map<String, Object?> map) => Order(
    id: map['id'] as int?,
    orderNumber: map['order_number'] as int,
    orderDate: map['order_date'] as String,
    subtotal: (map['subtotal'] as num).toDouble(),
    discount: (map['discount'] as num).toDouble(),
    totalAmount: (map['total_amount'] as num).toDouble(),
    paymentMethod: map['payment_method'] as String,
    status: map['status'] as String,
    createdAt: map['created_at'] as String?,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'order_number': orderNumber,
    'order_date': orderDate,
    'subtotal': subtotal,
    'discount': discount,
    'total_amount': totalAmount,
    'payment_method': paymentMethod,
    'status': status,
    'created_at': createdAt,
  };
}

class OrderItem {
  const OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.dealId,
    this.dealName,
  });

  final int? id;
  final int orderId;
  final int productId;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final int? dealId;
  final String? dealName;

  factory OrderItem.fromMap(Map<String, Object?> map) => OrderItem(
    id: map['id'] as int?,
    orderId: map['order_id'] as int,
    productId: map['product_id'] as int,
    quantity: map['quantity'] as int,
    unitPrice: (map['unit_price'] as num).toDouble(),
    subtotal: (map['subtotal'] as num).toDouble(),
    dealId: map['deal_id'] as int?,
    dealName: map['deal_name'] as String?,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'order_id': orderId,
    'product_id': productId,
    'quantity': quantity,
    'unit_price': unitPrice,
    'subtotal': subtotal,
    'deal_id': dealId,
    'deal_name': dealName,
  };
}

class ExpenseCategory {
  const ExpenseCategory({this.id, required this.name, this.createdAt});

  final int? id;
  final String name;
  final String? createdAt;

  factory ExpenseCategory.fromMap(Map<String, Object?> map) => ExpenseCategory(
    id: map['id'] as int?,
    name: map['name'] as String,
    createdAt: map['created_at'] as String?,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'created_at': createdAt,
  };
}

class Expense {
  const Expense({
    this.id,
    required this.expenseCategoryId,
    required this.amount,
    this.description = '',
    required this.expenseDate,
    this.createdAt,
  });

  final int? id;
  final int expenseCategoryId;
  final double amount;
  final String description;
  final String expenseDate;
  final String? createdAt;

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
    id: map['id'] as int?,
    expenseCategoryId: map['expense_category_id'] as int,
    amount: (map['amount'] as num).toDouble(),
    description: map['description'] as String? ?? '',
    expenseDate: map['expense_date'] as String,
    createdAt: map['created_at'] as String?,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'expense_category_id': expenseCategoryId,
    'amount': amount,
    'description': description,
    'expense_date': expenseDate,
    'created_at': createdAt,
  };
}

class Deal {
  const Deal({
    this.id,
    required this.name,
    this.description = '',
    required this.normalPrice,
    required this.dealPrice,
    this.isActive = true,
    this.createdAt,
  });

  final int? id;
  final String name;
  final String description;
  final double normalPrice;
  final double dealPrice;
  final bool isActive;
  final String? createdAt;

  factory Deal.fromMap(Map<String, Object?> map) => Deal(
    id: map['id'] as int?,
    name: map['name'] as String,
    description: map['description'] as String? ?? '',
    normalPrice: (map['normal_price'] as num).toDouble(),
    dealPrice: (map['deal_price'] as num).toDouble(),
    isActive: (map['is_active'] as int) == 1,
    createdAt: map['created_at'] as String?,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'normal_price': normalPrice,
    'deal_price': dealPrice,
    'is_active': isActive ? 1 : 0,
    'created_at': createdAt,
  };
}

class DealItem {
  const DealItem({
    this.id,
    required this.dealId,
    required this.productId,
    required this.quantity,
  });

  final int? id;
  final int dealId;
  final int productId;
  final int quantity;

  factory DealItem.fromMap(Map<String, Object?> map) => DealItem(
    id: map['id'] as int?,
    dealId: map['deal_id'] as int,
    productId: map['product_id'] as int,
    quantity: map['quantity'] as int,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'deal_id': dealId,
    'product_id': productId,
    'quantity': quantity,
  };
}
