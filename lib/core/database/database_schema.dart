abstract final class DatabaseSchema {
  static const migrationVersion = 2;
  static const createTables = <String>[
    '''CREATE TABLE admins (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      category_id INTEGER NOT NULL,
      price REAL NOT NULL CHECK (price >= 0),
      description TEXT NOT NULL DEFAULT '',
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT
    )''',
    '''CREATE TABLE orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_number INTEGER NOT NULL UNIQUE,
      order_date TEXT NOT NULL,
      subtotal REAL NOT NULL CHECK (subtotal >= 0),
      discount REAL NOT NULL DEFAULT 0 CHECK (discount >= 0),
      total_amount REAL NOT NULL CHECK (total_amount >= 0),
      payment_method TEXT NOT NULL,
      status TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE order_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL CHECK (quantity > 0),
      unit_price REAL NOT NULL CHECK (unit_price >= 0),
      subtotal REAL NOT NULL CHECK (subtotal >= 0),
      deal_id INTEGER,
      deal_name TEXT,
      FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
    )''',
    '''CREATE TABLE expense_categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE expenses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      expense_category_id INTEGER NOT NULL,
      amount REAL NOT NULL CHECK (amount >= 0),
      description TEXT NOT NULL DEFAULT '',
      expense_date TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (expense_category_id) REFERENCES expense_categories (id) ON DELETE RESTRICT
    )''',
    '''CREATE TABLE deals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      normal_price REAL NOT NULL CHECK (normal_price >= 0),
      deal_price REAL NOT NULL CHECK (deal_price >= 0),
      is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )''',
    '''CREATE TABLE deal_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      deal_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL CHECK (quantity > 0),
      FOREIGN KEY (deal_id) REFERENCES deals (id) ON DELETE CASCADE,
      FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE RESTRICT
    )''',
  ];

  static const indexes = <String>[
    'CREATE INDEX idx_products_category_id ON products (category_id)',
    'CREATE INDEX idx_orders_order_date ON orders (order_date)',
    'CREATE INDEX idx_order_items_order_id ON order_items (order_id)',
    'CREATE INDEX idx_expenses_expense_date ON expenses (expense_date)',
    'CREATE INDEX idx_deal_items_deal_id ON deal_items (deal_id)',
  ];
}
