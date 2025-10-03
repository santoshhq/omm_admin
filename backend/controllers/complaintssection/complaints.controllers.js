const ComplaintService = require('../../services/complaintssection/complaints.services');
const Messages = require('../../models/complaintssection/messages');

class ComplaintController {

    // Create new complaint - Auto-fetch user details
    static async createComplaint(req, res) {
        try {
            console.log('\n=== 📝 CREATE COMPLAINT CONTROLLER CALLED ===');
            console.log('📄 Request Body:', req.body);

            const { userId, isCreatedByAdmin = false, assignedToAdmin = null, title, description } = req.body;

            // Basic validation - name and flatNo are auto-fetched
            if (!userId || !title || !description) {
                return res.status(400).json({
                    success: false,  
                    message: 'Missing required fields: userId, title, description'
                });
            }

            const result = await ComplaintService.createComplaint({
                userId,
                isCreatedByAdmin,
                assignedToAdmin,
                title,
                description
            });

            const statusCode = result.success ? 201 : 400;
            return res.status(statusCode).json(result);

        } catch (error) {
            console.log('❌ ERROR in createComplaint controller:', error.message);
            return res.status(500).json({
                success: false,
                message: 'Internal server error',
                error: error.message
            });
        }
    }

    // Get all complaints for a specific admin
    static async getAdminComplaints(req, res) {
        try {
            console.log('\n=== 📋 GET ADMIN COMPLAINTS CONTROLLER CALLED ===');
            console.log('🔑 Admin ID:', req.params.adminId);

            const { adminId } = req.params;
            const { status } = req.query;

            if (!adminId) {
                return res.status(400).json({
                    success: false,
                    message: 'Admin ID is required'
                });
            }

            const result = await ComplaintService.getComplaintsByAdmin(adminId, {
                status
            });

            const statusCode = result.success ? 200 : 400;
            return res.status(statusCode).json(result);

        } catch (error) {
            console.log('❌ ERROR in getAdminComplaints controller:', error.message);
            return res.status(500).json({
                success: false,
                message: 'Internal server error',
                error: error.message
            });
        }
    }

    // Get complaint details with messages
    static async getComplaintDetails(req, res) {
        try {
            console.log('\n=== 🔍 GET COMPLAINT DETAILS CONTROLLER CALLED ===');
            console.log('📝 Complaint ID:', req.params.id);

            const { id } = req.params;

            if (!id) {
                return res.status(400).json({
                    success: false,
                    message: 'Complaint ID is required'
                });
            }

            const complaintResult = await ComplaintService.getComplaintById(id);

            if (!complaintResult.success) {
                return res.status(404).json(complaintResult);
            }

            // Get messages for this complaint
            try {
                const messages = await Messages.find({ complaintId: id })
                    .populate('senderId', 'firstName lastName email')
                    .sort({ timestamp: 1 });

                return res.status(200).json({
                    success: true,
                    message: 'Complaint details retrieved successfully',
                    data: {
                        complaint: complaintResult.data,
                        messages: messages || []
                    }
                });
            } catch (msgError) {
                // Return complaint even if messages fail
                return res.status(200).json({
                    success: true,
                    message: 'Complaint details retrieved (messages unavailable)',
                    data: {
                        complaint: complaintResult.data,
                        messages: []
                    }
                });
            }

        } catch (error) {
            console.log('❌ ERROR in getComplaintDetails controller:', error.message);
            return res.status(500).json({
                success: false,
                message: 'Internal server error',
                error: error.message
            });
        }
    }

    // Update complaint status
    static async updateStatus(req, res) {
        try {
            console.log('\n=== ✏️ UPDATE COMPLAINT STATUS CONTROLLER CALLED ===');
            console.log('📝 Complaint ID:', req.params.id);
            console.log('📄 Request Body:', req.body);

            const { id } = req.params;
            const { status, adminId } = req.body;

            if (!id) {
                return res.status(400).json({
                    success: false,
                    message: 'Complaint ID is required'
                });
            }

            if (!status) {
                return res.status(400).json({
                    success: false,
                    message: 'Status is required'
                });
            }

            if (!adminId) {
                return res.status(400).json({
                    success: false,
                    message: 'Admin ID is required for authorization'
                });
            }

            const result = await ComplaintService.updateComplaintStatus(id, status, adminId);

            const statusCode = result.success ? 200 : (result.message.includes('not found') ? 404 : 400);
            return res.status(statusCode).json(result);

        } catch (error) {
            console.log('❌ ERROR in updateStatus controller:', error.message);
            return res.status(500).json({
                success: false,
                message: 'Internal server error',
                error: error.message
            });
        }
    }

    // Get complaints by status
    static async getComplaintsByStatus(req, res) {
        try {
            console.log('\n=== 🏷️ GET COMPLAINTS BY STATUS CONTROLLER CALLED ===');
            console.log('🔑 Admin ID:', req.params.adminId);
            console.log('🔄 Status:', req.params.status);

            const { adminId, status } = req.params;

            if (!adminId) {
                return res.status(400).json({
                    success: false,
                    message: 'Admin ID is required'
                });
            }

            if (!status) {
                return res.status(400).json({
                    success: false,
                    message: 'Status is required'
                });
            }

            const result = await ComplaintService.getComplaintsByStatus(status);

            const statusCode = result.success ? 200 : 400;
            return res.status(statusCode).json(result);

        } catch (error) {
            console.log('❌ ERROR in getComplaintsByStatus controller:', error.message);
            return res.status(500).json({
                success: false,
                message: 'Internal server error',
                error: error.message
            });
        }
    }

    // Delete complaint and associated messages
    static async deleteComplaint(req, res) {
        try {
            console.log('\n=== 🗑️ DELETE COMPLAINT CONTROLLER CALLED ===');
            console.log('🆔 Complaint ID:', req.params.id);

            const { id } = req.params;

            if (!id) {
                return res.status(400).json({
                    success: false,
                    message: 'Complaint ID is required'
                });
            }

            const result = await ComplaintService.deleteComplaint(id);

            const statusCode = result.success ? 200 : 400;
            return res.status(statusCode).json(result);

        } catch (error) {
            console.log('❌ ERROR in deleteComplaint controller:', error.message);
            return res.status(500).json({
                success: false,
                message: 'Internal server error',
                error: error.message
            });
        }
    }
}

module.exports = ComplaintController;
