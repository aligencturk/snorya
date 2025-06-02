# Python Wikipedia Özet Servisi

Bu servis, Wikipedia makalelerini Python'un `wikipedia` paketi kullanarak özetler. Gemini AI yerine bu servisi kullanarak API maliyetlerinden tasarruf edebilirsiniz.

## Özellikler

- Wikipedia makalelerini otomatik özetleme
- Türkçe dil desteği
- REST API arayüzü
- CORS desteği
- Rastgele makale özetleme
- Arama ve özetleme

## Kurulum

### Yerel Kurulum

1. Python 3.11+ yükleyin
2. Bağımlılıkları yükleyin:
```bash
pip install -r requirements.txt
```

3. Servisi başlatın:
```bash
python main.py
```

Servis `http://localhost:5000` adresinde çalışacaktır.

### Docker ile Kurulum

1. Docker image'ını oluşturun:
```bash
docker build -t wikipedia-summary-service .
```

2. Container'ı çalıştırın:
```bash
docker run -p 5000:5000 wikipedia-summary-service
```

## API Endpoints

### GET /health
Servis sağlık kontrolü

**Yanıt:**
```json
{
    "status": "healthy",
    "message": "Python Wikipedia Özet Servisi çalışıyor"
}
```

### POST /summarize
Verilen içeriği özetler

**İstek:**
```json
{
    "content": "özetlenecek metin",
    "title": "makale başlığı (opsiyonel)",
    "sentences": 4
}
```

**Yanıt:**
```json
{
    "success": true,
    "summary": "özetlenmiş metin",
    "original_length": 1500,
    "summary_length": 200,
    "sentences_count": 4
}
```

### POST /search-and-summarize
Wikipedia'da arama yapar ve bulunan makaleyi özetler

**İstek:**
```json
{
    "query": "arama terimi",
    "sentences": 4
}
```

**Yanıt:**
```json
{
    "success": true,
    "title": "Makale Başlığı",
    "summary": "özetlenmiş metin",
    "url": "https://tr.wikipedia.org/wiki/...",
    "original_length": 2000,
    "summary_length": 250
}
```

### GET /random-summary
Rastgele bir Wikipedia makalesini özetler

**Yanıt:**
```json
{
    "success": true,
    "title": "Rastgele Makale",
    "summary": "özetlenmiş metin",
    "url": "https://tr.wikipedia.org/wiki/...",
    "content": "tam makale içeriği",
    "original_length": 1800,
    "summary_length": 220
}
```

## Flutter Entegrasyonu

Bu servisi Flutter uygulamanızla entegre etmek için:

1. `lib/services/` klasöründe yeni bir servis dosyası oluşturun
2. HTTP istekleri ile bu servisi çağırın
3. Mevcut Gemini servisini bu servisle değiştirin

## Avantajlar

- ✅ API maliyeti yok
- ✅ Hızlı yanıt süresi
- ✅ Offline çalışabilir
- ✅ Özelleştirilebilir özet uzunluğu
- ✅ Türkçe dil desteği

## Dezavantajlar

- ❌ Basit özetleme (AI kadar gelişmiş değil)
- ❌ Ek sunucu gereksinimi
- ❌ Sadece Wikipedia ile sınırlı 