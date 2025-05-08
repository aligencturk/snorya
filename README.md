# Snorya

Snorya, Wikipedia makalelerini Gemini AI ile özetleyip kullanıcılara sunan bir Flutter uygulamasıdır. TikTok tarzı dikey kaydırmalı bir arayüzle kullanıcılar farklı kategorilerdeki makaleleri keşfedebilir, favorilere ekleyebilir ve paylaşabilirler.

## Özellikler

- TikTok tarzı dikey kaydırma ile makale keşfi
- Wikipedia'dan rastgele makaleleri otomatik yükleme
- Gemini AI ile makaleleri özetleme
- Kategori bazlı içerik seçimi (Bilim, Tarih, Teknoloji, Kültür, Karışık)
- Favori makaleleri kaydetme ve yönetme
- Makaleleri paylaşma

## Kurulum

1. Projeyi klonlayın:
```
git clone https://github.com/kullaniciadi/snorya.git
```

2. Bağımlılıkları yükleyin:
```
flutter pub get
```

3. `lib/utils/constants.dart` dosyasında `geminiApiKey` değişkenini kendi Gemini API anahtarınızla değiştirin.

4. Uygulamayı çalıştırın:
```
flutter run
```

## Proje Yapısı

Proje MVVM (Model-View-ViewModel) mimarisi kullanılarak yapılandırılmıştır:

- **models/**: Veri modellerini içerir
- **viewmodels/**: İş mantığını ve durum yönetimini içerir
- **views/**: Kullanıcı arayüzü bileşenlerini içerir
  - **components/**: Yeniden kullanılabilir UI bileşenleri
  - **screens/**: Ekran bileşenleri
- **services/**: API ve depolama işlemlerini içerir
- **utils/**: Yardımcı fonksiyonlar ve sabitler

## Kullanılan Teknolojiler

- Flutter
- Provider (Durum yönetimi)
- HTTP (API istekleri)
- Gemini API (Makale özetleme)
- SharedPreferences (Yerel depolama)
- CachedNetworkImage (Görsel önbelleğe alma)

## Gelecek Geliştirmeler

- Kullanıcı hesapları ve bulut senkronizasyonu
- Makale geçmişi
- Daha gelişmiş kategori seçenekleri
- Karanlık mod
- Daha fazla özelleştirme seçeneği

## Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Daha fazla bilgi için [LICENSE](LICENSE) dosyasına bakın.
