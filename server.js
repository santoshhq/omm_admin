const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');

const app = express();
const server = http.createServer(app);

// Initialize Socket.IO with CORS
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// MongoDB connection
mongoose.connect('mongodb://localhost:27017/omm_admin', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ MongoDB connected'))
.catch(err => console.error('❌ MongoDB connection error:', err));

// Basic route
app.get('/', (req, res) => {
  res.send('OMM Admin Backend Server with Socket.IO is running!');
});

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('🔌 New client connected:', socket.id);

  // Handle guard room joining
  socket.on('joinGuardRoom', (guardId) => {
    socket.join(`guard_${guardId}`);
    console.log(`🏢 Guard ${guardId} joined room: guard_${guardId}`);
  });

  // Handle disconnection
  socket.on('disconnect', () => {
    console.log('❌ Client disconnected:', socket.id);
  });
});

// Function to emit visitor events to guards
function emitVisitorEvent(eventType, visitorData, guardId = null) {
  const eventData = {
    type: eventType,
    visitor: visitorData,
    timestamp: new Date().toISOString()
  };

  if (guardId) {
    // Emit to specific guard room
    io.to(`guard_${guardId}`).emit(eventType, eventData);
    console.log(`📡 Emitted ${eventType} to guard_${guardId}:`, eventData);
  } else {
    // Emit to all guards
    io.emit(eventType, eventData);
    console.log(`📡 Emitted ${eventType} to all guards:`, eventData);
  }
}

// Export the emit function so other modules can use it
global.emitVisitorEvent = emitVisitorEvent;

// Mock visitor data for testing
let mockVisitors = [];

// API Routes for visitors (mock implementation)
app.get('/api/visitors', (req, res) => {
  const guardId = req.query.guardId;
  console.log(`📥 Getting visitors for guard: ${guardId}`);

  // Return mock visitors for now
  res.json({
    success: true,
    data: mockVisitors,
    count: mockVisitors.length,
    message: 'Visitors retrieved successfully'
  });
});

app.post('/api/visitors', (req, res) => {
  const visitorData = req.body;
  const guardId = visitorData.guardId || visitorData.assignedGuard;

  console.log('➕ New visitor request:', visitorData);

  // Add to mock data
  const newVisitor = {
    _id: Date.now().toString(),
    ...visitorData,
    createdAt: new Date().toISOString(),
    status: 'pending'
  };

  mockVisitors.push(newVisitor);

  // Emit real-time event to guards
  emitVisitorEvent('visitorAdded', newVisitor, guardId);

  res.json({
    success: true,
    data: newVisitor,
    message: 'Visitor request created successfully'
  });
});

// Mock security guard login
app.post('/api/auth/login', (req, res) => {
  const { mobilenumber, password } = req.body;

  console.log(`🔐 Security guard login attempt: ${mobilenumber}`);

  // Mock successful login
  if (mobilenumber && password) {
    const guardData = {
      _id: 'guard_123',
      id: 'guard_123',
      name: 'Security Guard',
      mobile: mobilenumber,
      role: 'security_guard'
    };

    const token = 'mock_jwt_token_' + Date.now();

    res.json({
      status: true,
      message: 'Login successful',
      data: guardData,
      token: token
    });
  } else {
    res.status(400).json({
      status: false,
      message: 'Invalid credentials'
    });
  }
});

// Start server
const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`🔌 Socket.IO server ready`);
  console.log(`📡 Real-time visitor updates enabled`);
});