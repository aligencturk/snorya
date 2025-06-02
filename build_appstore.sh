#!/bin/bash

echo "🍎 APP STORE BUILD BAŞLADI"
echo "========================="

# 1. Temizlik
echo "🧹 Önceki build'leri temizliyorum..."
flutter clean
rm -rf ios/Pods
rm -rf ios/Podfile.lock

# 2. Bağımlılıkları güncelle
echo "📦 Bağımlılıkları güncelliyorum..."
flutter pub get
cd ios && pod install && cd ..

# 3. Version kontrolü
echo "📱 Version kontrolü..."
grep "version:" pubspec.yaml

# 4. .env kontrolü
if [ ! -f ".env" ]; then
    echo "⚠️  .env dosyası bulunamadı! Oluşturuluyor..."
    echo "GEMINI_API_KEY=your_api_key_here" > .env
    echo "PYTHON_SUMMARY_SERVICE_URL=https://your-app.vercel.app" >> .env
fi

# 5. Test
echo "🧪 Test çalıştırılıyor..."
flutter test

# 6. iOS Build
echo "🔨 iOS Build başlıyor..."
flutter build ios --release

echo ""
echo "✅ BUILD TAMAMLANDI!"
echo "📁 Build dosyası: build/ios/iphoneos/Runner.app"
echo ""
echo "📋 SONRAKI ADIMLAR:"
echo "1. Xcode'da ios/Runner.xcworkspace dosyasını aç"
echo "2. Apple Developer hesabınızla sign edin"
echo "3. Archive yapın"
echo "4. App Store Connect'e yükleyin"
echo ""
echo "⚠️  UNUTMAYIN:"
echo "• Bundle ID'yi benzersiz yapın"
echo "• Provisioning Profile ayarlayın"
echo "• App Store Connect'te app oluşturun" 