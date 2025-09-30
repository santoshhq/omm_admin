// Backend Route Checker - Run this to check if amenities routes are working
// Command: node check_backend_routes.js

const http = require('http');

console.log('🔍 Checking Backend Routes Status...\n');

// Test basic server health
const checkServer = () => {
  return new Promise((resolve, reject) => {
    const req = http.get('http://localhost:8080', (res) => {
      console.log('✅ Backend server is running');
      console.log(`📊 Status: ${res.statusCode}`);
      resolve(true);
    });

    req.on('error', (err) => {
      console.log('❌ Backend server is NOT running');
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

// Test amenities routes
const checkAmenitiesRoutes = () => {
  return new Promise((resolve) => {
    const adminId = "68d664d7d84448fff5dc3a8b"; // Your admin ID from Flutter logs
    
    const options = {
      hostname: 'localhost',
      port: 8080,
      path: `/api/admin-amenities/admin/${adminId}`,
      method: 'GET',
      timeout: 5000
    };

    const req = http.request(options, (res) => {
      console.log(`📊 Amenities Route Status: ${res.statusCode}`);
      
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        if (res.statusCode === 200) {
          console.log('✅ Amenities routes are working!');
          console.log('📄 Response preview:', data.substring(0, 100));
          resolve('WORKING');
        } else if (res.statusCode === 404) {
          console.log('❌ Amenities routes are NOT registered');
          console.log('📄 Response:', data.substring(0, 200));
          resolve('NOT_REGISTERED');
        } else {
          console.log(`⚠️ Amenities routes returned ${res.statusCode}`);
          console.log('📄 Response:', data.substring(0, 200));
          resolve('ERROR');
        }
      });
    });

    req.on('error', (err) => {
      console.log('❌ Error checking amenities routes:', err.message);
      resolve('NETWORK_ERROR');
    });

    req.on('timeout', () => {
      console.log('⏰ Amenities route check timeout');
      req.destroy();
      resolve('TIMEOUT');
    });

    req.end();
  });
};

// Main diagnostic function
const runDiagnostic = async () => {
  try {
    console.log('='.repeat(50));
    console.log('🏥 BACKEND DIAGNOSTIC REPORT');
    console.log('='.repeat(50));
    
    // Check server
    console.log('\n1️⃣ Testing Backend Server...');
    await checkServer();
    
    // Check amenities routes
    console.log('\n2️⃣ Testing Amenities Routes...');
    const routeStatus = await checkAmenitiesRoutes();
    
    // Final report
    console.log('\n' + '='.repeat(50));
    console.log('📋 DIAGNOSTIC SUMMARY');
    console.log('='.repeat(50));
    
    console.log('Backend Server: ✅ Running');
    
    switch(routeStatus) {
      case 'WORKING':
        console.log('Amenities Routes: ✅ Working');
        console.log('\n🎉 Everything is working! Your Flutter app should work now.');
        break;
        
      case 'NOT_REGISTERED':
        console.log('Amenities Routes: ❌ Not Registered');
        console.log('\n🔧 SOLUTION:');
        console.log('1. Copy these files to your backend project:');
        console.log('   - backend_amenities_controller.js → controllers/amenitiesController.js');
        console.log('   - backend_amenities_routes.js → routes/admin-amenities.js');
        console.log('   - backend_amenity_model.js → models/Amenity.js');
        console.log('2. Add this line to your main server file:');
        console.log('   app.use(\'/api/admin-amenities\', require(\'./routes/admin-amenities\'));');
        console.log('3. Restart your backend server');
        break;
        
      default:
        console.log('Amenities Routes: ⚠️ Unknown Status');
        console.log('\n💡 Check your backend server logs for errors');
    }
    
    console.log('\n📖 For detailed instructions, see: QUICK_FIX_SUMMARY.md');
    console.log('='.repeat(50));
    
  } catch (error) {
    console.log('\n❌ Diagnostic failed:', error);
  }
};

// Run the diagnostic
runDiagnostic();