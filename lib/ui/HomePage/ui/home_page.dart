import 'package:clinic_management_system/helper/initialize_hive.dart';
import 'package:clinic_management_system/ui/LoginPage/bloc/auth_bloc.dart';
import 'package:clinic_management_system/ui/LoginPage/models/user_model.dart';
import 'package:clinic_management_system/ui/ScheduleGridPade/ui/schedule_grid_pade.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc bloc) => bloc.state.userModel);

    return FutureBuilder(
      future: initializeHive(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Error initializing local data: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('User not logged in')),
          );
        }

        return ScheduleGridScreen(user: user);
      },
    );
  }
}
