// routes/admin-amenities.js
const express = require('express');
const router = express.Router();
const {
  createAmenity,
  getAllAmenities,
  getAmenityById,
  updateAmenity,
  deleteAmenity,
  toggleAmenityStatus
} = require('../controllers/amenitiesController'); // Update path as needed

// Route: POST /api/admin-amenities/create
// Description: Create a new amenity
router.post('/create', createAmenity);

// Route: GET /api/admin-amenities/admin/:adminId
// Description: Get all amenities for a specific admin
router.get('/admin/:adminId', getAllAmenities);

// Route: GET /api/admin-amenities/admin/:adminId/amenity/:amenityId
// Description: Get a specific amenity by ID
router.get('/admin/:adminId/amenity/:amenityId', getAmenityById);

// Route: PUT /api/admin-amenities/admin/:adminId/amenity/:amenityId
// Description: Update a specific amenity
router.put('/admin/:adminId/amenity/:amenityId', updateAmenity);

// Route: DELETE /api/admin-amenities/admin/:adminId/amenity/:amenityId
// Description: Delete a specific amenity (soft delete by default, hard delete with ?hardDelete=true)
router.delete('/admin/:adminId/amenity/:amenityId', deleteAmenity);

// Route: PATCH /api/admin-amenities/admin/:adminId/amenity/:amenityId/toggle-status
// Description: Toggle amenity active/inactive status
router.patch('/admin/:adminId/amenity/:amenityId/toggle-status', toggleAmenityStatus);

module.exports = router;