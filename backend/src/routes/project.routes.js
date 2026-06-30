const express = require('express');
const router = express.Router();
const { projects, findById } = require('../data/projects.store');

router.get('/', (req, res) => {
  res.status(200).json(projects);
});

router.get('/:id', (req, res) => {
  const project = findById(req.params.id);
  if (project) {
    res.status(200).json(project);
  } else {
    res.status(404).json({ message: 'Project not found' });
  }
});

module.exports = router;
