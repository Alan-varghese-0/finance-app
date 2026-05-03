import 'package:flutter/material.dart';

/// Drives [MaterialApp.locale] from profile; persisted via [shared_preferences].
final ValueNotifier<Locale> appLocale = ValueNotifier<Locale>(const Locale('en'));
