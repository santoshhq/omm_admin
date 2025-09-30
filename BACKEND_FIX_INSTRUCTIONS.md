// BACKEND FIX - Update your server.js file
// Change this line in your server.js:

// FROM:
// app.use(`${API_PREFIX}/amenities`, amenitiesRouter);

// TO:
app.use(`${API_PREFIX}/admin-amenities`, amenitiesRouter);

// This will make your backend match your Flutter app's expected endpoints:
// - GET /api/admin-amenities/admin/:adminId  
// - POST /api/admin-amenities/admin/:adminId
// - etc.

// IMPORTANT: Also update your routes file adding.amenities.routers.js
// Your routes currently use:
// router.post('/admin/:adminId', createAmenity);
// router.get('/admin/:adminId', getAllAmenities);

// But your Flutter app expects:
// router.post('/create', createAmenity);  // For create endpoint
// router.get('/admin/:adminId', getAllAmenities);  // This one is correct

// So update the CREATE route in your adding.amenities.routers.js:
// Change:
// router.post('/admin/:adminId', createAmenity);
// To:
// router.post('/create', createAmenity);

// And update the createAmenity controller to get adminId from body instead of params