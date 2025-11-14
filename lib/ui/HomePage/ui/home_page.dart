import 'package:physioone/ui/LoginPage/models/user_model.dart';
import 'package:physioone/ui/ScheduleGridPade/ui/schedule_grid_pade.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final UserModel user;

  const HomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // The HomePage now directly returns the ScheduleGridScreen,
    // receiving the authenticated user model from the AuthStateListener.
    return ScheduleGridScreen(user: user);
  }
}
