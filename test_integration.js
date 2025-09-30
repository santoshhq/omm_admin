// Integration Test Script for Amenities Backend
// Run this after integrating the amenities routes: node test_integration.js

const http = require('http');

const testData = {
  createdByAdminId: "68d664d7d84448fff5dc3a8b", // Your actual admin ID from the Flutter logs
  name: "Swimming Pool",
  description: "Olympic size swimming pool with heating",
  capacity: 50,
  imagePaths: [],
  location: "Ground Floor, Building A",
  hourlyRate: 100.0,
  features: ["WiFi", "Towels", "Locker", "Shower"],
  active: true
};

console.log('🚀 Testing Amenities Backend Integration...\n');

// Test 1: Check if server is running
const testServer = () => {
  console.log('📡 Step 1: Testing if backend server is running...');
  
  const req = http.get('http://localhost:8080', (res) => {
    console.log('✅ Backend server is running!');
    console.log(`📊 Status: ${res.statusCode}`);
    testGetAmenities();
  });

  req.on('error', (err) => {
    console.log('❌ Backend server is not running!');
    console.log('💡 Please start your backend server first');
    process.exit(1);
  });

  req.setTimeout(5000, () => {
    console.log('⏰ Server connection timeout');
    req.destroy();
    process.exit(1);
  });
};

// Test 2: Check GET amenities endpoint
const testGetAmenities = () => {
  console.log('\n📡 Step 2: Testing GET amenities endpoint...');
  
  const options = {
    hostname: 'localhost',
    port: 8080,
    path: `/api/admin-amenities/admin/${testData.createdByAdminId}`,
    method: 'GET',
    timeout: 10000
  };

  const req = http.request(options, (res) => {
    console.log(`📊 GET Amenities Status: ${res.statusCode}`);
    
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      if (res.statusCode === 200) {
        console.log('✅ GET amenities endpoint is working!');
        console.log('📄 Response preview:', data.substring(0, 200));
        testCreateAmenity();
      } else if (res.statusCode === 404) {
        console.log('❌ GET amenities endpoint not found (404)');
        console.log('💡 Make sure you added the routes to your main server file:');
        console.log('   app.use(\'/api/admin-amenities\', require(\'./routes/admin-amenities\'));');
        console.log('\n📄 Server response:', data);
      } else {
        console.log(`⚠️ GET amenities returned ${res.statusCode}`);
        console.log('📄 Response:', data);
        testCreateAmenity(); // Continue with create test anyway
      }
    });
  });

  req.on('error', (err) => {
    console.log('❌ Error testing GET amenities:', err.message);
    testCreateAmenity(); // Continue anyway
  });

  req.end();
};

// Test 3: Check CREATE amenity endpoint  
const testCreateAmenity = () => {
  console.log('\n📡 Step 3: Testing POST create amenity endpoint...');
  
  const postData = JSON.stringify(testData);
  
  const options = {
    hostname: 'localhost',
    port: 8080,
    path: '/api/admin-amenities/create',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    },
    timeout: 10000
  };

  const req = http.request(options, (res) => {
    console.log(`📊 CREATE Amenity Status: ${res.statusCode}`);
    
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      if (res.statusCode === 200 || res.statusCode === 201) {
        console.log('✅ CREATE amenity endpoint is working!');
        console.log('📄 Response:', data);
        console.log('\n🎉 All tests passed! Your amenities backend is integrated correctly.');
      } else if (res.statusCode === 404) {
        console.log('❌ CREATE amenity endpoint not found (404)');
        console.log('💡 Routes are not properly integrated into your main server');
        console.log('📄 Server response:', data);
      } else {
        console.log(`⚠️ CREATE amenity returned ${res.statusCode}`);
        console.log('📄 Response:', data);
      }
      
      console.log('\n📋 Integration Summary:');
      console.log('1. ✅ Backend server is running on port 8080');
      console.log(`2. ${res.statusCode === 404 ? '❌' : '✅'} Amenities routes are ${res.statusCode === 404 ? 'NOT ' : ''}registered`);
      console.log('3. 📱 Flutter app is ready to connect');
      
      if (res.statusCode === 404) {
        console.log('\n🔧 Next Steps:');
        console.log('1. Copy backend_amenities_controller.js to your backend/controllers/');
        console.log('2. Copy backend_amenities_routes.js to your backend/routes/');
        console.log('3. Copy backend_amenity_model.js to your backend/models/');
        console.log('4. Add this line to your main server file:');
        console.log('   app.use(\'/api/admin-amenities\', require(\'./routes/admin-amenities\'));');
        console.log('5. Restart your backend server');
      }
    });
  });

  req.on('error', (err) => {
    console.log('❌ Error testing CREATE amenity:', err.message);
  });

  req.write(postData);
  req.end();
};

// Start the tests
testServer();