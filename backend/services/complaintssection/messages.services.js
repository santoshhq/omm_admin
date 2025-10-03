const Messages = require('../../models/complaintssection/messages');
const multer = require('multer');
const sharp = require('sharp');
const path = require('path');
const fs = require('fs').promises;

class MessageService {

    // Send a text message
    static async sendMessage({ complaintId, senderId, message, senderType = 'admin' }) {
        try {
            console.log('\n=== 💬 SEND MESSAGE SERVICE CALLED ===');
            console.log('📝 Complaint ID:', complaintId);
            console.log('👤 Sender ID:', senderId);
            console.log('🔖 Sender Type:', senderType);
            console.log('💬 Message:', message.substring(0, 50) + '...');

            // Validate required fields
            if (!complaintId || !senderId || !message) {
                return {
                    success: false,
                    message: 'Missing required fields: complaintId, senderId, message'
                };
            }

            // Create message
            const messageData = {
                complaintId,
                senderId,
                senderType,
                message: message.trim(),
                messageType: 'text',
                timestamp: new Date()
            };

            const newMessage = new Messages(messageData);
            const savedMessage = await newMessage.save();

            // Populate sender details
            const populatedMessage = await Messages.findById(savedMessage._id)
                .populate('senderId', 'firstName lastName email mobile flatNo');

            console.log('✅ Message sent successfully with ID:', savedMessage._id);

            return {
                success: true,
                message: 'Message sent successfully',
                data: populatedMessage
            };

        } catch (error) {
            console.error('❌ Error sending message:', error.message);
            
            if (error.name === 'ValidationError') {
                const validationErrors = Object.values(error.errors).map(err => err.message);
                return {
                    success: false,
                    message: 'Validation failed',
                    errors: validationErrors
                };
            }

            return {
                success: false,
                message: 'Internal server error while sending message',
                error: error.message
            };
        }
    }

    // Send image message with compression
    static async sendImageMessage({ complaintId, senderId, message = '', files, senderType = 'admin' }) {
        try {
            console.log('\n=== 🖼️ SEND IMAGE MESSAGE SERVICE CALLED ===');
            console.log('📝 Complaint ID:', complaintId);
            console.log('👤 Sender ID:', senderId);
            console.log('🔖 Sender Type:', senderType);
            console.log('🖼️ Files:', files?.length || 0);
            console.log('💬 Caption:', message || 'No caption');

            // Validate required fields
            if (!complaintId || !senderId || !files || files.length === 0) {
                return {
                    success: false,
                    message: 'Missing required fields: complaintId, senderId, files'
                };
            }

            // Process and compress images
            const processedImages = [];
            
            for (let i = 0; i < files.length; i++) {
                const file = files[i];
                console.log(`📁 Processing file ${i + 1}: ${file.originalname}`);

                // Create directories if they don't exist
                const originalDir = path.join(__dirname, '../../uploads/images/complaints');
                const compressedDir = path.join(__dirname, '../../uploads/images/compressed');
                
                await fs.mkdir(originalDir, { recursive: true });
                await fs.mkdir(compressedDir, { recursive: true });

                // Generate unique filename
                const timestamp = Date.now();
                const randomString = Math.random().toString(36).substring(7);
                const extension = path.extname(file.originalname);
                const filename = `${timestamp}_${randomString}${extension}`;

                // Save original image
                const originalPath = path.join(originalDir, filename);
                await fs.writeFile(originalPath, file.buffer);

                // Create compressed version
                const compressedFilename = `compressed_${filename}`;
                const compressedPath = path.join(compressedDir, compressedFilename);

                await sharp(file.buffer)
                    .resize(800, 800, { 
                        fit: 'inside', 
                        withoutEnlargement: true 
                    })
                    .jpeg({ 
                        quality: 80, 
                        progressive: true 
                    })
                    .toFile(compressedPath);

                // Get file size after compression
                const compressedStats = await fs.stat(compressedPath);

                const imageData = {
                    originalUrl: `uploads/images/complaints/${filename}`,
                    compressedUrl: `uploads/images/compressed/${compressedFilename}`,
                    filename: filename,
                    size: compressedStats.size,
                    mimeType: file.mimetype
                };

                processedImages.push(imageData);
                console.log(`✅ Image ${i + 1} processed successfully`);
            }

            // Create message with images
            const messageData = {
                complaintId,
                senderId,
                senderType,
                message: message.trim() || '',
                messageType: 'image',
                images: processedImages,
                timestamp: new Date()
            };

            const newMessage = new Messages(messageData);
            const savedMessage = await newMessage.save();

            // Populate sender details
            const populatedMessage = await Messages.findById(savedMessage._id)
                .populate('senderId', 'firstName lastName email mobile flatNo');

            console.log('✅ Image message sent successfully with ID:', savedMessage._id);

            return {
                success: true,
                message: `Image message with ${processedImages.length} image(s) sent successfully`,
                data: populatedMessage
            };

        } catch (error) {
            console.error('❌ Error sending image message:', error.message);
            
            if (error.name === 'ValidationError') {
                const validationErrors = Object.values(error.errors).map(err => err.message);
                return {
                    success: false,
                    message: 'Validation failed',
                    errors: validationErrors
                };
            }

            return {
                success: false,
                message: 'Internal server error while sending image message',
                error: error.message
            };
        }
    }

    // Get messages by complaint
    static async getMessagesByComplaint(complaintId) {
        try {
            console.log('\n=== 📨 GET MESSAGES BY COMPLAINT SERVICE CALLED ===');
            console.log('📝 Complaint ID:', complaintId);

            if (!complaintId) {
                return {
                    success: false,
                    message: 'Complaint ID is required'
                };
            }

            const messages = await Messages.find({ complaintId })
                .populate('senderId', 'firstName lastName email mobile flatNo')
                .sort({ timestamp: 1 });

            console.log('📊 Total messages found:', messages.length);

            return {
                success: true,
                message: 'Messages retrieved successfully',
                data: messages,
                count: messages.length
            };

        } catch (error) {
            console.error('❌ Error retrieving messages:', error.message);
            return {
                success: false,
                message: 'Internal server error while retrieving messages',
                error: error.message
            };
        }
    }

    // Get messages by sender
    static async getMessagesBySender(senderId) {
        try {
            console.log('\n=== 👤 GET MESSAGES BY SENDER SERVICE CALLED ===');
            console.log('👤 Sender ID:', senderId);

            if (!senderId) {
                return {
                    success: false,
                    message: 'Sender ID is required'
                };
            }

            const messages = await Messages.find({ senderId })
                .populate('senderId', 'firstName lastName email mobile flatNo')
                .sort({ timestamp: -1 });

            console.log('📊 Total messages found for sender:', messages.length);

            return {
                success: true,
                message: 'Sender messages retrieved successfully',
                data: messages,
                count: messages.length
            };

        } catch (error) {
            console.error('❌ Error retrieving sender messages:', error.message);
            return {
                success: false,
                message: 'Internal server error while retrieving sender messages',
                error: error.message
            };
        }
    }

    // Delete a message
    static async deleteMessage(messageId, adminId, deleteForEveryone = false) {
        try {
            console.log('\n=== 🗑️ DELETE MESSAGE SERVICE CALLED ===');
            console.log('🆔 Message ID:', messageId);
            console.log('👨‍💼 Admin ID:', adminId);
            console.log('🌍 Delete for everyone:', deleteForEveryone);

            if (!messageId || !adminId) {
                return {
                    success: false,
                    message: 'Message ID and Admin ID are required'
                };
            }

            const message = await Messages.findById(messageId);
            if (!message) {
                return {
                    success: false,
                    message: 'Message not found'
                };
            }

            // Check if admin has permission to delete
            if (message.senderId.toString() !== adminId && !deleteForEveryone) {
                return {
                    success: false,
                    message: 'Permission denied: You can only delete your own messages'
                };
            }

            // If message has images, delete the files
            if (message.images && message.images.length > 0) {
                for (const image of message.images) {
                    try {
                        const originalPath = path.join(__dirname, '../../', image.originalUrl);
                        const compressedPath = path.join(__dirname, '../../', image.compressedUrl);
                        
                        await fs.unlink(originalPath).catch(() => {});
                        await fs.unlink(compressedPath).catch(() => {});
                        
                        console.log(`🗑️ Deleted image files for: ${image.filename}`);
                    } catch (fileError) {
                        console.log(`⚠️ Could not delete image files: ${fileError.message}`);
                    }
                }
            }

            const deletedMessage = await Messages.findByIdAndDelete(messageId);

            console.log('✅ Message deleted successfully');

            return {
                success: true,
                message: 'Message deleted successfully',
                data: deletedMessage
            };

        } catch (error) {
            console.error('❌ Error deleting message:', error.message);
            return {
                success: false,
                message: 'Internal server error while deleting message',
                error: error.message
            };
        }
    }
}

module.exports = MessageService;