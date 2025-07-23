#!/bin/bash

echo "🔍 检查iOS权限配置..."

INFO_PLIST="/Users/user/Documents/GitHub/prms-app/ios/Runner/Info.plist"

if [ ! -f "$INFO_PLIST" ]; then
    echo "❌ Error: Info.plist 文件未找到"
    exit 1
fi

echo "📋 检查必要权限..."

# 检查位置权限
if grep -q "NSLocationWhenInUseUsageDescription" "$INFO_PLIST"; then
    echo "✅ NSLocationWhenInUseUsageDescription: 已配置"
else
    echo "❌ NSLocationWhenInUseUsageDescription: 未配置"
fi

if grep -q "NSLocationAlwaysAndWhenInUseUsageDescription" "$INFO_PLIST"; then
    echo "✅ NSLocationAlwaysAndWhenInUseUsageDescription: 已配置"
else
    echo "❌ NSLocationAlwaysAndWhenInUseUsageDescription: 未配置"
fi

# 检查本地网络权限
if grep -q "NSLocalNetworkUsageDescription" "$INFO_PLIST"; then
    echo "✅ NSLocalNetworkUsageDescription: 已配置"
else
    echo "❌ NSLocalNetworkUsageDescription: 未配置"
fi

# 检查相机权限
if grep -q "NSCameraUsageDescription" "$INFO_PLIST"; then
    echo "✅ NSCameraUsageDescription: 已配置"
else
    echo "❌ NSCameraUsageDescription: 未配置"
fi

echo ""
echo "📱 iOS版本兼容性注意事项:"
echo "  • iOS 13-: 只需要位置权限"
echo "  • iOS 14+: 需要位置权限 + 本地网络权限"
echo "  • 建议最低支持 iOS 12.0"

echo ""
echo "🚀 下一步操作:"
echo "  1. 确保所有权限都已正确配置"
echo "  2. 在真实设备上测试WiFi SSID功能"
echo "  3. 验证权限提示是否正常显示"
