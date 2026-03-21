import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../l10n/app_localizations.dart';
import '../providers/math_provider.dart';
import '../widgets/logo_widget.dart';
import '../theme.dart';
import 'text_input_screen.dart';
import 'camera_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _isOffline = results.every((r) => r == ConnectivityResult.none);
        });
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isOffline = results.every((r) => r == ConnectivityResult.none);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final screens = [
      _buildHomeContent(context, l10n),
      const HistoryScreen(),
      const HistoryScreen(showFavoritesOnly: true),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: Column(
        children: [
          if (_isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.orange[700],
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Offline — Local solver only',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: screens[_currentIndex]),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withAlpha(10)
                  : Colors.black.withAlpha(10),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              activeIcon: _buildActiveNavIcon(Icons.home_rounded),
              label: l10n.appTitle,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.history_rounded),
              activeIcon: _buildActiveNavIcon(Icons.history_rounded),
              label: l10n.history,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_rounded),
              activeIcon: _buildActiveNavIcon(Icons.favorite_rounded),
              label: l10n.favorites,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_rounded),
              activeIcon: _buildActiveNavIcon(Icons.settings_rounded),
              label: l10n.settings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveNavIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.accentPurple.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppTheme.accentPurple),
    );
  }

  Widget _buildHomeContent(BuildContext context, AppLocalizations l10n) {
    final mathProvider = context.watch<MathProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 28),

            // Logo & title
            const LogoWidget(size: 110),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppTheme.primaryGradient.createShader(bounds),
              child: Text(
                l10n.appTitle,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.yourAIMathTutor,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppTheme.textLight.withAlpha(160)
                    : Colors.grey[500],
                letterSpacing: 0.3,
              ),
            ),

            const SizedBox(height: 36),

            // Action cards
            _buildActionCard(
              context: context,
              icon: Icons.edit_rounded,
              title: l10n.typeProblem,
              subtitle: l10n.typeSubtitle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TextInputScreen()),
              ),
            ),

            const SizedBox(height: 14),

            _buildActionCard(
              context: context,
              icon: Icons.camera_alt_rounded,
              title: l10n.scanProblem,
              subtitle: l10n.scanSubtitle,
              gradient: const LinearGradient(
                colors: [Color(0xFF00B4D8), Color(0xFF0096C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CameraScreen()),
              ),
            ),

            const SizedBox(height: 28),

            // Stats
            if (mathProvider.history.isNotEmpty)
              _buildStatsRow(context, l10n, mathProvider, isDark),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.first.withAlpha(50),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withAlpha(190),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    AppLocalizations l10n,
    MathProvider mathProvider,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            '${mathProvider.history.length}',
            l10n.solved,
            Icons.check_circle_rounded,
            AppTheme.accentGreen,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatTile(
            '${mathProvider.favorites.length}',
            l10n.favorites,
            Icons.favorite_rounded,
            AppTheme.accentPurple,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    String value,
    String label,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.textDark,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.textLight.withAlpha(120)
                        : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
