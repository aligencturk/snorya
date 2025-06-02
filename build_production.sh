#!/bin/bash

echo "🏭 PRODUCTION BUILD BAŞLADI"
echo "============================"

# Mode seçimi
echo "📋 Hangi modu kullanmak istiyorsunuz?"
echo "1. Cloud Python Servisi (Önerilen - Ücretsiz)"
echo "2. Sadece Gemini AI (Ücretli ama kolay)"
echo ""
read -p "Seçiminizi yapın (1-2): " choice

case $choice in
    1)
        echo "🌍 Cloud Python Servisi modu seçildi"
        
        # Python servisini deploy et
        echo "🚀 Python servisi deploy ediliyor..."
        ./deploy_python_service.sh
        
        echo ""
        echo "⚠️  Deploy edilen URL'i .env dosyasına eklemeyi unutmayın!"
        echo ""
        ;;
    2)
        echo "🤖 Gemini AI modu seçildi"
        
        # Constants'ı Gemini için güncelle
        sed -i '' 's/static const bool usePythonSummaryService = true/static const bool usePythonSummaryService = false/' lib/utils/constants.dart
        sed -i '' 's/static const bool allowGeminiFallback = false/static const bool allowGeminiFallback = true/' lib/utils/constants.dart
        
        echo "✅ Gemini AI modu etkinleştirildi"
        echo "⚠️  .env dosyasında GEMINI_API_KEY'inizi kontrol edin!"
        ;;
    *)
        echo "❌ Geçersiz seçim!"
        exit 1
        ;;
esac

echo ""
echo "🧹 Önceki build'leri temizliyorum..."
flutter clean
rm -rf ios/Pods
rm -rf ios/Podfile.lock

echo "📦 Bağımlılıkları güncelliyorum..."
flutter pub get
cd ios && pod install && cd ..

echo "🧪 Test çalıştırılıyor..."
flutter test

echo "🔨 Production build başlıyor..."
flutter build ios --release

echo ""
echo "✅ PRODUCTION BUILD TAMAMLANDI!"
echo ""
echo "📱 APP STORE YÜKLEMESİ:"
echo "1. Xcode'da ios/Runner.xcworkspace dosyasını açın"
echo "2. Archive yapın"
echo "3. App Store Connect'e yükleyin"
echo ""
echo "🎯 SONUÇ:"
if [ "$choice" == "1" ]; then
    echo "✅ %100 Ücretsiz Python servisi kullanılıyor"
    echo "💰 API maliyeti: 0₺"
else
    echo "🤖 Gemini AI kullanılıyor"
    echo "💰 API maliyeti: ~$0.01-0.02 per özet"
fi 