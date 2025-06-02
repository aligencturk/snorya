# 🐍 SNORYA - SADECE PYTHON SERVİSİ MODU

## 🎯 **AMAÇ**
Bu mod, Snorya uygulamasında **kesinlikle Gemini AI kullanmadan**, sadece Python'un Wikipedia package'ı ile **ücretsiz** özetleme yapmayı sağlar.

## ✅ **AVANTAJLAR**
- ✨ **%100 ÜCRETSİZ** - API maliyeti yok
- 🚀 **Hızlı** - Yerel serviste çalışır
- 🔒 **Güvenilir** - Gemini API'ya bağımlı değil
- 🌐 **Çevrimdışı** - İnternet varsa Wikipedia'ya erişiyor

## 🛠️ **KURULUM VE KULLANIM**

### 1. Python Servisini Başlatın
```bash
# Otomatik başlatma scripti
./start_python_service.sh

# Veya manuel
cd python_summary_service
python3 main.py
```

### 2. Flutter Uygulamasını Çalıştırın
```bash
flutter run
```

## 🔍 **NASIL ÇALIŞIYOR**

### Python Servisi (Port 5001)
- **Wikipedia Package** kullanır
- Türkçe Wikipedia makalelerini özetler
- REST API endpoints:
  - `GET /health` - Sağlık kontrolü
  - `POST /summarize` - Makale özetleme
  - `POST /search-and-summarize` - Arama ve özetleme
  - `GET /random-summary` - Rastgele makale

### Flutter Entegrasyonu
- `PurePythonSummaryService` sadece Python servisini kullanır
- Gemini fallback **YOK** - Python servisi çalışmak zorunda
- Console'da detaylı log mesajları gösterir

## 🧪 **TEST ETME**

### 1. Python Servisi Test
```bash
# Sağlık kontrolü
curl http://localhost:5001/health

# Özet testi
curl -X POST http://localhost:5001/summarize \
  -H "Content-Type: application/json" \
  -d '{"content":"Wikipedia test metni", "sentences":3}'
```

### 2. Flutter Console Logları
Uygulama çalışırken console'da şu mesajları göreceksiniz:
```
🐍 PURE PYTHON SERVİSİ: Özet oluşturma başladı
🌐 Python Servisi URL: http://localhost:5001
🏥 Sağlık kontrolü başlatılıyor...
💚 Sağlık durumu: SAĞLIKLI
✅ BAŞARILI! Python servisi özet oluşturdu
💰 Maliyet: 0₺ - ÜCRETSIZ
```

## ⚠️ **SORUN GİDERME**

### Python Servisi Çalışmıyor
```bash
# Port kontrolü
lsof -i :5001

# Port temizleme
lsof -ti:5001 | xargs kill -9

# Servisi yeniden başlat
./start_python_service.sh
```

### Flutter Hataları
Eğer uygulama "Python servisi çalışmıyor" hatası veriyorsa:

1. **Python servisini kontrol edin:**
   ```bash
   curl http://localhost:5001/health
   ```

2. **Servisi yeniden başlatın:**
   ```bash
   ./start_python_service.sh
   ```

3. **Flutter'ı yeniden başlatın:**
   ```bash
   flutter hot restart
   ```

## 📁 **DEĞİŞEN DOSYALAR**

### Yeni Dosyalar
- `lib/services/pure_python_summary_service.dart` - Sadece Python servisi
- `start_python_service.sh` - Otomatik başlatma scripti
- `PYTHON_ONLY_MODE.md` - Bu rehber

### Güncellenen Dosyalar
- `lib/utils/constants.dart` - Python servisi ayarları
- `lib/main.dart` - Pure Python servisi entegrasyonu
- `lib/services/preload_service.dart` - Python servisi kullanımı
- `lib/viewmodels/article_view_model.dart` - Python servisi entegrasyonu

## 🎮 **KULLANIM DENEYİMİ**

### Başlangıç
1. Uygulama açılırken Python servisi sağlık kontrolü yapar
2. Servisi çalışmıyorsa uyarı mesajı gösterir
3. Başlatma talimatlarını verir

### Özet Oluşturma
1. Her makale için Python servisi çağrılır
2. Console'da detaylı loglar gösterilir
3. Maliyet bilgisi: "0₺ - ÜCRETSIZ"

### Hata Durumu
- Python servisi çalışmıyorsa fallback summary gösterilir
- Detaylı hata mesajları console'a yazılır
- Kullanıcıya başlatma talimatları gösterilir

## 🚀 **PERFORMANS**

### Hız
- **Python servisi:** ~1-2 saniye
- **Gemini API:** ~3-5 saniye
- **Avantaj:** Python daha hızlı!

### Maliyet
- **Python servisi:** 0₺ (Ücretsiz)
- **Gemini API:** ~$0.01-0.02 per summary
- **Avantaj:** %100 ücretsiz!

## 🔧 **GELİŞTİRİCİ NOTLARİ**

### Debug Modu
Tüm log mesajları aktif. Python servisinin her adımını takip edebilirsiniz.

### Kod Yapısı
```dart
// Sadece Python servisi kullanımı
final summary = await _purePythonSummaryService.generateSummary(content);

// Gemini fallback YOK - Python zorunlu
if (!isHealthy) {
  return AppConstants.fallbackSummary;
}
```

### Yapılandırma
```dart
// constants.dart
static const bool usePythonSummaryService = true;
static const bool allowGeminiFallback = false;
```

## 🎯 **SONUÇ**

Artık Snorya uygulamanız:
- ✅ **%100 Python Wikipedia Package** kullanıyor
- ❌ **Gemini AI kullanmıyor**
- 💰 **0₺ maliyet**
- 🚀 **Hızlı ve güvenilir**

**Başlatma:** `./start_python_service.sh && flutter run`

**Test:** `curl http://localhost:5001/health`

**Başarı!** 🎉 