import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import hive_flutter
import 'package:physioprime/core/app_consts/app_consts.dart';

import 'package:physioprime/firebase_options.dart';
import 'package:physioprime/ui/HomePage/ui/home_page.dart';
import 'package:physioprime/ui/LoginPage/ui/login_page.dart';
import 'package:physioprime/ui/LoginPage/bloc/auth_bloc.dart';
import 'package:physioprime/ui/LoginPage/bloc/auth_state.dart';
import 'package:physioprime/ui/LoginPage/repository/auth_repository.dart';
import 'package:physioprime/helper/initialize_hive.dart'; // Import your Hive initializer

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeHive(); // Initialize Hive before runApp
  await Hive.openBox('userSession');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AuthRepository(),
      child: BlocProvider(
        create:
            (context) => AuthBloc(
              authRepository: RepositoryProvider.of<AuthRepository>(context),
            ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConsts.appName,
          theme: ThemeData(
            primaryColor: const Color(0xFF00796B),
            primaryColorDark: const Color(0xFF004D40),
            primaryColorLight: const Color(0xFF4DB6AC),
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: const MaterialColor(0xFF00796B, <int, Color>{
                50: Color(0xFFE0F2F1),
                100: Color(0xFFB2DFDB),
                200: Color(0xFF80CBC4),
                300: Color(0xFF4DB6AC),
                400: Color(0xFF26A69A),
                500: Color(0xFF009688),
                600: Color(0xFF00897B),
                700: Color(0xFF00796B),
                800: Color(0xFF00695C),
                900: Color(0xFF004D40),
              }),
            ).copyWith(
              secondary: const Color(0xFF4CAF50),
              error: Colors.redAccent,
            ),
            scaffoldBackgroundColor: const Color(0xFFFAFAFA),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF00796B),
              foregroundColor: Colors.white,
              elevation: 4,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00796B),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFB2DFDB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF00796B),
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFB2DFDB)),
              ),
              labelStyle: const TextStyle(color: Color(0xFF004D40)),
              floatingLabelStyle: const TextStyle(color: Color(0xFF00796B)),
            ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004D40),
              ),
              headlineMedium: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF004D40),
              ),
              headlineSmall: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xFF004D40),
              ),
              bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
              bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
              labelLarge: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          home: const AuthStateListener(),
        ),
      ),
    );
  }
}

class AuthStateListener extends StatelessWidget {
  const AuthStateListener({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return state.isAuthenticated ? const HomePage() : LoginScreen();
      },
    );
  }
}



// import 'package:physioprime/firebase_options.dart';
// import 'package:physioprime/ui/HomePage/ui/home_page.dart';
// import 'package:physioprime/ui/LoginPage/bloc/auth_bloc.dart';
// import 'package:physioprime/ui/LoginPage/bloc/auth_state.dart';
// import 'package:physioprime/ui/LoginPage/repository/auth_repository.dart';
// import 'package:physioprime/ui/LoginPage/ui/login_page.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   // Hive is now initialized after successful login inside the AuthBloc,
//   // so we don't need to call it here.
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return RepositoryProvider(
//       create: (context) => AuthRepository(),
//       child: BlocProvider(
//         create: (context) => AuthBloc(
//           authRepository: RepositoryProvider.of<AuthRepository>(context),
//         ),
//         child: MaterialApp(
//           title: 'Clinic Management System',
//           theme: ThemeData(
//             primarySwatch: Colors.teal,
//             visualDensity: VisualDensity.adaptivePlatformDensity,
//           ),
//           home: const AuthStateListener(),
//         ),
//       ),
//     );
//   }
// }

// class AuthStateListener extends StatelessWidget {
//   const AuthStateListener({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<AuthBloc, AuthState>(
//       builder: (context, state) {
//         return state.isAuthenticated ?  HomePage() : LoginScreen();
//       },
//     );
//   }
// }



// import 'package:physioprime/ui/HomePage/ui/home_page.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart'; // Import the generated firebase_options.dart

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options:
//         DefaultFirebaseOptions.currentPlatform, // Use platform-specific options
//   );
//   runApp(HomePage()); // HomePage will handle auth state and Hive initialization
// }
