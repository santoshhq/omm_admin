// Backend modifications needed for image handling
// Add this to your events.cards.js controller or wherever you handle event creation

const fs = require('fs');
const path = require('path');

// Function to handle base64 image data
function saveBase64Image(base64Data, eventId) {
  try {
    if (!base64Data || !base64Data.startsWith('data:image/')) {
      return null;
    }

    // Extract the image data and extension
    const matches = base64Data.match(/^data:image\/([a-zA-Z]+);base64,(.+)$/);
    if (!matches) {
      return null;
    }

    const extension = matches[1];
    const imageData = matches[2];
    
    // Create uploads directory if it doesn't exist
    const uploadsDir = path.join(__dirname, '..', 'uploads', 'events');
    if (!fs.existsSync(uploadsDir)) {
      fs.mkdirSync(uploadsDir, { recursive: true });
    }

    // Generate filename
    const filename = `event_${eventId}_${Date.now()}.${extension}`;
    const filePath = path.join(uploadsDir, filename);

    // Save the file
    fs.writeFileSync(filePath, imageData, 'base64');

    // Return the URL path (adjust based on your server setup)
    return `/uploads/events/${filename}`;
  } catch (error) {
    console.error('Error saving base64 image:', error);
    return null;
  }
}

// Update your create event endpoint to use this function
// Example modification for your create endpoint:

async function createEvent(req, res) {
  try {
    const { image, name, startdate, enddate, description, targetamount, eventdetails, adminId } = req.body;

    // Create the event first to get an ID
    const newEvent = new EventCard({
      name,
      startdate,
      enddate,
      description,
      targetamount,
      eventdetails,
      adminId,
      // Don't set image yet
    });

    const savedEvent = await newEvent.save();

    // Handle image if provided
    let imageUrl = null;
    if (image) {
      if (image.startsWith('data:image/')) {
        // It's base64 data, save it as a file
        imageUrl = saveBase64Image(image, savedEvent._id);
      } else if (image.startsWith('http')) {
        // It's already a URL
        imageUrl = image;
      }
      // If it's a local file path, ignore it (don't save)
    }

    // Update the event with the image URL
    if (imageUrl) {
      savedEvent.image = imageUrl;
      await savedEvent.save();
    }

    res.status(201).json({
      success: true,
      message: 'Event created successfully',
      data: savedEvent
    });
  } catch (error) {
    console.error('Error creating event:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create event'
    });
  }
}

// Also add static file serving for uploaded images
// Add this to your main server file (app.js or server.js):

const express = require('express');
const app = express();

// Serve uploaded files
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Export the function if you're using modules
module.exports = { saveBase64Image, createEvent };