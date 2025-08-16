#!/bin/bash

# RedSync iOS Build and Deploy Script for macOS
# Run this script on your Mac to build and deploy the iOS app

echo "🍎 RedSync iOS Build & Deploy Script"
echo "=================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script must be run on macOS"
    exit 1
fi

print_status "Step 1: Checking macOS environment..."

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode is not installed. Please install Xcode from the Mac App Store."
    exit 1
fi
print_success "Xcode is installed"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed. Please install Flutter first."
    echo "Visit: https://docs.flutter.dev/get-started/install/macos"
    exit 1
fi
print_success "Flutter is installed"

# Check if CocoaPods is installed
if ! command -v pod &> /dev/null; then
    print_warning "CocoaPods not found. Installing..."
    sudo gem install cocoapods
    pod setup
fi
print_success "CocoaPods is ready"

print_status "Step 2: Running Flutter Doctor..."
flutter doctor

print_status "Step 3: Cleaning previous builds..."
flutter clean
print_success "Previous builds cleaned"

print_status "Step 4: Getting Flutter dependencies..."
flutter pub get
if [ $? -ne 0 ]; then
    print_error "Failed to get Flutter dependencies"
    exit 1
fi
print_success "Flutter dependencies ready"

print_status "Step 5: Installing iOS dependencies..."
cd ios
pod install
if [ $? -ne 0 ]; then
    print_error "Failed to install iOS dependencies"
    exit 1
fi
cd ..
print_success "iOS dependencies installed"

print_status "Step 6: Building iOS app..."
flutter build ios --release
if [ $? -ne 0 ]; then
    print_error "iOS build failed"
    exit 1
fi
print_success "iOS build completed successfully!"

print_status "Step 7: Checking for connected iOS devices..."
flutter devices

echo ""
echo "🎉 Build Complete!"
echo "=================="
echo ""
print_success "Your RedSync iOS app has been built successfully!"
echo ""
echo "📱 Next Steps:"
echo "1. Connect your iPhone to this Mac via USB cable"
echo "2. Unlock your iPhone and trust this computer"
echo "3. Choose one of the deployment options below:"
echo ""
echo "📋 Deployment Options:"
echo ""
echo "Option A - Deploy via Flutter:"
echo "  flutter run --release -d \"iPhone Name\""
echo ""
echo "Option B - Deploy via Xcode:"
echo "  open ios/Runner.xcworkspace"
echo "  • Select your iPhone from device dropdown"
echo "  • Click the Play button (▶️) to run"
echo ""
echo "Option C - Build for App Store:"
echo "  flutter build ipa"
echo "  • Upload via Xcode or App Store Connect"
echo ""
echo "🔧 Configure in Xcode:"
print_warning "IMPORTANT: Before deploying, open ios/Runner.xcworkspace and:"
echo "  • Set your Bundle Identifier (e.g., com.yourname.redsync)"
echo "  • Select your Apple Developer Team"
echo "  • Add capabilities: Push Notifications, Background App Refresh"
echo ""
echo "📱 Testing Notifications:"
echo "  1. Install app on iPhone"
echo "  2. Grant notification permissions"
echo "  3. Schedule a medication reminder"
echo "  4. Lock iPhone and wait for notification"
echo ""
print_success "Ready to deploy to iPhone! 🚀"
