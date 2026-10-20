import 'package:flutter/material.dart';

import 'src/expense_repository.dart';
import 'src/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(ExpenseTrackerApp(repository: ExpenseRepository()));
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key, required this.repository});

  final ExpenseRepository repository;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xff176b57);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      surface: const Color(0xfff7f4eb),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Encrypted Expense Tracker',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.surface,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        cardTheme: const CardThemeData(
          clipBehavior: Clip.antiAlias,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      ),
      home: ExpenseHomePage(repository: repository),
    );
  }
}
