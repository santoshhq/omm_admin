# 🚀 Backend Server Setup Instructions

## 1. Start Your Backend Server

Make sure your Node.js backend server is running on **http://localhost:8080**

### To start your server:

```bash
# Navigate to your backend directory
cd path/to/your/backend/project

# Install dependencies (if not already done)
npm install

# Start the server
node server.js
# OR
npm start
```

### Required Dependencies in your backend:
```bash
npm install express mongoose bcrypt body-parser
```

## 2. Verify Server is Running

Open your browser and go to: **http://localhost:8080**

You should see: "Hello World!"

## 3. Test API Endpoints

You can test your API endpoints using Postman:

### Signup Test:
- **URL**: `POST http://localhost:8080/api/auth/signup`
- **Body** (JSON):
```json
{
    "email": "test@example.com",
    "password": "password123"
}
```

### Expected Response:
```json
{
    "status": true,
    "message": "User registered successfully. OTP sent to your email. Please verify within 10 minutes.",
    "data": {
        "id": "user_id",
        "email": "test@example.com",
        "otp": "123456",
        "expiresAt": "2025-09-25T10:15:00.000Z"
    }
}
```

## 4. Common Issues:

### If you get "Cannot connect to server" error:
1. Make sure your backend server is running
2. Check if MongoDB is connected
3. Verify the port is 8080
4. Check for any error messages in your backend console

### If you get CORS errors:
Add CORS middleware to your backend:
```javascript
const cors = require('cors');
app.use(cors());
```

## 5. Flutter App Changes Made:

✅ **Removed mock responses** - Now connects to real backend
✅ **Added detailed logging** - Check Flutter console for API call details
✅ **Better error handling** - Shows specific connection errors
✅ **Password confirmation validation** - Already working in signup form

## 6. Testing Flow:

1. Start your backend server
2. Run your Flutter app
3. Try to signup with email and password
4. Check Flutter console for API call logs
5. Check your MongoDB to see if user was created
6. Use the OTP from the backend response to verify

---

**Note**: The Flutter app will now show detailed error messages if it cannot connect to your backend server.