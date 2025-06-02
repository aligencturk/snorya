# Snorya

Snorya, Wikipedia makalelerini AI ile özetleyip kullanıcılara sunan bir Flutter uygulamasıdır. TikTok tarzı dikey kaydırmalı bir arayüzle kullanıcılar farklı kategorilerdeki makaleleri keşfedebilir, favorilere ekleyebilir ve paylaşabilirler.

## 🆕 Yeni Özellik: Python Wikipedia Özet Servisi

Artık Gemini AI yerine **Python Wikipedia paketi** kullanarak makaleleri özetleyebilirsiniz! Bu sayede:

- ✅ **API maliyeti yok** - Gemini API anahtarına gerek yok
- ✅ **Hızlı yanıt süresi** - Yerel işlem
- ✅ **Offline çalışabilir** - İnternet bağlantısı sadece Wikipedia için gerekli
- ✅ **Hibrit sistem** - Python servisi çalışmazsa otomatik olarak Gemini'ye geçer

## Özellikler

- TikTok tarzı dikey kaydırma ile makale keşfi
- Wikipedia'dan rastgele makaleleri otomatik yükleme
- **İki farklı özet servisi:**
  - **Python Wikipedia Servisi** (Varsayılan, ücretsiz)
  - **Gemini AI** (Fallback, API anahtarı gerekli)
- Kategori bazlı içerik seçimi (Bilim, Tarih, Teknoloji, Kültür, Karışık)
- Favori makaleleri kaydetme ve yönetme
- Makaleleri paylaşma

## Kurulum

### 1. Flutter Uygulaması

1. Projeyi klonlayın:
```bash
git clone https://github.com/kullaniciadi/snorya.git
cd snorya
```

2. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

3. `.env` dosyası oluşturun (opsiyonel):
```bash
# Sadece Gemini kullanmak istiyorsanız
GEMINI_API_KEY=your_gemini_api_key_here

# Python servisi farklı portta çalışıyorsa
PYTHON_SUMMARY_SERVICE_URL=http://localhost:5001
```

### 2. Python Özet Servisi (Önerilen)

1. Python servis dizinine gidin:
```bash
cd python_summary_service
```

2. Bağımlılıkları yükleyin:
```bash
pip3 install -r requirements.txt
```

3. Servisi başlatın:
```bash
python3 main.py
```

Veya otomatik kurulum scripti ile:
```bash
./run.sh
```

Servis `http://localhost:5001` adresinde çalışacaktır.

### 3. Flutter Uygulamasını Çalıştırın

```bash
flutter run
```

## Özet Servisi Seçimi

`lib/utils/constants.dart` dosyasında `usePythonSummaryService` değişkenini değiştirerek özet servisini seçebilirsiniz:

```dart
// Python servisi kullan (varsayılan)
static const bool usePythonSummaryService = true;

// Sadece Gemini kullan
static const bool usePythonSummaryService = false;
```

## Python Servisi API Endpoints

### GET /health
Servis sağlık kontrolü

### POST /summarize
Makale içeriğini özetler
```json
{
    "content": "makale içeriği",
    "sentences": 4
}
```

### POST /search-and-summarize
Wikipedia'da arama yapar ve özetler
```json
{
    "query": "arama terimi",
    "sentences": 4
}
```

### GET /random-summary
Rastgele Wikipedia makalesini özetler

## Proje Yapısı

Proje MVVM (Model-View-ViewModel) mimarisi kullanılarak yapılandırılmıştır:

- **models/**: Veri modellerini içerir
- **viewmodels/**: İş mantığını ve durum yönetimini içerir
- **views/**: Kullanıcı arayüzü bileşenlerini içerir
  - **components/**: Yeniden kullanılabilir UI bileşenleri
  - **screens/**: Ekran bileşenleri
- **services/**: API ve depolama işlemlerini içerir
  - **hybrid_summary_service.dart**: Python ve Gemini arasında geçiş yapan hibrit servis
  - **python_summary_service.dart**: Python Wikipedia servisi
  - **gemini_service.dart**: Gemini AI servisi
- **utils/**: Yardımcı fonksiyonlar ve sabitler
- **python_summary_service/**: Python mikro servisi

## Kullanılan Teknolojiler

### Flutter Uygulaması
- Flutter
- Provider (Durum yönetimi)
- HTTP (API istekleri)
- SharedPreferences (Yerel depolama)
- CachedNetworkImage (Görsel önbelleğe alma)

### Python Servisi
- Flask (Web framework)
- Wikipedia (Python paketi)
- Flask-CORS (CORS desteği)

## Avantajlar

### Python Servisi
- ✅ Ücretsiz (API maliyeti yok)
- ✅ Hızlı yanıt süresi
- ✅ Basit kurulum
- ✅ Türkçe dil desteği

### Gemini AI (Fallback)
- ✅ Daha gelişmiş özetleme
- ✅ Doğal dil işleme
- ✅ Bağlamsal anlama

## Gelecek Geliştirmeler

- Kullanıcı hesapları ve bulut senkronizasyonu
- Makale geçmişi
- Daha gelişmiş kategori seçenekleri
- Karanlık mod
- Daha fazla özelleştirme seçeneği
- Python servisinde daha gelişmiş özetleme algoritmaları

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Daha fazla bilgi için [LICENSE](LICENSE) dosyasına bakın.
