import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_prestaya_flutter/core/theme/app_theme.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_button.dart';
import 'package:app_prestaya_flutter/core/widgets/custom_input.dart';
import 'package:app_prestaya_flutter/injection_container.dart';
import 'package:app_prestaya_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:app_prestaya_flutter/features/home/presentation/pages/main_navigation_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsign;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final prefs = sl<SharedPreferences>();
    final savedEmail = prefs.getString('remembered_email');
    final savedPassword = prefs.getString('remembered_password');
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe && mounted) {
      setState(() {
        _emailController.text = savedEmail ?? '';
        _passwordController.text = savedPassword ?? '';
        _rememberMe = true;
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = sl<SharedPreferences>();
    if (_rememberMe) {
      await prefs.setString('remembered_email', _emailController.text);
      await prefs.setString('remembered_password', _passwordController.text);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('remembered_email');
      await prefs.remove('remembered_password');
      await prefs.setBool('remember_me', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          _saveCredentials(); // Guardar si tuvo éxito
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationPage()),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/logos/logo-prestaya-white.png',
                  width: 140,
                  height: 140,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_balance_wallet, size: 100, color: AppTheme.primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  '¡Bienvenido!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                ),
                const Text(
                  'Ingresa tus datos para continuar',
                  style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 40),
                CustomInput(
                  label: 'Correo electrónico',
                  placeholder: 'Ingresa tu correo electrónico',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  icon: Icons.email_outlined,
                ),
                CustomInput(
                  label: 'Contraseña',
                  placeholder: 'Ingresa tu contraseña',
                  controller: _passwordController,
                  isPassword: true,
                  icon: Icons.lock_outline,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: AppTheme.primary,
                          onChanged: (val) => setState(() => _rememberMe = val ?? false),
                        ),
                        const Text('Recordarme', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return CustomButton(
                      title: 'Iniciar Sesión',
                      loading: state is AuthLoading,
                      onPress: () {
                        if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
                          context.read<AuthBloc>().add(
                            LoginRequested(_emailController.text, _passwordController.text),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor completa todos los campos')),
                          );
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿No tienes una cuenta? ', style: TextStyle(color: AppTheme.textSecondary)),
                    GestureDetector(
                      onTap: () {},
                      child: const Text('Registrarse', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('O continuar con', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                    Expanded(child: Divider(color: AppTheme.border)),
                  ],
                ),
                const SizedBox(height: 25),
                Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: IconButton(
                      icon: Image.asset('assets/logos/google-icon.png', width: 28, errorBuilder: (c,e,s) => const Icon(Icons.g_mobiledata, size: 30)),
                      onPressed: () async {
                        try {
                          final googleSignIn = sl<gsign.GoogleSignIn>();
                          final googleUser = await googleSignIn.signIn();
                          if (googleUser != null) {
                            final googleAuth = await googleUser.authentication;
                            if (googleAuth.idToken != null) {
                              context.read<AuthBloc>().add(GoogleLoginRequested(googleAuth.idToken!));
                            }
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al iniciar sesión con Google: $e')),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
