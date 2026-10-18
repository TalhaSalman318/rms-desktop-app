const mongoose = require('mongoose');
const Order = require('./Order');

const base = { id: { type: Number, unique: true, index: true }, created_at: { type: String, default: () => new Date().toISOString() } };
const schema = (fields) => new mongoose.Schema(
  { ...base, ...fields },
  {
    versionKey: false,
    toJSON: { transform: (_doc, ret) => { delete ret._id; return ret; } },
    toObject: { transform: (_doc, ret) => { delete ret._id; return ret; } },
  },
);
const make = (name, fields) => mongoose.models[name] || mongoose.model(name, schema(fields), name.toLowerCase());
const sessionSchema = new mongoose.Schema(
  {
    token_hash: { type: String, required: true, unique: true },
    admin_id: { type: Number, required: true },
    expires_at: { type: Date, required: true },
    password_change_required: { type: Boolean, default: false },
  },
  { versionKey: false },
);
sessionSchema.index({ expires_at: 1 }, { expireAfterSeconds: 0 });

module.exports = {
  Admin: make('Admin', { username: { type: String, unique: true, required: true }, password: { type: String, required: true } }),
  Session: mongoose.models.Session || mongoose.model('Session', sessionSchema, 'sessions'),
  Category: make('Category', { name: { type: String, unique: true, required: true } }),
  Product: make('Product', { name: String, category_id: Number, price: Number, description: { type: String, default: '' }, is_active: { type: Number, default: 1 } }),
  Order,
  ExpenseCategory: make('ExpenseCategory', { name: { type: String, unique: true, required: true } }),
  Expense: make('Expense', { expense_category_id: Number, amount: Number, description: { type: String, default: '' }, expense_date: String }),
  Deal: make('Deal', { name: String, description: { type: String, default: '' }, normal_price: Number, deal_price: Number, is_active: { type: Number, default: 1 }, items: Array }),
};
