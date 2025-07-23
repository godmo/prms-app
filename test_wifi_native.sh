#!/bin/bash

echo "🚀 Building iOS app with native WiFi SSID support..."

# 检查是否在iOS目录中
if [ ! -d "ios" ]; then
    echo "❌ Error: Please run this script from the root of your Flutter project"
    exit 1
fi

echo "📱 Building for iOS simulator..."
flutter build ios --debug --simulator

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo ""
    echo "📋 Implementation Summary:"
    echo "  ✓ Modified AppDelegate.swift to handle WiFi SSID requests"
    echo "  ✓ Created WifiService.dart for native method channel communication"
    echo "  ✓ Updated binding_prms_card.dart to use native WiFi service"
    echo "  ✓ Simplified permission handling (now handled natively)"
    echo ""
    echo "🔧 Key Features:"
    echo "  - Uses iOS SystemConfiguration.CaptiveNetwork API"
    echo "  - Handles location permission requests automatically"
    echo "  - Better error handling with specific error codes"
    echo "  - Maintains IP address retrieval as fallback"
    echo ""
    echo "📝 Testing Instructions:"
    echo "  1. Run the app on a physical iOS device (WiFi info unavailable on simulator)"
    echo "  2. Tap 'Get WiFi SSID' button"
    echo "  3. Grant location permission when prompted"
    echo "  4. Verify WiFi SSID and BSSID are displayed correctly"
else
    echo "❌ Build failed! Please check the error messages above."
    exit 1
fi
