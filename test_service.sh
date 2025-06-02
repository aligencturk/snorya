#!/bin/bash

echo "🧪 SERVİS TESTI BAŞLADI"
echo "========================"

echo ""
echo "1️⃣ Python Servisi Kontrolü:"
if curl -s http://localhost:5001/health > /dev/null; then
    echo "✅ Python servisi ÇALIŞIYOR (API kullanılmıyor)"
    
    echo ""
    echo "2️⃣ Test özet oluşturma:"
    RESPONSE=$(curl -s -X POST http://localhost:5001/summarize \
        -H "Content-Type: application/json" \
        -d '{"content": "Bu bir test metnidir.", "sentences": 1}')
    
    echo "📄 Yanıt: $RESPONSE"
    
    if echo "$RESPONSE" | grep -q "Python Wikipedia Package"; then
        echo "🎉 BAŞARILI: Python paketi kullanılıyor - API maliyeti YOK!"
    else
        echo "⚠️ Bilinmeyen durum"
    fi
    
else
    echo "❌ Python servisi çalışmıyor (Gemini API kullanılacak)"
fi

echo ""
echo "3️⃣ Maliyet Durumu:"
echo "   Python Servisi: 0₺ (ÜCRETSIZ)"
echo "   Gemini API:     ~0.01₺-0.05₺ per request"

echo ""
echo "🔍 Nasıl Anlarsın:"
echo "   • Python çalışıyorsa: Yanıtta 'Python Wikipedia Package' görürsün"
echo "   • Gemini kullanılıyorsa: Console'da '🔄 Gemini kullanıldı' mesajını görürsün" 