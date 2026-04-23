import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlYW5tbHBvanVhYXhrZ2FobnNyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NjYxMDY2NiwiZXhwIjoyMDkyMTg2NjY2fQ.mqOp5vKIYIifhHgmxem7z0adxDUWKlDoL3kiXRs-Uf8',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJlYW5tbHBvanVhYXhrZ2FobnNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY2MTA2NjYsImV4cCI6MjA5MjE4NjY2Nn0.tFkU_hUtuUpQldDTgikTQs1F1Vw3g5Ay9BHvghqUAiM',
  );

  runApp(const ProviderScope(child: App()));
}
