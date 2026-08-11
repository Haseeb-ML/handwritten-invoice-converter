import 'package:flutter/material.dart';
import 'localization.dart';
import 'main.dart';
import 'invoices_list_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkTheme = false;
  bool _autoCorrectUrdu = true;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalization.currentLanguage,
      builder: (context, currentLanguage, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          // Use theme defaults instead of hardcoded F6F8FA
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false, // If pushed, no back button based on previous design which had an avatar instead
        title: Text(
          AppLocalization.t('settings'),
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0C4A4A), fontWeight: FontWeight.w600, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Language Preference', isDark),
              _buildLanguageCard(),
              const SizedBox(height: 24),

              _buildSectionTitle('Visuals', isDark),
              _buildSwitchCard(
                title: 'Dark Theme',
                icon: Icons.dark_mode_outlined,
                value: AppTheme.themeMode.value == ThemeMode.dark,
                onChanged: (val) {
                  AppTheme.themeMode.value = val ? ThemeMode.dark : ThemeMode.light;
                  setState(() {});
                },
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('AI Assistant Settings', isDark),
              _buildSwitchCard(
                title: 'Auto Correct Urdu',
                subtitle: 'Smart spelling correction for Urdu names',
                icon: Icons.spellcheck,
                value: _autoCorrectUrdu,
                onChanged: (val) {
                  setState(() => _autoCorrectUrdu = val);
                },
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('Data & Storage', isDark),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      icon: Icons.cloud_outlined,
                      title: 'Cloud Backup',
                      subtitle: 'Last synced: 2m ago',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInfoCard(
                      icon: Icons.sync_problem,
                      title: 'Offline Queue',
                      subtitle: '3 Invoices pending',
                      accentColor: const Color(0xFFD4AF37),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 120), // Bottom padding for bottom nav bar
            ],
          ),
        ),
      ),
      // Custom Bottom Navigation
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_outlined, AppLocalization.t('home'), false, () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                );
              }, isDark),
              _buildNavItem(Icons.receipt_long, AppLocalization.t('invoices'), false, () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const InvoicesListScreen()),
                );
              }, isDark),
              // Center FAB-like button
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFF0C4A4A),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x66075E54), blurRadius: 10, offset: Offset(0, 5))],
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const DashboardScreen()),
                    );
                  },
                ),
              ),
              _buildNavItem(Icons.settings, AppLocalization.t('settings'), true, () {}, isDark),
            ],
          ),
        ),
      ),
    );
    },
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap, bool isDark) {
    final color = isActive ? const Color(0xFF075E54) : (isDark ? Colors.white54 : Colors.black54);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF4B5563)),
      ),
    );
  }

  Widget _buildLanguageCard() {
    final isUrdu = AppLocalization.currentLanguage.value == 'urdu';
    final isDark = AppTheme.themeMode.value == ThemeMode.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0C4A4A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.language, color: Color(0xFF0C4A4A)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text('App Language', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
          ),
          Container(
            height: 36,
            decoration: BoxDecoration(
              border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    if (!isUrdu) AppLocalization.toggleLanguage();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isUrdu ? const Color(0xFF0C4A4A) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'اردو',
                      style: TextStyle(
                        color: isUrdu ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (isUrdu) AppLocalization.toggleLanguage();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: !isUrdu ? const Color(0xFF0C4A4A) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'English',
                      style: TextStyle(
                        color: !isUrdu ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchCard({required String title, String? subtitle, required IconData icon, required bool value, required ValueChanged<bool> onChanged, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0C4A4A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0C4A4A)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ]
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0C4A4A),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String subtitle, Color? accentColor, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: accentColor != null ? Border(left: BorderSide(color: accentColor, width: 4)) : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0C4A4A)),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
