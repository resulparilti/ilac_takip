/// Ortam değişkenleri — hassas anahtarlar `.env` üzerinden okunur.
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  EnvConfig._();

  static String get admobAppIdAndroid =>
      dotenv.env['ADMOB_APP_ID_ANDROID'] ?? '';

  static String get admobAppIdIos => dotenv.env['ADMOB_APP_ID_IOS'] ?? '';

  static String get admobBannerIdAndroid =>
      dotenv.env['ADMOB_BANNER_ID_ANDROID'] ?? '';

  static String get admobBannerIdIos =>
      dotenv.env['ADMOB_BANNER_ID_IOS'] ?? '';

  static String get admobInterstitialIdAndroid =>
      dotenv.env['ADMOB_INTERSTITIAL_ID_ANDROID'] ?? '';

  static String get admobInterstitialIdIos =>
      dotenv.env['ADMOB_INTERSTITIAL_ID_IOS'] ?? '';

  static String get premiumSubscriptionId =>
      dotenv.env['PREMIUM_SUBSCRIPTION_ID'] ?? 'premium_monthly_29tl';

  static int get premiumPriceTry =>
      int.tryParse(dotenv.env['PREMIUM_PRICE_TRY'] ?? '29') ?? 29;

  static String get privacyPolicyUrl =>
      dotenv.env['PRIVACY_POLICY_URL'] ?? '';

  static String get termsOfUseUrl => dotenv.env['TERMS_OF_USE_URL'] ?? '';
}
