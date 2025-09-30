# 🖼️ Backend Fix for Event Images

## 🎯 Problem Analysis

Your Flutter app is getting this error:
```
Error creating event card: FormatException: Unexpected character (at character 1)
<!DOCTYPE html>
```

This means your **backend is returning HTML (error page) instead of JSON** when processing base64 image data.

## ✅ Working Solution (Based on Amenities)

I analyzed your amenities system and found it works perfectly with images. Here's how to implement the same approach for events:

### 🔧 Backend Changes Needed

#### 1. Update Your Event Model Schema
```javascript
// In your events.cards.js model
const eventSchema = new mongoose.Schema({
  name: { type: String, required: true },
  description: { type: String, required: true },
  startdate: { type: Date, required: true },
  enddate: { type: Date, required: true },
  targetamount: { type: Number, required: true },
  collectedamount: { type: Number, default: 0 },
  // Change this from single image to array like amenities
  images: [{ type: String }], // Array of base64 or URL strings
  adminId: { type: mongoose.Schema.Types.ObjectId, ref: 'Admin', required: true },
  eventdetails: [{ type: String }],
  status: { type: Boolean, default: true },
  donations: [{
    donorName: String,
    donorFlat: String,
    amount: Number,
    date: { type: Date, default: Date.now }
  }]
}, { timestamps: true });
```

#### 2. Update Event Creation Controller
```javascript
// In your events controller
const createEvent = async (req, res) => {
  try {
    const { 
      name, 
      description, 
      startdate, 
      enddate, 
      targetamount, 
      eventdetails, 
      adminId,
      image  // This will be base64 data or null
    } = req.body;

    console.log('Creating event:', { name, hasImage: !!image });

    // Handle image data
    let images = [];
    if (image && image.startsWith('data:image/')) {
      // Process base64 image similar to amenities
      try {
        // Extract image data
        const matches = image.match(/^data:image\/([a-zA-Z]+);base64,(.+)$/);
        if (matches) {
          const extension = matches[1];
          const imageData = matches[2];
          
          // Create uploads directory if it doesn't exist
          const fs = require('fs');
          const path = require('path');
          const uploadsDir = path.join(__dirname, '..', 'uploads', 'events');
          if (!fs.existsSync(uploadsDir)) {
            fs.mkdirSync(uploadsDir, { recursive: true });
          }

          // Generate filename
          const filename = `event_${Date.now()}.${extension}`;
          const filePath = path.join(uploadsDir, filename);

          // Save the file
          fs.writeFileSync(filePath, imageData, 'base64');

          // Store the URL path
          const imageUrl = `/uploads/events/${filename}`;
          images.push(imageUrl);
          console.log('✅ Image saved:', imageUrl);
        }
      } catch (error) {
        console.error('Error processing image:', error);
        // Continue without image rather than failing
      }
    }

    // Create event
    const newEvent = new EventCard({
      name,
      description,
      startdate: new Date(startdate),
      enddate: new Date(enddate),
      targetamount,
      eventdetails: eventdetails || [],
      adminId,
      images, // Use images array instead of single image
      collectedamount: 0,
      status: true
    });

    const savedEvent = await newEvent.save();

    res.status(201).json({
      success: true,
      message: 'Event created successfully',
      data: savedEvent
    });

  } catch (error) {
    console.error('Error creating event:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create event: ' + error.message
    });
  }
};
```

#### 3. Add Static File Serving
```javascript
// In your main server file (app.js or server.js)
const express = require('express');
const path = require('path');
const app = express();

// Serve uploaded files (add this line)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Your existing routes...
```

#### 4. Update Event Retrieval
```javascript
// Make sure your get events endpoint returns the images array
const getEvents = async (req, res) => {
  try {
    const events = await EventCard.find({})
      .populate('adminId', 'name email')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: events
    });
  } catch (error) {
    console.error('Error fetching events:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch events'
    });
  }
};
```

### 📱 Flutter Changes (After Backend Fix)

Once you implement the backend changes, update the Flutter side:

```dart
// In add_event.dart, change the image handling back to:
final imageBase64 = await _getImageAsBase64();
imageToSend = imageBase64; // Send the base64 data

// In modules.dart, update Festival model:
class Festival {
  final List<String> images; // Change from single imageUrl to images array
  
  // Update fromJson:
  factory Festival.fromJson(Map<String, dynamic> json) {
    return Festival(
      // ... other fields
      images: List<String>.from(json['images'] ?? []),
    );
  }
}

// In festival_widget.dart, update image display:
Widget _buildEventImage(Festival fest) {
  if (fest.images.isNotEmpty) {
    return Image.network(
      fest.images.first, // Use first image
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.celebration, size: 50, color: Colors.deepPurple);
      },
    );
  }
  return const Icon(Icons.celebration, size: 50, color: Colors.deepPurple);
}
```

## 🚀 Quick Test Steps

1. **Implement backend changes** above
2. **Restart your backend server**
3. **Test event creation** without image first
4. **Test event creation** with image
5. **Verify images display** in event cards

## 💡 Why This Approach Works

- ✅ **Matches working amenities system**
- ✅ **Handles base64 data properly**
- ✅ **Saves images as actual files**
- ✅ **Returns accessible URLs**
- ✅ **Graceful error handling**

## 🔍 Debugging Tips

If still having issues:

1. **Check server logs** when creating events
2. **Verify uploads folder** is created and writable
3. **Test image URLs** directly in browser
4. **Check file permissions** on uploads directory

The temporary Flutter fix I applied will create events without images until you implement the backend changes.