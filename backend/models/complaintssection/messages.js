const mongoose = require('mongoose');
const db = require('../../config/db');

const { Schema } = mongoose;

const messagesSchema = new Schema({
    complaintId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Complaints',
        required: [true, 'Complaint ID is required']
    },
    senderId: {
        type: mongoose.Schema.Types.ObjectId,
        required: [true, 'Sender ID is required']
    },
    senderType: {
        type: String,
        enum: ['admin', 'member'],
        required: [true, 'Sender type is required']
    },
    message: {
        type: String,
        required: [true, 'Message is required'],
        trim: true,
        maxlength: [1000, 'Message cannot exceed 1000 characters']
    },
    messageType: {
        type: String,
        enum: ['text', 'image'],
        default: 'text'
    },
    images: [{
        originalUrl: {
            type: String,
            required: true
        },
        compressedUrl: {
            type: String,
            required: true
        },
        filename: {
            type: String,
            required: true
        },
        size: {
            type: Number,
            required: true
        },
        mimeType: {
            type: String,
            required: true
        }
    }],
    isRead: {
        type: Boolean,
        default: false
    },
    timestamp: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

// Indexes for better performance
messagesSchema.index({ complaintId: 1, timestamp: -1 });
messagesSchema.index({ senderId: 1, timestamp: -1 });
messagesSchema.index({ messageType: 1 });
messagesSchema.index({ isRead: 1 });

// Instance method to check if message is from admin
messagesSchema.methods.isAdminMessage = function(adminId) {
    return this.senderId.toString() === adminId.toString();
};

const Messages = db.model('Messages', messagesSchema);
module.exports = Messages;