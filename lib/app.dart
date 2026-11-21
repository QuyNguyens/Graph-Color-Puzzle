import 'package:flutter/material.dart';

import 'features/campaign/presentation/screens/campaign_home_screen.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

/// Root Widget cấu hình theme và routing của Graph Coloring Game.
/// Sử dụng AppTheme.darkTheme đồng bộ toàn diện Midnight Slate / Deep Navy.
/// Tích hợp đa ngôn ngữ (Tiếng Việt và Tiếng Anh) chuẩn Flutter Localizations.
class GraphColoringApp extends StatelessWidget {
  const GraphColoringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Graph Coloring',
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (Locale? locale, Iterable<Locale> supportedLocales) {
        if (locale != null && locale.languageCode == 'vi') {
          return const Locale('vi');
        }
        return const Locale('en');
      },
      home: const CampaignHomeScreen(),
    );
  }
}
