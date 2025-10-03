const mongoose = require('mongoose');

// Database configuration
const DB_CONFIG = {
    url: process.env.MONGODB_URI || 'mongodb://localhost:27017/omm_admin',
    options: {
        useNewUrlParser: true,
        useUnifiedTopology: true,
    }
};

// Connect to MongoDB
let isConnected = false;

const connectDB = async () => {
    if (isConnected) {
        console.log('📊 Database already connected');
        return mongoose.connection;
    }

    try {
        console.log('🔄 Connecting to MongoDB...');
        console.log('📡 Database URL:', DB_CONFIG.url.replace(/\/\/.*@/, '//***:***@')); // Hide credentials in logs

        const connection = await mongoose.connect(DB_CONFIG.url, DB_CONFIG.options);
        
        isConnected = true;
        console.log('✅ MongoDB Connected Successfully');
        console.log('🏛️ Database Name:', connection.connection.name);
        console.log('🌐 Host:', connection.connection.host);
        console.log('🔌 Port:', connection.connection.port);

        // Handle connection events
        mongoose.connection.on('connected', () => {
            console.log('📊 Mongoose connected to MongoDB');
        });

        mongoose.connection.on('error', (err) => {
            console.error('❌ Mongoose connection error:', err);
        });

        mongoose.connection.on('disconnected', () => {
            console.log('📊 Mongoose disconnected from MongoDB');
            isConnected = false;
        });

        // Handle process termination
        process.on('SIGINT', async () => {
            await mongoose.connection.close();
            console.log('📊 MongoDB connection closed due to app termination');
            process.exit(0);
        });

        return connection;

    } catch (error) {
        console.error('❌ MongoDB Connection Error:', error.message);
        console.error('🔧 Please ensure MongoDB is running and the connection string is correct');
        process.exit(1);
    }
};

// Export both the connection function and mongoose for models
module.exports = mongoose;
module.exports.connectDB = connectDB;
module.exports.isConnected = () => isConnected;