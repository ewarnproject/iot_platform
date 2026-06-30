const express = require('express');
const router = express.Router();

// Mock Auth Controllers
router.post('/signup', (req, res) => {
  const { username, email, password } = req.body;
  res.status(201).json({ message: 'User registered successfully', user: { username, email } });
});

router.post('/login', (req, res) => {
  const { email, password } = req.body;
  res.status(200).json({ message: 'Login successful', token: 'mock-jwt-token' });
});

module.exports = router;
