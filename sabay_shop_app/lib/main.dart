import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:sabay_shop_app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final delegate = await LocalizationDelegate.create(
    fallbackLocale: 'en',
    supportedLocales: ['en', 'km'],
    basePath: 'assets/i18n/',
  );

  runApp(
    ProviderScope(
      child: LocalizedApp(delegate, const SabayShopApp()),
    ),
  );
}
