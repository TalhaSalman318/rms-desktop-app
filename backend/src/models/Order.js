const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema(
  {
    id: { type: Number, unique: true, index: true },
    created_at: { type: String, default: () => new Date().toISOString() },
    order_number: Number,
    order_date: String,
    subtotal: Number,
    discount: Number,
    total_amount: Number,
    payment_method: String,
    status: { type: String, default: 'Completed' },
    order_type: {
      type: String,
      enum: ['Dine-In', 'Takeaway', 'Delivery'],
      default: 'Dine-In',
    },
    delivery_charges: { type: Number, default: 0, min: 0 },
    items: Array,
  },
  {
    versionKey: false,
    toJSON: { transform: (_doc, ret) => { delete ret._id; return ret; } },
    toObject: { transform: (_doc, ret) => { delete ret._id; return ret; } },
  },
);

module.exports = mongoose.models.Order || mongoose.model('Order', orderSchema, 'order');
