const crypto = require('crypto');
const { Session } = require('../models/models');

const tokenHash = (token) => crypto.createHash('sha256').update(token).digest('hex');

const requireAuth = async (req, res, next) => {
  const authorization = req.get('authorization') || '';
  const match = authorization.match(/^Bearer ([a-f0-9]{64})$/i);
  if (!match) {
    return res.status(401).json({ message: 'Authentication required.' });
  }

  try {
    const hash = tokenHash(match[1]);
    const session = await Session.findOne({
      token_hash: hash,
      expires_at: { $gt: new Date() },
    }).lean();
    if (!session) {
      return res.status(401).json({ message: 'Session is invalid or expired.' });
    }
    req.adminId = session.admin_id;
    req.sessionTokenHash = hash;
    return next();
  } catch (error) {
    return next(error);
  }
};

module.exports = requireAuth;
