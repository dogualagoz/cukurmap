import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/prefs_keys.dart';
import '../../core/strings.dart';
import '../../core/theme.dart';
import '../auth/auth_provider.dart';
import '../users/data/users_api.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _geofenceEnabled = false;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadGeofencePref();
    _loadAppVersion();
  }

  Future<void> _loadGeofencePref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _geofenceEnabled = prefs.getBool(PrefsKeys.geofenceNotificationsEnabled) ?? false;
    });
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = '${info.version}+${info.buildNumber}');
  }

  Future<void> _toggleGeofence(bool value) async {
    setState(() => _geofenceEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.geofenceNotificationsEnabled, value);
  }

  Future<void> _editNickname() async {
    final current = ref.read(authProvider).valueOrNull?.nickname ?? '';
    final controller = TextEditingController(text: current);
    final newNickname = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(Strings.settingsNicknameDialogTitle),
        content: TextField(
          controller: controller,
          maxLength: 40,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(Strings.dialogOk),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text(Strings.settingsNicknameEdit),
          ),
        ],
      ),
    );
    if (newNickname == null || newNickname.isEmpty || newNickname == current) return;
    try {
      await ref.read(usersApiProvider).updateNickname(newNickname);
      await ref.read(authProvider.notifier).updateNickname(newNickname);
      ref.invalidate(userProfileProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.settingsNicknameError)),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(Strings.settingsDeleteAccountDialogTitle),
        content: const Text(Strings.settingsDeleteAccountDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(Strings.settingsDeleteAccountCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(Strings.settingsDeleteAccountConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(usersApiProvider).deleteAccount();
      await ref.read(authProvider.notifier).resetForAccountDeletion();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      context.go('/onboarding');
      ref.invalidate(authProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(Strings.settingsDeleteAccountError)),
      );
    }
  }

  Future<void> _openPage(String path) {
    final origin = ref.read(apiOriginProvider);
    return launchUrl(
      Uri.parse('$origin$path'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _openSupportMail() {
    return launchUrl(Uri(scheme: 'mailto', path: Strings.supportEmail));
  }

  @override
  Widget build(BuildContext context) {
    final nickname = ref.watch(authProvider).valueOrNull?.nickname ?? '';
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text(Strings.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _sectionLabel(Strings.settingsNotificationsTitle),
          const SizedBox(height: 10),
          _card(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _geofenceEnabled,
              onChanged: _toggleGeofence,
              activeThumbColor: AppTheme.accent,
              title: const Text(Strings.settingsGeofenceToggleTitle, style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                Strings.settingsGeofenceToggleBody,
                style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryLight),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel(Strings.settingsAccountTitle),
          const SizedBox(height: 10),
          _card(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(Strings.settingsNicknameLabel, style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('@$nickname', style: TextStyle(color: AppTheme.textSecondaryLight)),
              trailing: TextButton(
                onPressed: _editNickname,
                child: const Text(Strings.settingsNicknameEdit),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                Strings.settingsDeleteAccountTitle,
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade700),
              ),
              subtitle: Text(
                Strings.settingsDeleteAccountSubtitle,
                style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryLight),
              ),
              trailing: Icon(Icons.delete_forever_outlined, color: Colors.red.shade700),
              onTap: _deleteAccount,
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel(Strings.settingsAboutTitle),
          const SizedBox(height: 10),
          _card(
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(Strings.settingsVersion, style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text(_appVersion ?? '—', style: TextStyle(color: AppTheme.textSecondaryLight)),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(Strings.settingsPrivacyPolicyTitle, style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openPage('/privacy.html'),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(Strings.settingsTermsTitle, style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openPage('/terms.html'),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(Strings.settingsSupportTitle, style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(Strings.supportEmail, style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryLight)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openSupportMail,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: AppTheme.mono(color: AppTheme.textSecondaryLight));

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}
