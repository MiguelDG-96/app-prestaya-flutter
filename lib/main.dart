import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/features/auth/presentation/pages/splash_page.dart';
import 'package:app_prestaya_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:app_prestaya_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app_prestaya_flutter/features/clients/presentation/bloc/clients_bloc.dart';
import 'package:app_prestaya_flutter/features/loans/presentation/bloc/loans_bloc.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/bloc/rentals_bloc.dart';
import 'package:app_prestaya_flutter/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:app_prestaya_flutter/core/services/firebase_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'injection_container.dart' as di;
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  await FirebaseService.init();
  await initializeDateFormatting('es', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthBloc>()..add(AuthCheckRequested())),
        BlocProvider(create: (_) => sl<ClientsBloc>()),
        BlocProvider(create: (_) => sl<LoansBloc>()),
        BlocProvider(create: (_) => sl<RentalsBloc>()),
        BlocProvider(create: (_) => sl<NotificationsBloc>()),
      ],
      child: MaterialApp(
        title: 'PrestaYa',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashPage(),
          '/login': (context) => const LoginPage(),
        },
      ),
    );
  }
}
