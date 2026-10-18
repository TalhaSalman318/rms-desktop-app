const express = require('express');
const { list, get, save, remove } = require('../controllers/resourceController');

const router = (resource) => {
  const route = express.Router();
  route.get('/', list(resource));
  route.get('/:id', get(resource));
  route.post('/', save(resource));
  route.put('/:id', save(resource));
  route.delete('/:id', remove(resource));
  return route;
};
module.exports = router;
