import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_provider.dart';
import 'providers/math_provider.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.init();
  runApp(const MathHelperApp());
}

class MathHelperApp extends StatelessWidget {
  const MathHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => MathProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, _) {
          return MaterialApp(
            title: 'Math Helper AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: Locale(appProvider.language),
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
              Locale('fr'),
              Locale('es'),
              Locale('zh'),
              Locale('de'),
              Locale('hi'),
              Locale('ja'),
              Locale('ko'),
              Locale('ru'),
              Locale('pt'),
              Locale('tr'),
              Locale('it'),
            ],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
