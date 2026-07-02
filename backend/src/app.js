const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { Sequelize } = require('sequelize');
const http = require('http');
const { Server } = require('socket.io');

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: '*',
  },
});

app.set('io', io);
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Database Connection
const sequelize = new Sequelize(
  process.env.DB_NAME || 'iot_platform_db',
  process.env.DB_USER || 'root',
  process.env.DB_PASSWORD || '',
  {
    host: process.env.DB_HOST || 'localhost',
    dialect: 'mysql',
  }
);

// Basic Route
app.get('/', (req, res) => {
  res.send('IoT Platform Backend API is running...');
});

// Import Routes
const authRoutes = require('./routes/auth.routes');
const projectRoutes = require('./routes/project.routes');
const githubRoutes = require('./routes/github.routes');
const realtimeRoutes = require('./routes/realtime.routes');

app.use('/api/auth', authRoutes);
app.use('/api/projects', projectRoutes);
app.use('/api/projects', githubRoutes);
app.use('/api/realtime', realtimeRoutes);
app.use('/', realtimeRoutes);

io.on('connection', (socket) => {
  console.log(`Realtime client connected: ${socket.id}`);
  socket.on('disconnect', () => {
    console.log(`Realtime client disconnected: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 5000;

server.listen(PORT, async () => {
  console.log(`Server is running on port ${PORT}`);
  try {
    await sequelize.authenticate();
    console.log('Database connection has been established successfully.');
  } catch (error) {
    console.error('Unable to connect to the database:', error);
  }
});
