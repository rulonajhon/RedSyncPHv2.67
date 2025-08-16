@echo off
echo === RedSyncPH Admin Setup ===
echo.
echo This script will help you set up admin accounts for the application.
echo You'll need to manually create these accounts in Firebase Authentication.
echo.

echo 📋 Admin Email Addresses:
echo    • admin@redsyncph.com
echo    • superadmin@redsyncph.com
echo    • hemophilia.admin@redsyncph.com
echo.

echo 🔧 Setup Instructions:
echo.
echo 1. Go to Firebase Console (https://console.firebase.google.com)
echo 2. Select your RedSyncPH project
echo 3. Navigate to Authentication ^> Users
echo 4. Click 'Add User' for each admin email:
echo    - Email: Use one of the admin emails above
echo    - Password: Create a secure password (min 6 characters)
echo    - Make sure to save the passwords securely!
echo.

echo 5. Test the admin login:
echo    - Open the RedSyncPH app
echo    - Go to login screen
echo    - Enter admin email and password
echo    - You should be redirected to the Admin Dashboard
echo.

echo ⚠️  Important Notes:
echo    • Admin accounts don't need to be added to Firestore users collection
echo    • Admin detection is based on email address only
echo    • Keep admin credentials secure
echo    • Consider using strong, unique passwords
echo.

echo 📱 Admin Dashboard Features:
echo    • View pending doctor verifications
echo    • Approve/reject medical professional applications
echo    • Monitor verified doctors
echo    • View application statistics
echo    • Revoke doctor verifications if needed
echo.

echo ✅ Once you've created the admin accounts in Firebase:
echo    1. Test login with admin credentials
echo    2. Verify you can access the Admin Dashboard
echo    3. Check that pending verifications are displayed
echo.

echo === Setup Complete ===
echo For support, contact the development team.
echo.
pause
