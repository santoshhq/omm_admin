// Simple test script to check amenities API
// Save this as test_amenities_api.js and run with: node test_amenities_api.js

const http = require('http');

// Test if the server is running
const testServerRunning = () => {
  console.log('🔍 Testing if server is running on localhost:8080...');
  
  const options = {
    hostname: 'localhost',
    port: 8080,
    path: '/',
    method: 'GET',
    timeout: 5000
  };

  const req = http.request(options, (res) => {
    console.log('✅ Server is running!');
    console.log('📊 Status:', res.statusCode);
    console.log('📋 Headers:', res.headers);
    
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      console.log('📄 Response preview:', data.substring(0, 200));
      testAmenitiesEndpoint();
    });
  });

  req.on('error', (err) => {
    console.log('❌ Server is not running or not accessible');
    console.log('🔥 Error:', err.message);
    console.log('\n💡 Make sure your backend server is running on port 8080');
  });

  req.on('timeout', () => {
    console.log('⏰ Request timed out - server might be slow or not running');
    req.destroy();
  });

  req.end();
};

// Test the amenities endpoint
const testAmenitiesEndpoint = () => {
  console.log('\n🧪 Testing amenities endpoint...');
  
  const postData = JSON.stringify({
    createdByAdminId: "test-admin-id",
    name: "Test Pool",
    description: "Test swimming pool",
    capacity: 20,
    imagePaths: [],
    location: "Ground Floor",
    hourlyRate: 50.0,
    features: ["WiFi", "Towels"],
    active: true
  });

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
    console.log('📊 Amenities API Status:', res.statusCode);
    console.log('📋 Response Headers:', res.headers);
    
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      console.log('📄 Response Body:', data);
      
      if (res.statusCode === 200 || res.statusCode === 201) {
        console.log('✅ Amenities API is working!');
      } else if (res.statusCode === 404) {
        console.log('❌ Endpoint not found - routes are not registered');
        console.log('💡 Add the amenities routes to your backend server');
      } else {
        console.log('⚠️  API returned error status:', res.statusCode);
      }
    });
  });

  req.on('error', (err) => {
    console.log('❌ Error calling amenities API');
    console.log('🔥 Error:', err.message);
  });

  req.on('timeout', () => {
    console.log('⏰ Amenities API request timed out');
    req.destroy();
  });

  req.write(postData);
  req.end();
};

// Start the test
console.log('🚀 Starting Backend API Test...');
testServerRunning();