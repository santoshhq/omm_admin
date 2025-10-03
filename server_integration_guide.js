// SERVER INTEGRATION GUIDE FOR MESSAGES
// Add this to your main server file (server.js or app.js)

/*
STEP 1: Install required dependencies
Run these commands in your backend directory:

npm install multer sharp

STEP 2: Add these lines to your main server file
*/

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

// ⭐ IMPORTANT: Add this line to serve static files (for image uploads)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Database connection
mongoose.connect('mongodb://localhost:27017/your-database-name', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// Your existing routes (keep these as they are)
// app.use('/api/auth', require('./routes/auth'));
// app.use('/api/admin-profiles', require('./routes/admin-profiles'));
// app.use('/api/members', require('./routes/members'));
// ... your other existing routes

// ⭐ ADD THESE LINES - Register the message routes
app.use('/api/complaints', require('./backend_message_routes')); // Adjust path as needed

// Default route
app.get('/', (req, res) => {
  res.send('OMM Admin Backend is running! 🚀');
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server is running on http://localhost:${PORT}`);
  console.log(`📁 Static files served from: ${path.join(__dirname, 'uploads')}`);
});

module.exports = app;

/*
STEP 3: File Structure
Make sure your backend has this structure:

your-backend/
├── server.js (or app.js) - Your main server file
├── backend_message_model.js - The Message model file created above
├── backend_message_routes.js - The message routes file created above
├── models/
│   └── Message.js - Move backend_message_model.js here and rename
├── routes/
│   └── messages.js - Move backend_message_routes.js here and rename
└── uploads/
    └── messages/ - This will be created automatically

STEP 4: Update imports in routes file
If you move the files to proper folders, update the require paths:
- Change: const Message = require('../models/Message');
- To match your actual file structure

STEP 5: Test the routes
After starting your server, these endpoints should work:
- GET http://localhost:8080/api/complaints/:complaintId/messages
- POST http://localhost:8080/api/complaints/messages/send
- POST http://localhost:8080/api/complaints/messages/send-images
- DELETE http://localhost:8080/api/complaints/messages/:messageId

STEP 6: Restart your server
Stop your current server and restart it to load the new routes.
*/

// QUICK TEST ENDPOINTS (add these temporarily to test if everything works)
app.get('/api/test', (req, res) => {
  res.json({
    success: true,
    message: 'Backend is working!',
    timestamp: new Date()
  });
});

app.get('/api/complaints/test', (req, res) => {
  res.json({
    success: true,
    message: 'Message routes are registered!',
    availableRoutes: [
      'GET /api/complaints/:complaintId/messages',
      'POST /api/complaints/messages/send',
      'POST /api/complaints/messages/send-images',
      'DELETE /api/complaints/messages/:messageId'
    ]
  });
});