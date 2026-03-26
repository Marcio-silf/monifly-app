import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/remote/supabase_client.dart';
import 'data/datasources/local/shared_prefs_helper.dart';
import 'package:monifly/presentation/app.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Variáveis de Ambiente
  await dotenv.load(fileName: ".env");

  // Initialize Date Formatting for Brazilian Portuguese
  await initializeDateFormatting('pt_BR', null);
  Intl.defaultLocale = 'pt_BR';

  // Load environment if any or just initialize Supabase
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  } catch (e) {
    debugPrint('Supabase initialization failed: $e');
  }

  // Initialize SharedPreferences
  await SharedPrefsHelper.init();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('transactions');
  await Hive.openBox('goals');
  await Hive.openBox('budgets');
  await Hive.openBox('metadata'); // For caching stats or summaries

  // Set system UI preferences
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Lock rotation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: MoniflyApp()));
}
