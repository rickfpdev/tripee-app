import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:tripee_app/core/theme/app_theme.dart';
import 'package:tripee_app/features/schedules/data/repositories/schedules_repository.dart';
import 'package:tripee_app/features/schedules/presentation/providers/schedules_detail_provider.dart';
import 'package:tripee_app/features/schedules/presentation/providers/schedules_provider.dart';
import 'package:tripee_app/features/schedules/presentation/screens/schedule_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const TripeeApp());
}

class TripeeApp extends StatelessWidget {
  const TripeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final schedulesRepository = SchedulesRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SchedulesProvider(repository: schedulesRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ScheduleDetailProvider(repository: schedulesRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Tripee',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const SchedulesListScreen(),
      ),
    );
  }
}
