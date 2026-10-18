const { getModel } = require('../models/resourceRegistry');

const normalize = (value) => {
  if (value && typeof value.toObject === 'function') return value.toObject();
  return value;
};
const list = (resource) => async (req, res, next) => {
  try {
    const Model = getModel(resource);
    const filter = {};
    if (req.query.search) filter.name = { $regex: req.query.search, $options: 'i' };
    if (req.query.category_id) filter.category_id = Number(req.query.category_id);
    if (req.query.active_only === 'true') filter.is_active = 1;
    if (req.query.status) filter.status = req.query.status;
    const rows = await Model.find(filter).sort({ name: 1, order_date: -1 }).lean();
    res.json({ data: rows });
  } catch (error) { next(error); }
};
const get = (resource) => async (req, res, next) => {
  try { const row = await getModel(resource).findOne({ id: Number(req.params.id) }).lean(); if (!row) return res.status(404).json({ message: 'Record not found' }); res.json({ data: row }); } catch (error) { next(error); }
};
const save = (resource) => async (req, res, next) => {
  try {
    const Model = getModel(resource);
    const id = req.params.id ? Number(req.params.id) : await nextId(Model);
    const row = await Model.findOneAndUpdate({ id }, { ...req.body, id }, { upsert: true, new: true, setDefaultsOnInsert: true }).lean();
    res.status(req.params.id ? 200 : 201).json({ data: row });
  } catch (error) { next(error); }
};
const remove = (resource) => async (req, res, next) => {
  try { await getModel(resource).deleteOne({ id: Number(req.params.id) }); res.status(204).end(); } catch (error) { next(error); }
};
const nextId = async (Model) => ((await Model.findOne().sort({ id: -1 }).select('id').lean())?.id || 0) + 1;
module.exports = { list, get, save, remove, normalize, nextId };
