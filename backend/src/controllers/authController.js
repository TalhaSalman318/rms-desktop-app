const crypto = require('crypto');
const { Admin, Session } = require('../models/models');
const { nextId } = require('./resourceController');

const SESSION_DURATION_MS = 30 * 24 * 60 * 60 * 1000;
const legacyHash = (password) =>
  crypto.createHash('sha256').update(password).digest('hex');
const createPasswordHash = (password) =>
  new Promise((resolve, reject) => {
    const salt = crypto.randomBytes(16);
    crypto.scrypt(password, salt, 64, (error, derivedKey) => {
      if (error) return reject(error);
      resolve(`scrypt$${salt.toString('hex')}$${derivedKey.toString('hex')}`);
    });
  });
const verifyPassword = async (password, storedHash) => {
  if (storedHash.startsWith('scrypt$')) {
    const [, saltHex, hashHex] = storedHash.split('$');
    if (!saltHex || !hashHex) return false;
    const salt = Buffer.from(saltHex, 'hex');
    const expected = Buffer.from(hashHex, 'hex');
    if (salt.length !== 16 || expected.length !== 64) return false;
    const actual = await new Promise((resolve, reject) => {
      crypto.scrypt(password, salt, expected.length, (error, result) => {
        if (error) return reject(error);
        resolve(result);
      });
    });
    return crypto.timingSafeEqual(expected, actual);
  }
  const expected = Buffer.from(storedHash, 'hex');
  const actual = Buffer.from(legacyHash(password), 'hex');
  return expected.length === actual.length && crypto.timingSafeEqual(expected, actual);
};
const tokenHash = (token) => crypto.createHash('sha256').update(token).digest('hex');
const publicAdmin = (admin, requiresPasswordChange = false) => ({
  id: admin.id,
  username: admin.username,
  created_at: admin.created_at,
  requires_password_change: requiresPasswordChange,
});

const ensureAdmin = async () => {
  if (await Admin.exists({})) return;

  const username = process.env.INITIAL_ADMIN_USERNAME?.trim() || 'admin';
  const password = process.env.INITIAL_ADMIN_PASSWORD;
  if (!password || password.length < 12) {
    throw new Error(
      'Set INITIAL_ADMIN_PASSWORD to a value of at least 12 characters before starting with an empty database.',
    );
  }
  await Admin.create({
    id: await nextId(Admin),
    username,
    password: await createPasswordHash(password),
  });
};

const login = async (req, res, next) => {
  try {
    const username =
      typeof req.body?.username === 'string' ? req.body.username.trim() : '';
    const password =
      typeof req.body?.password === 'string' ? req.body.password : '';
    if (!username || !password) {
      return res.status(400).json({ message: 'Username and password are required.' });
    }

    const admin = await Admin.findOne({ username });
    if (!admin || !(await verifyPassword(password, admin.password))) {
      return res.status(401).json({ message: 'Invalid username or password.' });
    }

    if (!admin.password.startsWith('scrypt$')) {
      admin.password = await createPasswordHash(password);
      await admin.save();
    }

    const token = crypto.randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + SESSION_DURATION_MS);
    await Session.create({
      token_hash: tokenHash(token),
      admin_id: admin.id,
      expires_at: expiresAt,
      password_change_required: false,
    });
    return res.json({
      data: {
        token,
        expires_at: expiresAt.toISOString(),
        admin: publicAdmin(admin),
      },
    });
  } catch (error) {
    return next(error);
  }
};

const currentAdmin = async (req, res, next) => {
  try {
    const admin = await Admin.findOne({ id: req.adminId }).lean();
    if (!admin) return res.status(401).json({ message: 'Admin account not found.' });
    return res.json({ data: publicAdmin(admin) });
  } catch (error) {
    return next(error);
  }
};

const logout = async (req, res, next) => {
  try {
    await Session.deleteOne({ token_hash: req.sessionTokenHash });
    return res.status(204).end();
  } catch (error) {
    return next(error);
  }
};

const password = async (req, res, next) => {
  try {
    const currentPassword =
      typeof req.body?.current_password === 'string'
        ? req.body.current_password
        : '';
    const newPassword =
      typeof req.body?.new_password === 'string' ? req.body.new_password : '';
    if (newPassword.length < 12) {
      return res.status(400).json({
        message: 'New password must be at least 12 characters long.',
      });
    }

    const admin = await Admin.findOne({ id: req.adminId });
    if (!admin || !(await verifyPassword(currentPassword, admin.password))) {
      return res.status(400).json({ message: 'Current password is incorrect.' });
    }

    admin.password = await createPasswordHash(newPassword);
    await admin.save();
    await Session.deleteMany({ admin_id: admin.id });
    return res.json({ data: { changed: true } });
  } catch (error) {
    return next(error);
  }
};

module.exports = { ensureAdmin, login, currentAdmin, logout, password };
