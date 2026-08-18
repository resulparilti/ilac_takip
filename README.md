# İlaç Takip

Yaşlı kullanıcılar için ilaç ve su hatırlatma uygulaması (Flutter).

- **Ücretsiz:** İlaç takibi + AdMob
- **Premium:** 29 TL/ay — su, istatistik, acil bildirim, reklamsız

## Geliştirme

```powershell
$env:PATH = "C:\Users\User\flutter\bin;$env:PATH"
flutter pub get
flutter run
```

Hassas anahtarlar `.env` içindedir. Yayın öncesi:

1. Gerçek AdMob App/Unit ID’leri
2. Play Console’da abonelik: `premium_monthly_29tl` (veya `.env`’deki ID)
3. Gizlilik / kullanım koşulları URL’leri
4. Release imzalama (keystore) — şu an debug ile imzalı

Yapılacaklar: [yapilacaklar.md](yapilacaklar.md)
