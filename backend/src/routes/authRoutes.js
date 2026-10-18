const express = require('express');
const { rateLimit } = require('express-rate-limit');
const {
  currentAdmin,
  login,
  logout,
  password,
} = require('../controllers/authController');
const requireAuth = require('../middleware/requireAuth');
const router = express.Router();
router.post(
  '/login',
  rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 10,
    standardHeaders: true,
    legacyHeaders: false,
    message: { message: 'Too many sign-in attempts. Try again later.' },
  }),
  login,
);
router.use(requireAuth);
router.get('/me', currentAdmin);
router.post('/logout', logout);
router.put('/password', password);
module.exports = router;
