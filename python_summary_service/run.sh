#!/bin/bash

echo "🐍 Python Wikipedia Özet Servisi Başlatılıyor..."

# Python 3 kontrolü
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 bulunamadı. Lütfen Python 3.11+ kurun."
    exit 1
fi

# Virtual environment oluştur
if [ ! -d "venv" ]; then
    echo "📦 Virtual environment oluşturuluyor..."
    python3 -m venv venv
fi

# Virtual environment aktif et
echo "🔧 Virtual environment aktif ediliyor..."
source venv/bin/activate

# Bağımlılıkları yükle
echo "📚 Bağımlılıklar yükleniyor..."
pip install -r requirements.txt

# Servisi başlat
echo "🚀 Servis başlatılıyor..."
echo "📍 URL: http://localhost:5000"
echo "🔍 Health Check: http://localhost:5000/health"
echo "⏹️  Durdurmak için: Ctrl+C"
echo ""

python main.py 