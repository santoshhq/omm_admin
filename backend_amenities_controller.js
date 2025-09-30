// controllers/amenitiesController.js
const {
  createAmenityService,
  getAllAmenitiesService,
  getAmenityByIdService,
  updateAmenityService,
  deleteAmenityService,
  toggleAmenityStatusService
} = require('../services/amenitiesService'); // Update path as needed

// Create Amenity Controller
const createAmenity = async (req, res) => {
  try {
    console.log('\n=== 🏢 CREATE AMENITY CONTROLLER CALLED ===');
    console.log('📨 Request Body:', req.body);
    
    const { createdByAdminId, name, description, capacity, imagePaths, location, hourlyRate, features, active } = req.body;
    
    // Validate required fields
    if (!createdByAdminId || !name || !description || capacity === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: createdByAdminId, name, description, capacity'
      });
    }

    const result = await createAmenityService(createdByAdminId, {
      name,
      description,
      capacity,
      imagePaths: imagePaths || [],
      location: location || '',
      hourlyRate: hourlyRate || 0.0,
      features: features || [],
      active: active !== undefined ? active : true
    });

    const statusCode = result.success ? 201 : 400;
    res.status(statusCode).json(result);

  } catch (error) {
    console.error('❌ Error in createAmenity controller:', error.message);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get All Amenities Controller
const getAllAmenities = async (req, res) => {
  try {
    console.log('\n=== 📋 GET ALL AMENITIES CONTROLLER CALLED ===');
    console.log('🔑 Admin ID:', req.params.adminId);
    console.log('🔍 Query filters:', req.query);

    const { adminId } = req.params;
    const filters = req.query;

    if (!adminId) {
      return res.status(400).json({
        success: false,
        message: 'Admin ID is required'
      });
    }

    const result = await getAllAmenitiesService(adminId, filters);
    const statusCode = result.success ? 200 : 400;
    res.status(statusCode).json(result);

  } catch (error) {
    console.error('❌ Error in getAllAmenities controller:', error.message);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get Amenity by ID Controller
const getAmenityById = async (req, res) => {
  try {
    console.log('\n=== 🔍 GET AMENITY BY ID CONTROLLER CALLED ===');
    console.log('🔑 Admin ID:', req.params.adminId);
    console.log('🏢 Amenity ID:', req.params.amenityId);

    const { adminId, amenityId } = req.params;

    if (!adminId || !amenityId) {
      return res.status(400).json({
        success: false,
        message: 'Admin ID and Amenity ID are required'
      });
    }

    const result = await getAmenityByIdService(adminId, amenityId);
    const statusCode = result.success ? 200 : 404;
    res.status(statusCode).json(result);

  } catch (error) {
    console.error('❌ Error in getAmenityById controller:', error.message);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Update Amenity Controller
const updateAmenity = async (req, res) => {
  try {
    console.log('\n=== ✏️ UPDATE AMENITY CONTROLLER CALLED ===');
    console.log('🔑 Admin ID:', req.params.adminId);
    console.log('🏢 Amenity ID:', req.params.amenityId);
    console.log('📨 Update Data:', req.body);

    const { adminId, amenityId } = req.params;
    const updateData = req.body;

    if (!adminId || !amenityId) {
      return res.status(400).json({
        success: false,
        message: 'Admin ID and Amenity ID are required'
      });
    }

    const result = await updateAmenityService(adminId, amenityId, updateData);
    const statusCode = result.success ? 200 : 400;
    res.status(statusCode).json(result);

  } catch (error) {
    console.error('❌ Error in updateAmenity controller:', error.message);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Delete Amenity Controller
const deleteAmenity = async (req, res) => {
  try {
    console.log('\n=== 🗑️ DELETE AMENITY CONTROLLER CALLED ===');
    console.log('🔑 Admin ID:', req.params.adminId);
    console.log('🏢 Amenity ID:', req.params.amenityId);
    console.log('💥 Hard Delete:', req.query.hardDelete === 'true');

    const { adminId, amenityId } = req.params;
    const hardDelete = req.query.hardDelete === 'true';

    if (!adminId || !amenityId) {
      return res.status(400).json({
        success: false,
        message: 'Admin ID and Amenity ID are required'
      });
    }

    const result = await deleteAmenityService(adminId, amenityId, hardDelete);
    const statusCode = result.success ? 200 : 400;
    res.status(statusCode).json(result);

  } catch (error) {
    console.error('❌ Error in deleteAmenity controller:', error.message);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Toggle Amenity Status Controller
const toggleAmenityStatus = async (req, res) => {
  try {
    console.log('\n=== 🔄 TOGGLE AMENITY STATUS CONTROLLER CALLED ===');
    console.log('🔑 Admin ID:', req.params.adminId);
    console.log('🏢 Amenity ID:', req.params.amenityId);

    const { adminId, amenityId } = req.params;

    if (!adminId || !amenityId) {
      return res.status(400).json({
        success: false,
        message: 'Admin ID and Amenity ID are required'
      });
    }

    const result = await toggleAmenityStatusService(adminId, amenityId);
    const statusCode = result.success ? 200 : 400;
    res.status(statusCode).json(result);

  } catch (error) {
    console.error('❌ Error in toggleAmenityStatus controller:', error.message);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

module.exports = {
  createAmenity,
  getAllAmenities,
  getAmenityById,
  updateAmenity,
  deleteAmenity,
  toggleAmenityStatus
};