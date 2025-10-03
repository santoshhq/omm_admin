const Complaints = require('../../models/complaintssection/complaints');
const AdminMemberProfile = require('../../models/auth.models/adminMemberProfile');
const Messages = require('../../models/complaintssection/messages');

class ComplaintService {

    // Create a new complaint - Auto-fetch user details
    static async createComplaint({ userId, isCreatedByAdmin = false, assignedToAdmin = null, title, description }) {
        try {
            console.log('\n=== 📝 CREATE COMPLAINT SERVICE CALLED ===');
            console.log('👤 User ID:', userId);
            console.log('🔧 Created By Admin:', isCreatedByAdmin);
            console.log('👨‍💼 Assigned To Admin:', assignedToAdmin || 'Auto-assign later');
            console.log('📋 Title:', title);

            // Validate required fields
            if (!userId || !title || !description) {
                return {
                    success: false,
                    message: 'Missing required fields: userId, title, description'
                };
            }

            // Fetch user details automatically from AdminMemberProfile
            console.log('🔍 Searching for user in AdminMemberProfile...');
            
            let userProfile;
            try {
                userProfile = await AdminMemberProfile.findById(userId);
                console.log('🔍 User query completed. User found:', !!userProfile);
                
                if (!userProfile) {
                    console.log('❌ User not found in AdminMemberProfile collection');
                    return {
                        success: false,
                        message: 'User not found. Please check the userId.'
                    };
                }

                console.log('👤 Auto-fetched Name:', userProfile.firstName);
                console.log('🏠 Auto-fetched Flat No:', userProfile.flatNo);
            } catch (dbError) {
                console.error('❌ Database error while fetching user:', dbError.message);
                return {
                    success: false,
                    message: 'Database error while fetching user details'
                };
            }

            // Auto-assign to an admin if not specified
            let finalAssignedAdmin = assignedToAdmin;
            if (!assignedToAdmin) {
                console.log('🔄 Auto-assigning complaint to available admin...');
                try {
                    const AdminSignup = require('../../models/auth.models/signup');
                    const availableAdmin = await AdminSignup.findOne({}).sort({ createdAt: 1 }); // Get first available admin
                    if (availableAdmin) {
                        finalAssignedAdmin = availableAdmin._id;
                        console.log('✅ Auto-assigned to admin:', availableAdmin._id);
                    } else {
                        console.log('⚠️  No admin available for auto-assignment');
                    }
                } catch (adminError) {
                    console.log('⚠️  Could not auto-assign admin:', adminError.message);
                }
            }

            // Create complaint with auto-fetched user details
            const complaintData = {
                userId,
                assignedToAdmin: finalAssignedAdmin,  // Can be null if no admin available
                isCreatedByAdmin,
                name: userProfile.firstName + (userProfile.lastName ? ' ' + userProfile.lastName : ''),
                flatNo: userProfile.flatNo,
                title: title.trim(),
                description: description.trim()
            };

            const newComplaint = new Complaints(complaintData);
            const savedComplaint = await newComplaint.save();

            console.log('✅ Complaint created successfully with ID:', savedComplaint._id);

            return {
                success: true,
                message: 'Complaint created successfully with auto-fetched user details',
                data: savedComplaint
            };

        } catch (error) {
            console.error('❌ Error creating complaint:', error.message);
            
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
                message: 'Internal server error while creating complaint',
                error: error.message
            };
        }
    }

    // Get all complaints
    static async getAllComplaints() {
        try {
            console.log('\n=== 📋 GET ALL COMPLAINTS SERVICE CALLED ===');

            const complaints = await Complaints.find()
                .populate('userId', 'firstName lastName email mobile')
                .populate('assignedToAdmin', 'firstName lastName email mobile')
                .sort({ createdAt: -1 });

            console.log('📊 Total complaints found:', complaints.length);

            return {
                success: true,
                message: 'Complaints retrieved successfully',
                data: complaints,
                count: complaints.length
            };

        } catch (error) {
            console.error('❌ Error retrieving complaints:', error.message);
            return {
                success: false,
                message: 'Internal server error while retrieving complaints',
                error: error.message
            };
        }
    }

    // Get complaints by admin
    static async getComplaintsByAdmin(adminId, filters = {}) {
        try {
            console.log('\n=== 📋 GET COMPLAINTS BY ADMIN SERVICE CALLED ===');
            console.log('🔑 Admin ID:', adminId);
            console.log('🔍 Filters:', filters);

            if (!adminId) {
                return {
                    success: false,
                    message: 'Admin ID is required'
                };
            }

            // Build query
            const query = { assignedToAdmin: adminId };
            
            // Apply status filter if provided
            if (filters.status) {
                query.status = filters.status;
            }

            const complaints = await Complaints.find(query)
                .populate('userId', 'firstName lastName email mobile')
                .populate('assignedToAdmin', 'firstName lastName email mobile')
                .sort({ createdAt: -1 });

            console.log('📊 Total complaints found for admin:', complaints.length);

            return {
                success: true,
                message: 'Admin complaints retrieved successfully',
                data: complaints,
                count: complaints.length
            };

        } catch (error) {
            console.error('❌ Error retrieving admin complaints:', error.message);
            return {
                success: false,
                message: 'Internal server error while retrieving admin complaints',
                error: error.message
            };
        }
    }

    // Get complaint by ID
    static async getComplaintById(id) {
        try {
            console.log('\n=== 🔍 GET COMPLAINT BY ID SERVICE CALLED ===');
            console.log('🆔 Complaint ID:', id);

            if (!id) {
                return {
                    success: false,
                    message: 'Complaint ID is required'
                };
            }

            const complaint = await Complaints.findById(id)
                .populate('userId', 'firstName lastName email mobile')
                .populate('assignedToAdmin', 'firstName lastName email mobile');

            if (!complaint) {
                return {
                    success: false,
                    message: 'Complaint not found'
                };
            }

            console.log('✅ Complaint found:', complaint.title);

            return {
                success: true,
                message: 'Complaint retrieved successfully',
                data: complaint
            };

        } catch (error) {
            console.error('❌ Error retrieving complaint:', error.message);
            return {
                success: false,
                message: 'Internal server error while retrieving complaint',
                error: error.message
            };
        }
    }

    // Update complaint
    static async updateComplaint(id, updateData) {
        try {
            console.log('\n=== ✏️ UPDATE COMPLAINT SERVICE CALLED ===');
            console.log('🆔 Complaint ID:', id);
            console.log('📝 Update Data:', updateData);

            if (!id) {
                return {
                    success: false,
                    message: 'Complaint ID is required'
                };
            }

            // Remove undefined fields
            const cleanUpdateData = Object.fromEntries(
                Object.entries(updateData).filter(([key, value]) => value !== undefined && value !== null)
            );

            const updatedComplaint = await Complaints.findByIdAndUpdate(
                id,
                { ...cleanUpdateData, updatedAt: new Date() },
                { new: true, runValidators: true }
            ).populate('userId', 'firstName lastName email mobile')
             .populate('assignedToAdmin', 'firstName lastName email mobile');

            if (!updatedComplaint) {
                return {
                    success: false,
                    message: 'Complaint not found'
                };
            }

            console.log('✅ Complaint updated successfully');

            return {
                success: true,
                message: 'Complaint updated successfully',
                data: updatedComplaint
            };

        } catch (error) {
            console.error('❌ Error updating complaint:', error.message);
            
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
                message: 'Internal server error while updating complaint',
                error: error.message
            };
        }
    }

    // Delete complaint and associated messages
    static async deleteComplaint(id) {
        try {
            console.log('\n=== 🗑️ DELETE COMPLAINT SERVICE CALLED ===');
            console.log('🆔 Complaint ID:', id);

            if (!id) {
                return {
                    success: false,
                    message: 'Complaint ID is required'
                };
            }

            // First check if complaint exists
            const existingComplaint = await Complaints.findById(id);
            if (!existingComplaint) {
                return {
                    success: false,
                    message: 'Complaint not found'
                };
            }

            // Delete all messages associated with this complaint
            console.log('🗑️ Deleting associated messages...');
            const deletedMessages = await Messages.deleteMany({ complaintId: id });
            console.log(`🗑️ Deleted ${deletedMessages.deletedCount} associated messages`);

            // Delete the complaint
            const deletedComplaint = await Complaints.findByIdAndDelete(id);

            console.log('✅ Complaint and associated messages deleted successfully');

            return {
                success: true,
                message: `Complaint and ${deletedMessages.deletedCount} associated messages deleted successfully`,
                data: {
                    complaint: deletedComplaint,
                    deletedMessagesCount: deletedMessages.deletedCount
                }
            };

        } catch (error) {
            console.error('❌ Error deleting complaint:', error.message);
            return {
                success: false,
                message: 'Internal server error while deleting complaint',
                error: error.message
            };
        }
    }

    // Get complaints by status
    static async getComplaintsByStatus(status) {
        try {
            console.log('\n=== 📊 GET COMPLAINTS BY STATUS SERVICE CALLED ===');
            console.log('📈 Status:', status);

            if (!status) {
                return {
                    success: false,
                    message: 'Status is required'
                };
            }

            const validStatuses = ['pending', 'solved', 'unsolved'];
            if (!validStatuses.includes(status)) {
                return {
                    success: false,
                    message: `Invalid status. Valid statuses: ${validStatuses.join(', ')}`
                };
            }

            const complaints = await Complaints.find({ status })
                .populate('userId', 'firstName lastName email mobile')
                .populate('assignedToAdmin', 'firstName lastName email mobile')
                .sort({ createdAt: -1 });

            console.log(`📊 Total complaints with status '${status}':`, complaints.length);

            return {
                success: true,
                message: `Complaints with status '${status}' retrieved successfully`,
                data: complaints,
                count: complaints.length
            };

        } catch (error) {
            console.error('❌ Error retrieving complaints by status:', error.message);
            return {
                success: false,
                message: 'Internal server error while retrieving complaints by status',
                error: error.message
            };
        }
    }

    // Get complaints by user
    static async getComplaintsByUser(userId) {
        try {
            console.log('\n=== 👤 GET COMPLAINTS BY USER SERVICE CALLED ===');
            console.log('👤 User ID:', userId);

            if (!userId) {
                return {
                    success: false,
                    message: 'User ID is required'
                };
            }

            const complaints = await Complaints.find({ userId })
                .populate('userId', 'firstName lastName email mobile')
                .populate('assignedToAdmin', 'firstName lastName email mobile')
                .sort({ createdAt: -1 });

            console.log('📊 Total complaints by user:', complaints.length);

            return {
                success: true,
                message: 'User complaints retrieved successfully',
                data: complaints,
                count: complaints.length
            };

        } catch (error) {
            console.error('❌ Error retrieving user complaints:', error.message);
            return {
                success: false,
                message: 'Internal server error while retrieving user complaints',
                error: error.message
            };
        }
    }

    // Update complaint status
    static async updateComplaintStatus(id, status, adminComment = '') {
        try {
            console.log('\n=== 📈 UPDATE COMPLAINT STATUS SERVICE CALLED ===');
            console.log('🆔 Complaint ID:', id);
            console.log('📊 New Status:', status);
            console.log('💬 Admin Comment:', adminComment);

            if (!id || !status) {
                return {
                    success: false,
                    message: 'Complaint ID and status are required'
                };
            }

            const validStatuses = ['pending', 'solved', 'unsolved'];
            if (!validStatuses.includes(status)) {
                return {
                    success: false,
                    message: `Invalid status. Valid statuses: ${validStatuses.join(', ')}`
                };
            }

            const updateData = {
                status,
                updatedAt: new Date()
            };

            if (adminComment.trim()) {
                updateData.adminComment = adminComment.trim();
            }

            const updatedComplaint = await Complaints.findByIdAndUpdate(
                id,
                updateData,
                { new: true, runValidators: true }
            ).populate('userId', 'firstName lastName email mobile')
             .populate('assignedToAdmin', 'firstName lastName email mobile');

            if (!updatedComplaint) {
                return {
                    success: false,
                    message: 'Complaint not found'
                };
            }

            console.log('✅ Complaint status updated successfully');

            return {
                success: true,
                message: 'Complaint status updated successfully',
                data: updatedComplaint
            };

        } catch (error) {
            console.error('❌ Error updating complaint status:', error.message);
            return {
                success: false,
                message: 'Internal server error while updating complaint status',
                error: error.message
            };
        }
    }

}

module.exports = ComplaintService;