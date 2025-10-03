// routes/messages.js
const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const sharp = require('sharp');
const Message = require('../models/Message'); // Adjust path as needed
const mongoose = require('mongoose');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: async (req, file, cb) => {
    const uploadDir = 'uploads/messages';
    try {
      await fs.mkdir(uploadDir, { recursive: true });
      cb(null, uploadDir);
    } catch (error) {
      cb(error);
    }
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'message-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
    files: 5 // Max 5 files
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Only JPG, PNG, and GIF images are allowed'));
    }
  }
});

// Helper function to get sender details
const getSenderDetails = async (senderId) => {
  try {
    // Try to find in admin collection first
    const Admin = mongoose.model('Admin');
    const admin = await Admin.findById(senderId);
    if (admin) {
      return {
        name: admin.name || 'Admin',
        flat: 'Admin',
        role: 'admin'
      };
    }

    // Try to find in members collection
    const Member = mongoose.model('Member');
    const member = await Member.findById(senderId);
    if (member) {
      return {
        name: member.name || 'Unknown Member',
        flat: member.flatNumber || 'N/A',
        role: 'member'
      };
    }

    return {
      name: 'Unknown User',
      flat: 'N/A',
      role: 'unknown'
    };
  } catch (error) {
    console.log('Error getting sender details:', error);
    return {
      name: 'Unknown User',
      flat: 'N/A',
      role: 'unknown'
    };
  }
};

// Compress image function
const compressImage = async (inputPath, outputPath) => {
  try {
    const metadata = await sharp(inputPath).metadata();
    
    await sharp(inputPath)
      .resize(1200, 1200, { 
        fit: 'inside',
        withoutEnlargement: true 
      })
      .jpeg({ quality: 80 })
      .toFile(outputPath);

    const originalStats = await fs.stat(inputPath);
    const compressedStats = await fs.stat(outputPath);
    
    return {
      originalSize: originalStats.size,
      compressedSize: compressedStats.size,
      compressionRatio: compressedStats.size / originalStats.size,
      dimensions: {
        width: metadata.width || 0,
        height: metadata.height || 0
      }
    };
  } catch (error) {
    console.error('Error compressing image:', error);
    throw error;
  }
};

// GET /api/complaints/:complaintId/messages - Get all messages for a complaint
router.get('/:complaintId/messages', async (req, res) => {
  try {
    const { complaintId } = req.params;
    
    console.log(`📨 Fetching messages for complaint: ${complaintId}`);
    
    // Validate ObjectId
    if (!mongoose.Types.ObjectId.isValid(complaintId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid complaint ID format'
      });
    }

    const messages = await Message.find({ 
      complaintId: complaintId,
      isDeleted: false 
    }).sort({ timestamp: 1 });

    // Populate sender details for each message
    const populatedMessages = await Promise.all(
      messages.map(async (message) => {
        const senderDetails = await getSenderDetails(message.senderId);
        return {
          ...message.toObject(),
          senderName: senderDetails.name,
          senderFlat: senderDetails.flat,
          senderDetails: senderDetails
        };
      })
    );

    console.log(`✅ Found ${populatedMessages.length} messages`);

    res.status(200).json({
      success: true,
      message: 'Messages retrieved successfully',
      data: populatedMessages
    });
  } catch (error) {
    console.error('❌ Error fetching messages:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch messages',
      error: error.message
    });
  }
});

// POST /api/complaints/messages/send - Send a text message
router.post('/messages/send', async (req, res) => {
  try {
    const { complaintId, senderId, message } = req.body;
    
    console.log(`💬 Sending message for complaint: ${complaintId}`);
    console.log(`👤 Sender: ${senderId}`);
    console.log(`📝 Message: ${message.substring(0, 50)}...`);

    // Validate required fields
    if (!complaintId || !senderId || !message) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: complaintId, senderId, message'
      });
    }

    // Validate ObjectId
    if (!mongoose.Types.ObjectId.isValid(complaintId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid complaint ID format'
      });
    }

    // Get sender details
    const senderDetails = await getSenderDetails(senderId);

    // Create new message
    const newMessage = new Message({
      complaintId,
      senderId,
      senderName: senderDetails.name,
      senderFlat: senderDetails.flat,
      messageType: 'text',
      message,
      images: [],
      senderDetails
    });

    const savedMessage = await newMessage.save();
    
    console.log(`✅ Message saved with ID: ${savedMessage._id}`);

    res.status(201).json({
      success: true,
      message: 'Message sent successfully',
      data: savedMessage
    });
  } catch (error) {
    console.error('❌ Error sending message:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send message',
      error: error.message
    });
  }
});

// POST /api/complaints/messages/send-images - Send image messages
router.post('/messages/send-images', upload.array('images', 5), async (req, res) => {
  try {
    const { complaintId, senderId, message } = req.body;
    const files = req.files;
    
    console.log(`🖼️ Sending image message for complaint: ${complaintId}`);
    console.log(`👤 Sender: ${senderId}`);
    console.log(`📁 Files: ${files?.length || 0}`);
    console.log(`📝 Caption: ${message || 'No caption'}`);

    // Validate required fields
    if (!complaintId || !senderId) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: complaintId, senderId'
      });
    }

    if (!files || files.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No images provided'
      });
    }

    // Validate ObjectId
    if (!mongoose.Types.ObjectId.isValid(complaintId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid complaint ID format'
      });
    }

    // Get sender details
    const senderDetails = await getSenderDetails(senderId);

    // Process images
    const processedImages = [];
    
    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      const compressedPath = file.path.replace(path.extname(file.path), '_compressed.jpg');
      
      try {
        const compressionResult = await compressImage(file.path, compressedPath);
        
        processedImages.push({
          originalName: file.originalname,
          fileName: file.filename,
          originalPath: file.path,
          compressedPath: compressedPath,
          originalSize: compressionResult.originalSize,
          compressedSize: compressionResult.compressedSize,
          compressionRatio: compressionResult.compressionRatio,
          dimensions: compressionResult.dimensions,
          mimetype: file.mimetype
        });
        
        console.log(`✅ Processed image ${i + 1}: ${file.originalname}`);
      } catch (compressionError) {
        console.error(`❌ Error processing image ${i + 1}:`, compressionError);
        // Clean up uploaded file
        try {
          await fs.unlink(file.path);
        } catch (unlinkError) {
          console.log('Error cleaning up file:', unlinkError);
        }
        throw new Error(`Failed to process image: ${file.originalname}`);
      }
    }

    // Create new message
    const newMessage = new Message({
      complaintId,
      senderId,
      senderName: senderDetails.name,
      senderFlat: senderDetails.flat,
      messageType: 'image',
      message: message || '',
      images: processedImages,
      senderDetails
    });

    const savedMessage = await newMessage.save();
    
    console.log(`✅ Image message saved with ID: ${savedMessage._id}`);

    res.status(201).json({
      success: true,
      message: 'Image message sent successfully',
      data: savedMessage
    });
  } catch (error) {
    console.error('❌ Error sending image message:', error);
    
    // Clean up uploaded files in case of error
    if (req.files) {
      for (const file of req.files) {
        try {
          await fs.unlink(file.path);
          const compressedPath = file.path.replace(path.extname(file.path), '_compressed.jpg');
          await fs.unlink(compressedPath);
        } catch (unlinkError) {
          console.log('Error cleaning up files:', unlinkError);
        }
      }
    }
    
    res.status(500).json({
      success: false,
      message: 'Failed to send image message',
      error: error.message
    });
  }
});

// DELETE /api/complaints/messages/:messageId - Delete a message
router.delete('/messages/:messageId', async (req, res) => {
  try {
    const { messageId } = req.params;
    const { adminId, deleteForEveryone } = req.body;
    
    console.log(`🗑️ Deleting message: ${messageId}`);
    console.log(`👤 Admin: ${adminId}`);
    console.log(`🌍 Delete for everyone: ${deleteForEveryone}`);

    // Validate ObjectId
    if (!mongoose.Types.ObjectId.isValid(messageId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid message ID format'
      });
    }

    const message = await Message.findById(messageId);
    if (!message) {
      return res.status(404).json({
        success: false,
        message: 'Message not found'
      });
    }

    // Mark message as deleted
    message.isDeleted = true;
    await message.save();
    
    console.log(`✅ Message deleted: ${messageId}`);

    res.status(200).json({
      success: true,
      message: 'Message deleted successfully'
    });
  } catch (error) {
    console.error('❌ Error deleting message:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete message',
      error: error.message
    });
  }
});

module.exports = router;