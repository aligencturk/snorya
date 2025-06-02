# 🍎 App Store Yükleme Checklist

## ✅ **Teknik Hazırlık**

### 1. Bundle ID Değiştir (ÖNEMLİ!)
- [ ] Bundle ID'yi benzersiz yap: `com.example.snorya` → `com.yourname.snorya`
- [ ] Xcode'da Runner > Signing & Capabilities > Bundle Identifier'ı değiştir

### 2. Python Servisi Seçimi (Birini Seç)
#### Seçenek A: Sadece Gemini (Kolay)
- [x] `constants.dart`'ta `usePythonSummaryService = false` yap
- [ ] Gemini API key'ini .env'e ekle

#### Seçenek B: Python Servisi Deploy Et (Ücretsiz)
- [ ] Python servisini Vercel'e deploy et:
  ```bash
  cd python_summary_service
  npm i -g vercel
  vercel
  ```
- [ ] Deploy edilen URL'i `constants.dart`'ta güncelle

### 3. Versiyonlama
- [ ] `pubspec.yaml`'da version'ı arttır: `1.0.3+6` → `1.0.4+7`

### 4. Icon ve Metadata
- [ ] App icon'ları ekle (1024x1024, 180x180, vs.)
- [ ] Launch screen'i güncelle
- [ ] App Store açıklaması hazırla

## 📱 **Build ve Test**

### 5. Build Test
- [ ] Scripti çalıştır: `chmod +x build_appstore.sh && ./build_appstore.sh`
- [ ] Hata çıkarsa düzelt

### 6. Simulator Test
- [ ] iOS Simulator'da test et
- [ ] Özet fonksiyonunu test et
- [ ] İnternet bağlantısız test et

## 🔐 **Apple Developer Hesabı**

### 7. Apple Developer Setup
- [ ] Apple Developer Program'a üye ol ($99/yıl)
- [ ] Certificates oluştur
- [ ] Provisioning Profile oluştur

### 8. App Store Connect
- [ ] App Store Connect'te yeni app oluştur
- [ ] Metadata'ları doldur:
  - [ ] App adı
  - [ ] Açıklama
  - [ ] Anahtar kelimeler
  - [ ] Kategori
  - [ ] Screenshots
  - [ ] Privacy Policy

## 📤 **Upload**

### 9. Xcode'da Archive
```bash
# Bu scripti çalıştırdıktan sonra:
open ios/Runner.xcworkspace
```
- [ ] Xcode'da açılan proje'yi Archive yap
- [ ] Validate yap
- [ ] Upload to App Store yap

### 10. App Store Review
- [ ] App Store Connect'te Review'a gönder
- [ ] Review notları ekle (hibrit sistem hakkında)
- [ ] Test hesabı bilgileri ekle (gerekirse)

## ⚠️ **Önemli Notlar**

### Review İçin Hazırlık
```
Review Notes:
Bu uygulama Wikipedia makalelerini özetlemek için hibrit bir sistem kullanır:
1. Python mikro servisi (ücretsiz)
2. Gemini AI (fallback)

Eğer Python servisi çalışmazsa otomatik olarak Gemini'ye geçer.
```

### Potansiyel Sorunlar
- **Çevrimdışı çalışma:** App Store, çevrimdışı çalışmayan uygulamaları reddedebilir
  - **Çözüm:** Hibrit sistem sayesinde cache'lenmiş içerik göster
- **API dependency:** Apple, external API'lara bağımlı uygulamaları sorgulatabilir
  - **Çözüm:** Fallback sistemi mevcut

### Son Kontroller
- [ ] Privacy Policy hazırla (gerekli)
- [ ] Terms of Service hazırla (gerekli)
- [ ] App içi satın alma varsa ekle
- [ ] Rating prompt'u ekle

## 🚀 **Deploy Komutları**

### Hızlı Deploy (Sadece Gemini):
```bash
# 1. Constants'ı güncelle
sed -i '' 's/usePythonSummaryService = true/usePythonSummaryService = false/' lib/utils/constants.dart

# 2. Build yap
./build_appstore.sh

# 3. Xcode'da aç
open ios/Runner.xcworkspace
```

### Python Servisi ile Deploy:
```bash
# 1. Python servisini deploy et
cd python_summary_service
vercel

# 2. URL'i güncelle
echo "Deploy edilen URL'i constants.dart'ta güncelle"

# 3. Build yap
cd ..
./build_appstore.sh
```

## 📞 **Destek**

Sorun yaşarsan:
1. Build loglarını kontrol et
2. Apple Developer Forums'u kontrol et
3. Flutter Doctor çalıştır: `flutter doctor` 