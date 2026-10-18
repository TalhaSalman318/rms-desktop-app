const getHealth = (req, res) => {
  res.json({
    success: true,
    message: 'RMS Backend is running',
  });
};

module.exports = { getHealth };