import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../services/ai_service.dart';
import '../constants.dart';
import '../theme.dart';
import 'privacy_policy_screen.dart';
import 'terms_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _apiUrlController = TextEditingController();
  bool _showApiKey = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appProvider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Section
          _buildSectionHeader(l10n.language, Icons.language, isDark),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: DropdownButton<String>(
                value: appProvider.language,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: isDark ? AppTheme.cardDark : Colors.white,
                items: AppConstants.supportedLanguages.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      '${entry.value}  (${entry.key.toUpperCase()})',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) appProvider.setLanguage(value);
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Difficulty Section
          _buildSectionHeader(l10n.difficulty, Icons.speed, isDark),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: DropdownButton<String>(
                value: appProvider.difficulty,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: isDark ? AppTheme.cardDark : Colors.white,
                items: [
                  DropdownMenuItem(
                    value: AppConstants.beginner,
                    child: Text(
                      '📗 ${l10n.beginner}',
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark),
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.intermediate,
                    child: Text(
                      '📙 ${l10n.intermediate}',
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark),
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.advanced,
                    child: Text(
                      '📕 ${l10n.advanced}',
                      style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) appProvider.setDifficulty(value);
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Explanation Mode
          _buildSectionHeader(l10n.explanationMode, Icons.description, isDark),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: DropdownButton<String>(
                value: appProvider.explanationMode,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: isDark ? AppTheme.cardDark : Colors.white,
                items: [
                  DropdownMenuItem(
                    value: AppConstants.simpleMode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.simple,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.simpleDescription,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textLight.withAlpha(153) : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.detailedMode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.detailed,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppTheme.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.detailedDescription,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textLight.withAlpha(153) : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) appProvider.setExplanationMode(value);
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Appearance
          _buildSectionHeader(l10n.darkMode, Icons.palette, isDark),
          Card(
            child: SwitchListTile(
              title: Text(l10n.darkMode),
              secondary: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                color: AppTheme.accentCyan,
              ),
              value: appProvider.isDarkMode,
              activeTrackColor: AppTheme.accentCyan,
              onChanged: (_) => appProvider.toggleDarkMode(),
            ),
          ),

          const SizedBox(height: 20),

          // AI Configuration
          _buildSectionHeader(l10n.aiConfiguration, Icons.smart_toy, isDark),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.apiKeyLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.poweredByAI,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppTheme.textLight.withAlpha(153)
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: !_showApiKey,
                    decoration: InputDecoration(
                      hintText: l10n.apiKeyLabel,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _showApiKey ? Icons.visibility_off : Icons.visibility,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _showApiKey = !_showApiKey),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check, size: 20, color: AppTheme.accentGreen),
                            onPressed: _saveApiConfig,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiUrlController,
                    decoration: InputDecoration(
                      hintText: l10n.apiUrl,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.accentCyan.withAlpha(13),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          AiService.isConfigured ? Icons.check_circle : Icons.info_outline,
                          color: AiService.isConfigured ? AppTheme.accentGreen : AppTheme.accentCyan,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AiService.isConfigured
                                ? '${l10n.apiConfigured} \u2713'
                                : l10n.apiNotConfigured,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.textLight : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Legal
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                ),
                child: const Text('Privacy Policy'),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TermsScreen()),
                ),
                child: const Text('Terms of Service'),
              ),
            ],
          ),

          // About
          _buildSectionHeader(l10n.about, Icons.info_outline, isDark),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'x²',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentCyan,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.appTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l10n.version} ${AppConstants.appVersion}',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.textLight.withAlpha(128)
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.appDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? AppTheme.textLight.withAlpha(179)
                          : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accentCyan, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }

  void _saveApiConfig() {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isNotEmpty) {
      AiService.configure(
        apiKey: apiKey,
        apiUrl: _apiUrlController.text.trim().isEmpty
            ? null
            : _apiUrlController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)?.apiSaved ?? 'API configuration saved'),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
