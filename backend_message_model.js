// models/Message.js
const mongoose = require('mongoose');

const MessageImageSchema = new mongoose.Schema({
  originalName: { type: String, required: true },
  fileName: { type: String, required: true },
  originalPath: { type: String, required: true },
  compressedPath: { type: String, required: true },
  originalSize: { type: Number, required: true },
  compressedSize: { type: Number, required: true },
  compressionRatio: { type: Number, required: true },
  dimensions: {
    width: { type: Number, required: true },
    height: { type: Number, required: true }
  },
  mimetype: { type: String, required: true }
});

const MessageSchema = new mongoose.Schema({
  complaintId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Complaint',
    required: true
  },
  senderId: {
    type: String,
    required: true
  },
  senderName: {
    type: String,
    default: 'Unknown User'
  },
  senderFlat: {
    type: String,
    default: 'N/A'
  },
  messageType: {
    type: String,
    enum: ['text', 'image'],
    default: 'text'
  },
  message: {
    type: String,
    required: true
  },
  images: [MessageImageSchema],
  timestamp: {
    type: Date,
    default: Date.now
  },
  isDeleted: {
    type: Boolean,
    default: false
  },
  senderDetails: {
    type: mongoose.Schema.Types.Mixed,
    default: null
  }
}, {
  timestamps: true
});

// Index for better query performance
MessageSchema.index({ complaintId: 1, timestamp: -1 });
MessageSchema.index({ senderId: 1 });

module.exports = mongoose.model('Message', MessageSchema);