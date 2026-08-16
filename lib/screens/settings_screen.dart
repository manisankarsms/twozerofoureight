import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/save_manager.dart';
import '../services/purchase_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onThemeChanged});

  final Future<void> Function() onThemeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static final _privacyPolicyUri = Uri.parse('https://twozero48.web.app/privacy.html');
  final _purchases = PurchaseService.instance;

  @override
  void initState() {
    super.initState();
    _purchases.addListener(_refresh);
    SaveManager.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    _purchases.removeListener(_refresh);
    SaveManager.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _buyRemoveAds() async {
    await _purchases.buyRemoveAds();
    _showMessage();
  }

  Future<void> _restorePurchases() async {
    await _purchases.restorePurchases();
    _showMessage();
  }

  Future<void> _openPrivacyPolicy() async {
    final opened = await launchUrl(
      _privacyPolicyUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the privacy policy.')),
      );
    }
  }

  void _showMessage() {
    final message = _purchases.message;
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final adsRemoved = _purchases.adsRemoved;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        title: Text('Settings', style: AppTheme.title.copyWith(fontSize: 28)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _SectionTitle('APPEARANCE'),
          _SettingsCard(
            child: SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text('Dark theme', style: _titleStyle),
              subtitle: Text(
                AppColors.isDark ? 'Use the light appearance' : 'Use the dark appearance',
                style: _subtitleStyle,
              ),
              value: AppColors.isDark,
              activeThumbColor: AppColors.accent,
              onChanged: (_) async {
                await widget.onThemeChanged();
                if (mounted) setState(() {});
              },
            ),
          ),
          const SizedBox(height: 28),
          _SectionTitle('PURCHASES'),
          _SettingsCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: Icon(
                    adsRemoved ? Icons.verified_rounded : Icons.block_rounded,
                    color: AppColors.accent,
                  ),
                  title: Text(
                    adsRemoved ? 'Ads removed' : 'Remove Ads',
                    style: _titleStyle,
                  ),
                  subtitle: Text(
                    adsRemoved
                        ? 'Thank you for supporting 2048.'
                        : 'A one-time purchase for uninterrupted play.',
                    style: _subtitleStyle,
                  ),
                  trailing: adsRemoved
                      ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                      : _purchases.isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : FilledButton(
                              onPressed: _purchases.removeAdsProduct == null
                                  ? null
                                  : _buyRemoveAds,
                              child: Text(_purchases.removeAdsProduct?.price ?? 'Buy'),
                            ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  enabled: !_purchases.isBusy,
                  leading: const Icon(Icons.restore_rounded),
                  title: Text('Restore Purchases', style: _titleStyle),
                  subtitle: Text('Restore a previous Remove Ads purchase.', style: _subtitleStyle),
                  onTap: _restorePurchases,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _SectionTitle('ABOUT'),
          _SettingsCard(
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text('2048', style: _titleStyle),
                  subtitle: Text('Version 1.0.0 (1)', style: _subtitleStyle),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text('Privacy policy', style: _titleStyle),
                  subtitle: Text(
                    'View our privacy policy online.',
                    style: _subtitleStyle,
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded),
                  onTap: _openPrivacyPolicy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _titleStyle => TextStyle(
        color: AppColors.textDark,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      );

  TextStyle get _subtitleStyle => TextStyle(
        color: AppColors.textDark.withValues(alpha: .7),
        fontSize: 13,
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textDark.withValues(alpha: .62),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(16));
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? .12 : .06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.isDark ? const Color(0xFF2D2D44) : Colors.white,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
