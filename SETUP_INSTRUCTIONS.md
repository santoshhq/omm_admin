# 🚀 OMM Admin App - Setup Instructions

## 📋 Prerequisites

- **Node.js** (for backend server)
- **Flutter SDK** (for mobile app)
- **MongoDB** (database)
- **Android Studio/VS Code** (development environment)

## 🖥️ Backend Server Setup

1. **Start MongoDB** (if not already running)
2. **Navigate to your backend project folder** and run:
   ```bash
   node server.js
   ```
3. **Verify server is running** - You should see:
   ```bash
   Server is running on port http://localhost:8080
   ```

## 📱 Frontend Flutter App Setup

### Option 1: Run on Android Emulator
1. **Start Android Emulator** from Android Studio
2. **Run Flutter app**:
   ```bash
   flutter run
   ```
3. **The app will automatically use `10.0.2.2:8080`** to connect to your backend

### Option 2: Run on Web/Desktop
1. **Run Flutter app**:
   ```bash
   flutter run -d chrome
   # or
   flutter run -d windows
   ```
2. **The app will use `localhost:8080`** to connect to your backend

### Option 3: Run on Physical Android Device
1. **Connect your Android device via USB**
2. **Enable USB Debugging** on your device
3. **Make sure your device is on the same Wi-Fi network as your computer**
4. **Update the API config** to use your computer's IP address:
   - Find your computer's IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
   - Update `lib/config/api_config.dart` to use your IP instead of localhost

## 🔧 Testing the Connection

### Test Backend (Run these commands in PowerShell):

```powershell
# Test if backend is running
Invoke-WebRequest -Uri "http://localhost:8080/" -Method GET

# Test signup endpoint
$body = @{email="test@example.com"; password="test123"} | ConvertTo-Json
Invoke-WebRequest -Uri "http://localhost:8080/api/auth/signup" -Method POST -Body $body -ContentType "application/json"
```

### Test Frontend:
1. **Open the Flutter app**
2. **Try to create an account** with any email/password
3. **Check the console/debug output** for connection messages

## 🐛 Troubleshooting

### ❌ "Cannot connect to server" Error:

1. **Verify backend is running**:
   ```bash
   curl http://localhost:8080/
   ```

2. **Check if MongoDB is running**

3. **For Android Emulator**: Make sure you're using `10.0.2.2:8080`

4. **For Physical Device**: Use your computer's actual IP address

### ❌ Network Security Error (Android):

The app includes network security config to allow HTTP connections. If you still get errors:

1. **Check `android/app/src/main/AndroidManifest.xml`** has:
   ```xml
   android:networkSecurityConfig="@xml/network_security_config"
   ```

2. **Check `android/app/src/main/res/xml/network_security_config.xml`** exists

## 📝 API Endpoints

- **POST** `/api/auth/signup` - Create new account
- **POST** `/api/auth/verify-otp` - Verify OTP
- **POST** `/api/auth/login` - User login
- **POST** `/api/auth/forgot-password` - Send reset OTP
- **POST** `/api/auth/reset-password` - Reset password with OTP

## 🎯 Expected Flow

1. **User fills signup form** → Backend creates user with OTP
2. **OTP sent to user** → Display OTP on screen (for development)
3. **User enters OTP** → Backend verifies and activates account
4. **User can now login** → Backend authenticates and returns success

## 📞 Need Help?

- **Backend not starting**: Check if port 8080 is available
- **MongoDB issues**: Ensure MongoDB service is running
- **Flutter build errors**: Run `flutter clean && flutter pub get`
- **Network issues**: Check firewall settings and Wi-Fi connectivity