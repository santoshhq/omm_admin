// test_message_backend.js
// Run this script to test if your message backend is working
// Command: node test_message_backend.js

const http = require('http');

console.log('🔍 Testing Message Backend...\n');

// Test 1: Check if server is running
const testServer = () => {
  return new Promise((resolve, reject) => {
    const req = http.get('http://localhost:8080/api/test', (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        console.log('✅ Server is running');
        console.log(`📊 Status: ${res.statusCode}`);
        if (res.statusCode === 200) {
          console.log(`📄 Response: ${data}`);
        }
        resolve(true);
      });
    });

    req.on('error', (err) => {
      console.log('❌ Server is NOT running');
      console.log('💡 Please start your backend server first');
      reject(false);
    });

    req.setTimeout(3000, () => {
      console.log('⏰ Server connection timeout');
      req.destroy();
      reject(false);
    });
  });
};

// Test 2: Check if message routes are registered
const testMessageRoutes = () => {
  return new Promise((resolve, reject) => {
    const req = http.get('http://localhost:8080/api/complaints/test', (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          console.log('✅ Message routes are registered');
          console.log(`📄 Response: ${data}`);
          resolve(true);
        } else {
          console.log('❌ Message routes are NOT registered');
          console.log(`📊 Status: ${res.statusCode}`);
          console.log(`📄 Response: ${data}`);
          reject(false);
        }
      });
    });

    req.on('error', (err) => {
      console.log('❌ Message routes test failed');
      console.log(`🔥 Error: ${err.message}`);
      reject(false);
    });

    req.setTimeout(3000, () => {
      console.log('⏰ Message routes test timeout');
      req.destroy();
      reject(false);
    });
  });
};

// Test 3: Test a specific complaint messages endpoint
const testSpecificRoute = (complaintId = '507f1f77bcf86cd799439011') => {
  return new Promise((resolve, reject) => {
    const url = `http://localhost:8080/api/complaints/${complaintId}/messages`;
    const req = http.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200 || res.statusCode === 400) {
          console.log('✅ Message endpoint is working');
          console.log(`📊 Status: ${res.statusCode}`);
          console.log(`📄 Response: ${data.substring(0, 200)}...`);
          resolve(true);
        } else {
          console.log('❌ Message endpoint returned unexpected status');
          console.log(`📊 Status: ${res.statusCode}`);
          console.log(`📄 Response: ${data.substring(0, 200)}...`);
          reject(false);
        }
      });
    });

    req.on('error', (err) => {
      console.log('❌ Message endpoint test failed');
      console.log(`🔥 Error: ${err.message}`);
      reject(false);
    });

    req.setTimeout(3000, () => {
      console.log('⏰ Message endpoint test timeout');
      req.destroy();
      reject(false);
    });
  });
};

// Run all tests
const runTests = async () => {
  try {
    console.log('📋 Test 1: Checking server status...');
    await testServer();
    console.log('');

    console.log('📋 Test 2: Checking message routes...');
    await testMessageRoutes();
    console.log('');

    console.log('📋 Test 3: Testing message endpoint...');
    await testSpecificRoute();
    console.log('');

    console.log('🎉 All tests passed! Your message backend is ready!');
    console.log('');
    console.log('📱 You can now test the Flutter app image messaging feature.');

  } catch (error) {
    console.log('');
    console.log('❌ Some tests failed. Please check your backend setup.');
    console.log('');
    console.log('📝 Next steps:');
    console.log('1. Make sure your server is running: node server.js');
    console.log('2. Check that you added the message routes to your server');
    console.log('3. Install required dependencies: npm install multer sharp');
    console.log('4. Restart your server after making changes');
  }
};

runTests();