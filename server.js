const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const bodyParser = require('body-parser');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

// Import routes
const securityRouter = require('./backend/routers/securityguards.routers');

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

// API prefix
const API_PREFIX = '/api';

// MongoDB connection
mongoose.connect('mongodb://localhost:27017/omm_admin', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ MongoDB connected'))
.catch(err => console.error('❌ MongoDB connection error:', err));

// Routes
app.use(`${API_PREFIX}/security`, securityRouter);

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

// Import middleware
const { authenticateGuard, optionalAuthenticateGuard } = require('./backend/middleware/auth.middleware');

// Mock visitor data for testing (will be replaced with database)
app.get('/api/visitors/guard/:guardId', authenticateGuard, async (req, res) => {
  try {
    const { guardId } = req.params;

    // Verify that the authenticated guard matches the requested guardId
    if (req.guard.id !== guardId) {
      return res.status(403).json({
        status: false,
        message: 'Access denied. You can only view your own visitors.'
      });
    }

    console.log(`📥 Getting visitors for guard: ${guardId}`);

    // For now, return mock visitors filtered by guard
    // TODO: Replace with actual database query
    const guardVisitors = mockVisitors.filter(visitor =>
      visitor.assignedGuard === guardId || visitor.guardId === guardId
    );

    res.json({
      status: true,
      data: guardVisitors,
      count: guardVisitors.length,
      message: 'Visitors retrieved successfully'
    });
  } catch (error) {
    console.error('Error fetching visitors:', error);
    res.status(500).json({
      status: false,
      message: 'Error retrieving visitors'
    });
  }
});

app.post('/api/visitors', optionalAuthenticateGuard, (req, res) => {
  const visitorData = req.body;
  const guardId = visitorData.guardId || visitorData.assignedGuard || req.guard?.id;

  console.log('➕ New visitor request:', visitorData);

  // Add to mock data
  const newVisitor = {
    _id: Date.now().toString(),
    ...visitorData,
    assignedGuard: guardId,
    createdAt: new Date().toISOString(),
    status: 'pending',
    // Set expiry to 24 hours from now (can be customized based on visitor type)
    expiry: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString() // 24 hours from now
  };

  mockVisitors.push(newVisitor);

  // Emit real-time event to guards
  emitVisitorEvent('visitorAdded', newVisitor, guardId);

  res.json({
    status: true,
    data: newVisitor,
    message: 'Visitor request created successfully'
  });
});

// Get expired visitors for a guard (requires JWT authentication)
app.get('/api/visitors/guard/:guardId/expired', authenticateGuard, async (req, res) => {
  try {
    const { guardId } = req.params;

    // Verify that the authenticated guard matches the requested guardId
    if (req.guard.id !== guardId) {
      return res.status(403).json({
        status: false,
        message: 'Access denied. You can only view your own expired visitors.'
      });
    }

    console.log(`📅 Getting expired visitors for guard: ${guardId}`);

    // Get current timestamp for expiry comparison
    const now = new Date();

    // For now, return mock visitors filtered by guard and expiry status
    // TODO: Replace with actual database query
    const expiredVisitors = mockVisitors.filter(visitor => {
      // Check if visitor belongs to this guard
      const visitorGuardId = visitor.assignedGuard || visitor.guardId;
      if (visitorGuardId !== guardId) {
        return false;
      }

      // Check if visitor has expiry information
      if (!visitor.expiry) {
        return false; // No expiry date means not expired
      }

      // Parse expiry date and check if it's expired
      const expiryDate = new Date(visitor.expiry);
      return expiryDate < now; // Expired if expiry date is before now
    });

    console.log(`📅 Found ${expiredVisitors.length} expired visitors for guard ${guardId}`);

    res.json({
      status: true,
      data: expiredVisitors,
      count: expiredVisitors.length,
      message: 'Expired visitors retrieved successfully'
    });
  } catch (error) {
    console.error('Error fetching expired visitors:', error);
    res.status(500).json({
      status: false,
      message: 'Error retrieving expired visitors'
    });
  }
});

// Security guard login is now handled by /api/security/login route
// This endpoint is kept for backward compatibility but should be removed in production
app.post('/api/auth/login', (req, res) => {
  console.log('⚠️  DEPRECATED: Using old login endpoint. Please use /api/security/login instead.');

  const { mobilenumber, password } = req.body;

  console.log(`🔐 Security guard login attempt: ${mobilenumber}`);

  // Mock successful login for backward compatibility
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
      message: 'Login successful (deprecated endpoint)',
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