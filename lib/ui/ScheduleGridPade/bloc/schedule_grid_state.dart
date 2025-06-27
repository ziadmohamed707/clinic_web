import 'package:clinic_management_system/domain/entities/appointment.dart';
import 'package:clinic_management_system/domain/entities/client.dart';
import 'package:clinic_management_system/domain/entities/doctor.dart';
import 'package:equatable/equatable.dart';

abstract class ScheduleGridState extends Equatable {
  const ScheduleGridState();

  @override
  List<Object> get props => [];
}

class ScheduleGridInitial extends ScheduleGridState {}

class ScheduleGridLoading extends ScheduleGridState {}

class ScheduleGridLoaded extends ScheduleGridState {
  final DateTime selectedDate;
  final List<Doctor> availableDoctors;
  final Map<String, Appointment> appointments; // Key: 'yyyy-MM-dd-timeSlot-doctorId'
  final List<Client> allClients; // All clients for search and display
  final String? successMessage;
  final String? errorMessage;
  final int todayAppointmentsCount;
  final int cancelledAppointmentsCount;
  final int totalClientsCount;
  final int availableSlotsCount;


  const ScheduleGridLoaded({
    required this.selectedDate,
    required this.availableDoctors,
    required this.appointments,
    required this.allClients,
    this.successMessage,
    this.errorMessage,
    this.todayAppointmentsCount = 0,
    this.cancelledAppointmentsCount = 0,
    this.totalClientsCount = 0,
    this.availableSlotsCount = 0,
  });

  ScheduleGridLoaded copyWith({
    DateTime? selectedDate,
    List<Doctor>? availableDoctors,
    Map<String, Appointment>? appointments,
    List<Client>? allClients,
    String? successMessage,
    String? errorMessage,
    int? todayAppointmentsCount,
    int? cancelledAppointmentsCount,
    int? totalClientsCount,
    int? availableSlotsCount,
  }) {
    return ScheduleGridLoaded(
      selectedDate: selectedDate ?? this.selectedDate,
      availableDoctors: availableDoctors ?? this.availableDoctors,
      appointments: appointments ?? this.appointments,
      allClients: allClients ?? this.allClients,
      successMessage: successMessage,
      errorMessage: errorMessage,
      todayAppointmentsCount: todayAppointmentsCount ?? this.todayAppointmentsCount,
      cancelledAppointmentsCount: cancelledAppointmentsCount ?? this.cancelledAppointmentsCount,
      totalClientsCount: totalClientsCount ?? this.totalClientsCount,
      availableSlotsCount: availableSlotsCount ?? this.availableSlotsCount,
    );
  }

  @override
  List<Object> get props => [
        selectedDate,
        availableDoctors,
        appointments,
        allClients,
        todayAppointmentsCount,
        cancelledAppointmentsCount,
        totalClientsCount,
        availableSlotsCount,
        successMessage ?? '', // Include nullable fields for comparison
        errorMessage ?? '', // Include nullable fields for comparison
      ];
}

class ScheduleGridError extends ScheduleGridState {
  final String message;

  const ScheduleGridError(this.message);

  @override
  List<Object> get props => [message];
}