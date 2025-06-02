#!/bin/bash

echo "🚀 PYTHON SERVİSİNİ CLOUD'A DEPLOY EDİYOR"
echo "========================================="

# Python servisi klasörüne git
cd python_summary_service

# Vercel CLI kontrolü
if ! command -v vercel &> /dev/null; then
    echo "📦 Vercel CLI yükleniyor..."
    npm install -g vercel
fi

echo "🔗 Vercel'e login olun (gerekirse):"
vercel login

echo ""
echo "🚀 Python servisi deploy ediliyor..."
echo "⏳ Bu işlem 1-2 dakika sürebilir..."

# Deploy et
vercel --prod

echo ""
echo "✅ DEPLOY TAMAMLANDI!"
echo ""
echo "📋 SONRAKİ ADIMLAR:"
echo "1. Yukarıdaki URL'i kopyalayın"
echo "2. .env dosyasına ekleyin:"
echo "   PYTHON_SUMMARY_SERVICE_URL=https://your-deployed-url.vercel.app"
echo ""
echo "🧪 TEST ETMEK İÇİN:"
echo "   curl https://your-deployed-url.vercel.app/health"
echo ""
echo "📱 Artık uygulamanızı App Store'a yükleyebilirsiniz!" 