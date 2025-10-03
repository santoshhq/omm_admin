// ADD_TO_EXISTING_SERVER.js
// Copy and paste these routes into your existing server file

// 🚨 IMPORTANT: ADD THESE IMPORTS TO THE TOP OF YOUR EXISTING SERVER FILE
const multer = require('multer');
const sharp = require('sharp');
const fs = require('fs').promises;
const path = require('path');

// 🚨 ADD THIS MESSAGE MODEL TO YOUR EXISTING SERVER FILE
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
  senderId: { type: String, required: true },
  senderName: { type: String, default: 'Unknown User' },
  senderFlat: { type: String, default: 'N/A' },
  messageType: { type: String, enum: ['text', 'image'], default: 'text' },
  message: { type: String, required: true },
  images: [MessageImageSchema],
  timestamp: { type: Date, default: Date.now },
  isDeleted: { type: Boolean, default: false },
  senderDetails: { type: mongoose.Schema.Types.Mixed, default: null }
}, { timestamps: true });

const Message = mongoose.model('Message', MessageSchema);

// 🚨 ADD THIS MULTER CONFIGURATION TO YOUR EXISTING SERVER FILE
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
  limits: { fileSize: 10 * 1024 * 1024, files: 5 },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    if (mimetype && extname) return cb(null, true);
    else cb(new Error('Only JPG, PNG, and GIF images are allowed'));
  }
});

// 🚨 ADD THESE HELPER FUNCTIONS TO YOUR EXISTING SERVER FILE
const getSenderDetails = async (senderId) => {
  return {
    name: senderId.includes('admin') ? 'Admin' : 'Member',
    flat: senderId.includes('admin') ? 'Admin' : 'N/A',
    role: senderId.includes('admin') ? 'admin' : 'member'
  };
};

const compressImage = async (inputPath, outputPath) => {
  const metadata = await sharp(inputPath).metadata();
  await sharp(inputPath)
    .resize(1200, 1200, { fit: 'inside', withoutEnlargement: true })
    .jpeg({ quality: 80 })
    .toFile(outputPath);
  
  const originalStats = await fs.stat(inputPath);
  const compressedStats = await fs.stat(outputPath);
  
  return {
    originalSize: originalStats.size,
    compressedSize: compressedStats.size,
    compressionRatio: compressedStats.size / originalStats.size,
    dimensions: { width: metadata.width || 0, height: metadata.height || 0 }
  };
};

// 🚨 ADD THESE ROUTES TO YOUR EXISTING SERVER FILE (after your existing routes)

// Get messages for a complaint
app.get('/api/complaints/:complaintId/messages', async (req, res) => {
  try {
    const { complaintId } = req.params;
    console.log(`📨 Fetching messages for complaint: ${complaintId}`);
    
    if (!mongoose.Types.ObjectId.isValid(complaintId)) {
      return res.status(400).json({ success: false, message: 'Invalid complaint ID format' });
    }

    const messages = await Message.find({ complaintId: complaintId, isDeleted: false }).sort({ timestamp: 1 });
    
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
    res.status(500).json({ success: false, message: 'Failed to fetch messages', error: error.message });
  }
});

// Send text message
app.post('/api/complaints/messages/send', async (req, res) => {
  try {
    const { complaintId, senderId, message } = req.body;
    console.log(`💬 Sending message for complaint: ${complaintId}`);

    if (!complaintId || !senderId || !message) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    if (!mongoose.Types.ObjectId.isValid(complaintId)) {
      return res.status(400).json({ success: false, message: 'Invalid complaint ID format' });
    }

    const senderDetails = await getSenderDetails(senderId);
    const newMessage = new Message({
      complaintId, senderId, senderName: senderDetails.name, senderFlat: senderDetails.flat,
      messageType: 'text', message, images: [], senderDetails
    });

    const savedMessage = await newMessage.save();
    console.log(`✅ Message saved with ID: ${savedMessage._id}`);

    res.status(201).json({ success: true, message: 'Message sent successfully', data: savedMessage });
  } catch (error) {
    console.error('❌ Error sending message:', error);
    res.status(500).json({ success: false, message: 'Failed to send message', error: error.message });
  }
});

// Send image message  
app.post('/api/complaints/messages/send-images', upload.array('images', 5), async (req, res) => {
  try {
    const { complaintId, senderId, message } = req.body;
    const files = req.files;
    console.log(`🖼️ Sending image message for complaint: ${complaintId}`);

    if (!complaintId || !senderId || !files || files.length === 0) {
      return res.status(400).json({ success: false, message: 'Missing required fields or images' });
    }

    if (!mongoose.Types.ObjectId.isValid(complaintId)) {
      return res.status(400).json({ success: false, message: 'Invalid complaint ID format' });
    }

    const senderDetails = await getSenderDetails(senderId);
    const processedImages = [];
    
    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      const compressedPath = file.path.replace(path.extname(file.path), '_compressed.jpg');
      const compressionResult = await compressImage(file.path, compressedPath);
      
      processedImages.push({
        originalName: file.originalname, fileName: file.filename,
        originalPath: file.path, compressedPath: compressedPath,
        originalSize: compressionResult.originalSize, compressedSize: compressionResult.compressedSize,
        compressionRatio: compressionResult.compressionRatio, dimensions: compressionResult.dimensions,
        mimetype: file.mimetype
      });
    }

    const newMessage = new Message({
      complaintId, senderId, senderName: senderDetails.name, senderFlat: senderDetails.flat,
      messageType: 'image', message: message || '', images: processedImages, senderDetails
    });

    const savedMessage = await newMessage.save();
    console.log(`✅ Image message saved with ID: ${savedMessage._id}`);

    res.status(201).json({ success: true, message: 'Image message sent successfully', data: savedMessage });
  } catch (error) {
    console.error('❌ Error sending image message:', error);
    res.status(500).json({ success: false, message: 'Failed to send image message', error: error.message });
  }
});

// 🚨 ADD THIS LINE TO SERVE STATIC FILES (add this with your other middleware)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

console.log('✅ Message routes added to existing server!');