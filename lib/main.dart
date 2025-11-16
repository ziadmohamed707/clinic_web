import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import hive_flutter
import 'package:physioone/core/app_consts/app_consts.dart';
import 'package:physioone/core/app_colors.dart';

import 'package:physioone/firebase_options.dart';
import 'package:physioone/ui/HomePage/ui/home_page.dart';
import 'package:physioone/ui/LoginPage/ui/login_page.dart';
import 'package:physioone/ui/LoginPage/bloc/auth_bloc.dart';
import 'package:physioone/ui/LoginPage/bloc/auth_state.dart';
import 'package:physioone/ui/LoginPage/repository/auth_repository.dart';
import 'package:physioone/helper/initialize_hive.dart';

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
            primaryColor: AppColors.primary,
            primaryColorDark: AppColors.primaryDark,
            primaryColorLight: AppColors.primaryLight,
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: AppColors.primarySwatch,
            ).copyWith(secondary: AppColors.secondary, error: AppColors.error),
            scaffoldBackgroundColor: AppColors.background,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 4,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            cardTheme: CardThemeData(
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
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFB2DFDB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primary, 
                  width: 2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primarySwatch[100]!),
              ),
              labelStyle: const TextStyle(color: AppColors.primaryDark),
              floatingLabelStyle: const TextStyle(color: AppColors.primary),
            ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
              headlineMedium: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
              headlineSmall: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryDark,
              ),
              bodyLarge: TextStyle(fontSize: 16, color: AppColors.black),
              bodyMedium: TextStyle(fontSize: 14, color: AppColors.black),
              labelLarge: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
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
        return state.isAuthenticated && state.userModel != null
            ? HomePage(user: state.userModel!) // This is correct
            : LoginScreen();
      },
    );
  }
}



// import 'package:physioone/firebase_options.dart';
// import 'package:physioone/ui/HomePage/ui/home_page.dart';
// import 'package:physioone/ui/LoginPage/bloc/auth_bloc.dart';
// import 'package:physioone/ui/LoginPage/bloc/auth_state.dart';
// import 'package:physioone/ui/LoginPage/repository/auth_repository.dart';
// import 'package:physioone/ui/LoginPage/ui/login_page.dart';
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



// import 'package:physioone/ui/HomePage/ui/home_page.dart';
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
