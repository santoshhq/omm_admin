// Example of how your main server file (server.js or app.js) should look
// This is a reference - add the amenities routes to your existing server file

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors());
app.use(bodyParser.json({ limit: '50mb' }));
app.use(bodyParser.urlencoded({ extended: true, limit: '50mb' }));

// Database connection (you probably already have this)
mongoose.connect('mongodb://localhost:27017/your-database-name', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

// Your existing routes (keep these as they are)
// app.use('/api/auth', require('./routes/auth'));
// app.use('/api/admin-profiles', require('./routes/admin-profiles'));
// app.use('/api/members', require('./routes/members'));
// ... your other routes

// ⭐ ADD THIS LINE - Register the amenities routes
app.use('/api/admin-amenities', require('./routes/admin-amenities'));

// Default route
app.get('/', (req, res) => {
  res.send('Hello World!');
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server is running on http://localhost:${PORT}`);
});

module.exports = app;