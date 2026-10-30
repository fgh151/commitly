import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const ProviderScope(child: CommitlyApp()));
}
