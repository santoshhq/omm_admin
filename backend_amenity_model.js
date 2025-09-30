const mongoose = require('mongoose');

const amenitySchema = new mongoose.Schema({
  createdByAdminId: { 
    type: String, 
    required: true,
    index: true // Add index for faster queries by admin
  },
  name: { 
    type: String, 
    required: true,
    trim: true
  },
  description: { 
    type: String, 
    required: true,
    trim: true
  },
  capacity: { 
    type: Number, 
    required: true,
    min: 1
  },
  imagePaths: [{ 
    type: String,
    trim: true
  }],
  location: { 
    type: String, 
    required: true,
    trim: true
  },
  hourlyRate: { 
    type: Number, 
    required: true,
    min: 0
  },
  features: [{ 
    type: String,
    trim: true
  }],
  active: { 
    type: Boolean, 
    default: true
  }
}, {
  timestamps: true // This adds createdAt and updatedAt automatically
});

// Add indexes for better query performance
amenitySchema.index({ createdByAdminId: 1, active: 1 });
amenitySchema.index({ name: 1 });

// Add a virtual for formatted rate
amenitySchema.virtual('formattedRate').get(function() {
  return `₹${this.hourlyRate}/hour`;
});

// Ensure virtual fields are serialized
amenitySchema.set('toJSON', { virtuals: true });

module.exports = mongoose.model('Amenity', amenitySchema);