# İlaç & Su Takip Uygulaması — Yapılacaklar Listesi

> **Kural:** Her geliştirme adımı sonrası bu dosya kontrol edilir; tamamlanan maddeler `[x]` ile işaretlenir.
> **Kaynak:** `.cursor/rules/projec-kurali.mdc` + ürün gereksinimleri.
> **Hedef kitle:** Yaşlı kullanıcılar (büyük yazı, yüksek kontrast, basit etkileşim).
> **Monetizasyon:** Free (AdMob) / Premium (aylık **29 TL**, reklamsız).

---

## Ücretsiz (Free) vs Premium Özeti

| Özellik | Free | Premium (29 TL/ay) |
|---|---|---|
| İlaç ekleme, fotoğraf, yönerge, esnek zamanlama | ✅ | ✅ |
| İlaç hatırlatma (tam ekran + sabit bildirim) | ✅ | ✅ |
| Stok / yenileme hatırlatması | ✅ | ✅ |
| Temel bildirim + zil sesi (ilaç) | ✅ | ✅ |
| Tema / yazı / buton boyutu kişiselleştirme | ✅ | ✅ |
| AdMob (banner + interstitial) | ✅ | ❌ |
| Su içme takibi, hedef, uyarı sıklığı | ❌ Paywall | ✅ |
| Su zil sesi + görsel ilerleme + manuel ekleme | ❌ Paywall | ✅ |
| Gelişmiş istatistikler | ❌ Paywall | ✅ |
| Sorumlu kişi + peş peşe kaçırmada WhatsApp/SMS/e-posta | ❌ Paywall | ✅ |

---

## 5️⃣ Geliştirme Adımları

* [x] **Adım 1: Proje Kurulumu, Mimari ve Güvenlik (.env)**
  * [x] Flutter projesinin oluşturulması (`ilac_takip`).
  * [x] Durum yönetimi: Riverpod kurulumu.
  * [x] Klasör mimarisi: `core/`, `features/`, `shared/`, `services/`.
  * [x] `flutter_dotenv` ile AdMob ID, abonelik ve hassas anahtarların `.env` üzerinden okunması (koda gömülmeyecek).
  * [x] Yaşlı kullanıcı odaklı tema temeli (Atkinson Hyperlegible, yüksek kontrast, min 48px dokunma alanı).

* [x] **Adım 2: Veritabanı (SQLite) Kurulumu**
  * [x] Tablolar: `medicines`, `schedules`, `dose_logs`, `renewals`, `water_goals`, `water_logs`, `water_reminders`, `emergency_contacts`, `settings`, `subscription`.
  * [x] Esnek zamanlama alanları: günlük / saatlik / tekrarlı (interval), özel saat listesi.
  * [x] Kaçırılan doz / su kayıtları ve “tamamlandı” durumu.
  * [x] Yerel ayarlar: tema renkleri, yazı boyutu, buton boyutu, ilaç/su zil sesi.

* [x] **Adım 3: İzinler, UMP, Onboarding ve Freemium Logic (Google Play)**
  * [x] Onboarding + `PermissionExplanationCard` (Prominent Disclosure) → ardından sistem izinleri.
  * [x] İzinler: Bildirim, Exact Alarm / SCHEDULE_EXACT_ALARM (minimum).
  * [x] UMP Consent Form → onay sonrası `google_mobile_ads` başlatma.
  * [x] Free/Premium bayrağı + Paywall iskeleti (aylık 29 TL).
  * [x] Free: Banner (alt) + Interstitial (test). Premium: reklamlar kapalı.

* [x] **Adım 4: Temel İlaç Yönetimi UI**
  * [x] **Dashboard:** `DateSelectorBar`, `MedicineCard`, FAB, Free’de `AdMobBanner`.
  * [x] **İlaç Ekle / Düzenle:** `PhotoPickerWidget`, yönerge metni, `TimePickerList`, `ConditionDropdown` (aç/tok vb.), esnek tekrar (günlük/saatlik/tekrarlı).
  * [x] **Stok / Yenileme:** `StatusCard` (Kırmızı/Acil, Sarı/Uyarı, Yeşil/Yeterli) + yenileme hatırlatması.

* [x] **Adım 5: Premium Özelliklerin UI**
  * [x] Paywall ekranı (29 TL/ay, özellik listesi, satın al / geri yükle).
  * [x] **Su İçme:** hedef (ml), günde kaç uyarı, `WaterProgressBar`, `QuickAddButton`, `UpcomingRemindersList`.
  * [x] **İstatistik:** `ComplianceChart`, `MissedHistoryList` (ilaç).
  * [x] **Ayarlar:** `ThemeSelector`, `SizeSlider`, ilaç & su zil sesi seçici.
  * [x] **Acil iletişim (Premium):** `EmergencyContactSection`.

* [x] **Adım 6: Yasal Metinler ve Veri Silme (Play zorunlu)**
  * [x] `LegalAndSecuritySection`: Gizlilik Politikası + Kullanım Koşulları (`url_launcher`).
  * [x] “Tüm Verilerimi Sil” → çift onay popup → SQLite + yerel ayarların temizlenmesi.

* [x] **Adım 7: Bildirim ve Tam Ekran Alarm Motoru (Core)**
  * [x] `flutter_local_notifications` + exact alarm; `AndroidManifest` izinleri.
  * [x] Tam ekran alarm UI + yalnızca swipe ile “Tamamladım”.
  * [x] Kaçırılan hatırlatmalar ongoing bildirimde kalır (1 saat sonra).
  * [x] İlaç ve su için ayrı bildirim kanalları / zil anahtarları.
  * [x] Yenileme (stok) hatırlatma bildirimleri.

* [x] **Adım 8: Acil Bildirim Arka Plan Servisi (Premium)**
  * [x] Peş peşe N kez ilaç kaçırılınca sorumlu kişiye WhatsApp / SMS / e-posta intent.
  * [x] Açılış/ön plana dönüş taraması + 6 saat rate limit; Free’de çalışmaz.

* [x] **Adım 9: Abonelik (In-App Purchase) — 29 TL/ay**
  * [x] Google Play Billing (`in_app_purchase`) entegrasyonu.
  * [x] Satın alma, geri yükleme, abonelik durumu senkronu.
  * [x] Premium aktifken AdMob kapanır; su hatırlatmaları açılır.

* [x] **Adım 10: Release Öncesi Güvenlik ve Yayın**
  * [x] R8/ProGuard: `minifyEnabled` + `shrinkResources` + `proguard-rules.pro`.
  * [x] İzinler minimumda; disclosure / UMP / veri silme mevcut.
  * [x] README’de store checklist (AdMob, abonelik ID, gizlilik URL, keystore).
  * [ ] Cihazda smoke test (Android SDK kurulunca).

---

## Notlar (Uygulama Sırasında)

1. Tam ekran alarm + swipe-to-complete ve ongoing bildirimler yaşlı kullanıcı deneyiminin kalbidir; erken prototiplenmeli.
2. WhatsApp otomasyonu cihaz/OS kısıtlarına takılabilir; SMS / e-posta / FCM yedek kanal olarak planlanmalı.
3. Tasarım `tasarim_sablon.html`’den esinlenir; okunabilirlik ve erişilebilirlik önceliklidir (Mor/krem varsayılan AI kalıplarından kaçınılır).
4. Bu liste her tamamlanan işte güncellenir (`[ ]` → `[x]`).
