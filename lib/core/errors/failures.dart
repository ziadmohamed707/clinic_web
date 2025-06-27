import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final List properties;
  const Failure([this.properties = const <dynamic>[]]);

  @override
  List get props => properties;
}

// General failures
class ServerFailure extends Failure {
  final String message;
  const ServerFailure({this.message = 'Server Error'});
  @override
  List<Object> get props => [message];
}

class CacheFailure extends Failure {
  final String message;
  const CacheFailure({this.message = 'Cache Error'});
  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  final String message;
  const NetworkFailure({this.message = 'No Internet Connection'});
  @override
  List<Object> get props => [message];
}

// Specific failures for your app
class ClientNotFoundFailure extends Failure {
  const ClientNotFoundFailure();
}
class UnknownFailure extends Failure {
  final String message;
  const UnknownFailure({this.message = 'Unknown Error'});
  @override
  List<Object> get props => [message];
}
class AppointmentConflictFailure extends Failure {
  final String message;
  const AppointmentConflictFailure({this.message = 'Appointment conflict'});
  @override
  List<Object> get props => [message];
}
// Add other specific failures as needed