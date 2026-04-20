import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app_prestaya_flutter/features/home/presentation/pages/main_navigation_page.dart';
import 'package:app_prestaya_flutter/features/auth/presentation/pages/login_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationPage()),
          );
        } else if (state is Unauthenticated || state is AuthError) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppTheme.splashGradient,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logos/logo-prestaya-white.png',
                width: 220,
                height: 220,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance_wallet, size: 100, color: Colors.white),
                  );
                },
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
