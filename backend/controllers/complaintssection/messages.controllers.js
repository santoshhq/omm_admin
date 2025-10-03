const MessageService = require('../../services/complaintssection/messages.services');

class MessageController {

    // Send a text message
    static async sendMessage(req, res) {
        try {
            console.log('\n=== 💬 SEND MESSAGE CONTROLLER CALLED ===');
            console.log('📄 Request Body:', req.body);

            const { complaintId, senderId, message, senderType = 'admin' } = req.body;

            // Basic validation
            if (!complaintId || !senderId || !message) {
                return res.status(400).json({
                    success: false,
                    message: 'Missing required fields: complaintId, senderId, message'
                });
            }

            const result = await MessageService.sendMessage({
                complaintId,
                senderId,
                message,
                senderType
            });

            const statusCode = result.success ? 201 : 400;
            return res.status(statusCode).json(result);

        } catch (error) {
            console.log('❌ ERROR in sendMessage controller:', error.message);
            return res.status(500).json({
                success: false,
                message: 'Internal server error',
                error: error.message
            });
        }
    }

    // Send image message with file upload
    static async sendImageMessage(req, res) {
        try {
            console.log('\n=== 🖼️ SEND IMAGE MESSAGE CONTROLLER CALLED ===');
            console.log('📄 Request Body:', req.body);
            console.log('📁 Request Files:', req.files?.length || 0);

            const { complaintId, senderId, message = '', senderType = 'admin' } = req.body;
            const files = req.files;

            // Basic validation
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

            const result = await MessageService.sendImageMessage({
                complaintId,
                senderId,
                message,
                files,
                senderType
            });

            // Emit real-time event if Socket.io is available
            const io = req.app.get('io');
            if (io && result.success) {
                io.to(complaintId).emit('new_message', {
                    type: 'image_message',
                    data: result.data
                });
                console.log(`📡 Real-time image message sent to room: ${complaintId}`);
            }

            const statusCode = result.success ? 201 : 400;
            return res.status(statusCode).json(result);

        } catch (error) {
            console.log('❌ ERROR in sendImageMessage controller:', error.message);
            return res.status(500).json({
                success: false,
                message: 'Internal server error',
                error: error.message
            });
        }
    }

    // Get messages for a complaint
    static async getMessages(req, res) {
        try {
            console.log('\n=== 📨 GET MESSAGES CONTROLLER CALLED ===');
            console.log('📝 Complaint ID:', req.params.complaintId);

            const { complaintId } = req.params;

            if (!complaintId) {
                return res.status(400).json({
                    success: false,
                    message: 'Complaint ID is required'
                });
            }

            const result = await MessageService.getMessagesByComplaint(complaintId);

            const statusCode = result.success ? 200 : 400;
            return res.status(statusCode).json(result);

        } catch (error) {
            console.log('❌ ERROR in getMessages controller:', error.message);
            return res.status(500).json({
                success: false,
                message: 'Internal server error',
                error: error.message
            });
        }
    }

    // Get messages by sender
    static async getMessagesBySender(req, res) {
        try {
            console.log('\n=== 👤 GET MESSAGES BY SENDER CONTROLLER CALLED ===');
            console.log('👤 Sender ID:', req.params.senderId);

            const { senderId } = req.params;

            if (!senderId) {
                return res.status(400).json({
                    success: false,
                    message: 'Sender ID is required'
                });
            }

            const result = await MessageService.getMessagesBySender(senderId);

            const statusCode = result.success ? 200 : 400;
            return res.status(statusCode).json(result);

        } catch (error) {
            console.log('❌ ERROR in getMessagesBySender controller:', error.message);
            return res.status(500).json({
                success: false,
                message: 'Internal server error',
                error: error.message
            });
        }
    }

    // Delete a message
    static async deleteMessage(req, res) {
        try {
            console.log('\n=== 🗑️ DELETE MESSAGE CONTROLLER CALLED ===');
            console.log('🆔 Message ID:', req.params.messageId);
            console.log('📄 Request Body:', req.body);

            const { messageId } = req.params;
            const { adminId, deleteForEveryone = false } = req.body;

            if (!messageId || !adminId) {
                return res.status(400).json({
                    success: false,
                    message: 'Message ID and Admin ID are required'
                });
            }

            const result = await MessageService.deleteMessage(messageId, adminId, deleteForEveryone);

            // Emit real-time event if Socket.io is available
            const io = req.app.get('io');
            if (io && result.success) {
                io.emit('message_deleted', {
                    messageId: messageId,
                    deletedBy: adminId
                });
                console.log(`📡 Real-time delete event sent for message: ${messageId}`);
            }

            const statusCode = result.success ? 200 : (result.message.includes('not found') ? 404 : 400);
            return res.status(statusCode).json(result);

        } catch (error) {
            console.log('❌ ERROR in deleteMessage controller:', error.message);
            return res.status(500).json({
                success: false,
                message: 'Internal server error',
                error: error.message
            });
        }
    }
}

module.exports = MessageController;