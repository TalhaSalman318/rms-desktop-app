const express = require('express');
const { dashboard, report, calendar } = require('../controllers/analyticsController');
const router = express.Router();
router.get('/dashboard', dashboard);
router.get('/reports', report);
router.get('/calendar', calendar);
module.exports = router;
