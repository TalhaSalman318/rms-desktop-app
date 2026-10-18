require('dotenv').config();

const cors = require('cors');
const express = require('express');
const connectDatabase = require('./config/database');
const healthRoutes = require('./routes/healthRoutes');
const authRoutes = require('./routes/authRoutes');
const orderRoutes = require('./routes/orderRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');
const resourceRoutes = require('./routes/resourceRoutes');
const requireAuth = require('./middleware/requireAuth');
const { ensureAdmin } = require('./controllers/authController');

const app = express();
const port = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());

app.use('/api/health', healthRoutes);
app.use('/api/auth', authRoutes);
app.use('/api', requireAuth);
app.use('/api/orders', orderRoutes);
app.use('/api/analytics', analyticsRoutes);
for (const resource of ['categories', 'products', 'expense_categories', 'expenses', 'deals']) {
  app.use(`/api/${resource}`, resourceRoutes(resource));
}

app.use((error, _req, res, _next) => {
  console.error(error);
  res.status(error.status || 500).json({ message: error.message || 'Internal server error' });
});

const startServer = async () => {
  await connectDatabase();
  await ensureAdmin();

  app.listen(port, () => {
    console.log(`RMS Backend is running on port ${port}`);
  });
};

startServer();