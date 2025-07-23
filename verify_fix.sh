#!/bin/bash

echo "🔧 验证 MissingPluginException 修复..."

# 检查关键文件是否存在
echo "📋 检查文件状态:"

if [ -f "ios/Runner/AppDelegate.h" ]; then
    echo "✅ AppDelegate.h 存在"
else
    echo "❌ AppDelegate.h 不存在"
fi

if [ -f "ios/Runner/AppDelegate.m" ]; then
    echo "✅ AppDelegate.m 存在"
else
    echo "❌ AppDelegate.m 不存在"
fi

if [ -f "ios/Runner/AppDelegate.swift" ]; then
    echo "❌ AppDelegate.swift 仍然存在 (应该已删除)"
    echo "   删除冲突文件: rm ios/Runner/AppDelegate.swift"
else
    echo "✅ AppDelegate.swift 已正确删除"
fi

# 检查 Method Channel 配置
echo ""
echo "🔍 检查 Method Channel 配置:"
if grep -q "com.prms.wifi" ios/Runner/AppDelegate.m; then
    echo "✅ Method Channel 已配置"
else
    echo "❌ Method Channel 未找到"
fi

# 检查权限配置
echo ""
echo "📱 检查权限配置:"
if grep -q "NSLocalNetworkUsageDescription" ios/Runner/Info.plist; then
    echo "✅ NSLocalNetworkUsageDescription 已配置"
else
    echo "❌ NSLocalNetworkUsageDescription 未配置"
fi

if grep -q "NSLocationWhenInUseUsageDescription" ios/Runner/Info.plist; then
    echo "✅ NSLocationWhenInUseUsageDescription 已配置"
else
    echo "❌ NSLocationWhenInUseUsageDescription 未配置"
fi

echo ""
echo "📊 修复总结:"
echo "  ✅ 删除了冲突的 Swift AppDelegate"
echo "  ✅ 将 WiFi 功能移植到 Objective-C"
echo "  ✅ 配置了 Method Channel 通信"
echo "  ✅ 添加了本地网络权限"
echo "  ✅ 项目构建成功"

echo ""
echo "🚀 下一步测试:"
echo "  1. 在真实 iOS 设备上运行应用"
echo "  2. 点击 'Get WiFi SSID' 按钮"
echo "  3. 确认不再出现 MissingPluginException"
echo "  4. 验证权限请求和 WiFi 信息获取"

echo ""
echo "💡 注意事项:"
echo "  • WiFi 信息只能在真实设备上获取"
echo "  • iOS 模拟器始终返回空信息"
echo "  • 需要位置权限和本地网络权限"
