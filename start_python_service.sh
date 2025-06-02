#!/bin/bash

echo "🐍 PYTHON SERVİSİ BAŞLATILIYOR"
echo "==============================="

# Port kontrolü
if lsof -Pi :5001 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  Port 5001 zaten kullanımda!"
    echo "🔍 Port 5001'i kim kullanıyor:"
    lsof -i :5001
    echo ""
    echo "❓ Bu servisi sonlandırmak istiyor musunuz? (y/n)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "🛑 Port 5001'deki servis sonlandırılıyor..."
        lsof -ti:5001 | xargs kill -9
        echo "✅ Servis sonlandırıldı!"
    else
        echo "❌ Port 5001 kullanımda olduğu için Python servisi başlatılamıyor."
        exit 1
    fi
fi

# Python servisi klasörüne git
cd python_summary_service

# Python ve gerekli paketleri kontrol et
echo "🔍 Python kontrol ediliyor..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 bulunamadı! Lütfen Python3'ü yükleyin."
    exit 1
fi

echo "📦 Gerekli paketler kontrol ediliyor..."
if ! python3 -c "import flask, flask_cors, wikipedia, requests" 2>/dev/null; then
    echo "⚠️  Gerekli paketler eksik! Yükleniyor..."
    pip3 install -r requirements.txt
fi

echo "🚀 Python servisi başlatılıyor..."
echo "📍 URL: http://localhost:5001"
echo "🔄 Servis çalışır durumda kalacak..."
echo ""
echo "🛑 Durdurmak için Ctrl+C tuşlayın"
echo ""

# Python servisini başlat
python3 main.py 