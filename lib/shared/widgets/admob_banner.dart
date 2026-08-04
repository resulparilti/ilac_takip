import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilac_takip/core/providers/app_providers.dart';
import 'package:ilac_takip/core/theme/app_theme.dart';

/// Free sürümde alt banner. Premium’da hiç render edilmez.
class AdMobBanner extends ConsumerStatefulWidget {
  const AdMobBanner({super.key});

  @override
  ConsumerState<AdMobBanner> createState() => _AdMobBannerState();
}

class _AdMobBannerState extends ConsumerState<AdMobBanner> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final isPremium = ref.read(isPremiumProvider);
    final ads = ref.read(consentAdsServiceProvider);
    if (isPremium || !ads.isAdsReady) return;

    final banner = BannerAd(
      size: AdSize.banner,
      adUnitId: ads.bannerAdUnitId,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _loaded = false);
        },
      ),
      request: const AdRequest(),
    );
    await banner.load();
    if (!mounted) {
      banner.dispose();
      return;
    }
    setState(() => _banner = banner);
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium || !_loaded || _banner == null) {
      return const SizedBox.shrink();
    }

    return ColoredBox(
      color: AppColors.surfaceContainer,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: _banner!.size.width.toDouble(),
          height: _banner!.size.height.toDouble(),
          child: AdWidget(ad: _banner!),
        ),
      ),
    );
  }
}
