import 'package:physioone/core/errors/failures.dart';
import 'package:physioone/core/usecases/usecase.dart';
import 'package:physioone/domain/usecases/add_client.dart';
import 'package:physioone/domain/usecases/get_clients.dart';
import 'package:physioone/domain/usecases/get_doctors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:dartz/dartz.dart';
import '/domain/entities/appointment.dart';
import '/domain/entities/doctor.dart';
import '/domain/usecases/cancel_appointment.dart';
import '/domain/usecases/get_appointments.dart';
import '/domain/usecases/save_appointment.dart';
import 'schedule_grid_event.dart';
import 'schedule_grid_state.dart';

class ScheduleGridBloc extends Bloc<ScheduleGridEvent, ScheduleGridState> {
  final GetAppointments getAppointments;
  final GetClients getClients;
  final GetDoctors getDoctors;
  final SaveAppointment saveAppointment;
  final CancelAppointment cancelAppointment;
  final AddClient addClient;

  final List<String> timeSlots = [
    '09:00 AM',
    '09:50 AM',
    '10:40 AM',
    '11:30 AM',
    '12:20 PM',
    '01:10 PM',
    '02:00 PM',
    '02:50 PM',
    '03:40 PM',
    '04:30 PM',
    '05:20 PM',
    '06:10 PM',
    '07:00 PM',
    '07:50 PM',
    '08:40 PM',
    '09:30 PM',
    '10:20 PM',
    '11:10 PM',
    '12:00 AM',
  ];

  ScheduleGridBloc({
    required this.getAppointments,
    required this.getClients,
    required this.getDoctors,
    required this.saveAppointment,
    required this.cancelAppointment,
    required this.addClient,
  }) : super(ScheduleGridInitial()) {
    on<LoadSchedule>(_onLoadSchedule);
    on<DateSelected>(_onDateSelected);
    on<SyncData>(_onSyncData);
    on<SaveAppointmentEvent>(_onSaveAppointment);
    on<CancelAppointmentEvent>(_onCancelAppointment);
    on<AddClientEvent>(_onAddClient);
  }

  Future<void> _onLoadSchedule(
    LoadSchedule event,
    Emitter<ScheduleGridState> emit,
  ) async {
    emit(ScheduleGridLoading());
    await _fetchAndEmitSchedule(event.date, emit);
  }

  Future<void> _onDateSelected(
    DateSelected event,
    Emitter<ScheduleGridState> emit,
  ) async {
    emit(ScheduleGridLoading());
    await _fetchAndEmitSchedule(event.newDate, emit);
  }

  Future<void> _onSyncData(
    SyncData event,
    Emitter<ScheduleGridState> emit,
  ) async {
    final currentDate =
        state is ScheduleGridLoaded
            ? (state as ScheduleGridLoaded).selectedDate
            : DateTime.now();

    emit(ScheduleGridLoading());
    await _fetchAndEmitSchedule(currentDate, emit);
  }

  Future<void> _onSaveAppointment(
    SaveAppointmentEvent event,
    Emitter<ScheduleGridState> emit,
  ) async {
    if (state is! ScheduleGridLoaded) return;
    final currentState = state as ScheduleGridLoaded;
    emit(ScheduleGridLoading());

    final result = await saveAppointment(
      SaveAppointmentParams(
        appointment: event.appointment,
        selectedClient: event.selectedClient,
        serviceType: event.serviceType,
        followUpPackageName: event.followUpPackageName,
      ),
    );

    result.fold(
      (failure) => emit(
        currentState.copyWith(errorMessage: _mapFailureToMessage(failure)),
      ),
      (_) async {
        await _fetchAndEmitSchedule(
          currentState.selectedDate,
          emit,
          successMessage: 'Appointment saved successfully!',
        );
      },
    );
  }

  Future<void> _onCancelAppointment(
    CancelAppointmentEvent event,
    Emitter<ScheduleGridState> emit,
  ) async {
    if (state is! ScheduleGridLoaded) return;
    final currentState = state as ScheduleGridLoaded;
    emit(ScheduleGridLoading());

    try {
      await cancelAppointment(
        CancelAppointmentParams(
          appointmentId: event.appointmentId,
          patientName: event.patientName,
          patientPhone: event.patientPhone,
          doctorName: event.doctorName,
          clientId: event.clientId!,
          serviceType: event.serviceType,
          packageNameUsed: event.packageNameUsed,
          packageCategoryUsed: event.packageCategoryUsed,
        ),
      );

      await _fetchAndEmitSchedule(
        currentState.selectedDate,
        emit,
        successMessage: 'Appointment cancelled successfully!',
      );
    } catch (e) {
      emit(
        currentState.copyWith(errorMessage: 'Failed to cancel appointment: $e'),
      );
    }
  }

  Future<void> _onAddClient(
    AddClientEvent event,
    Emitter<ScheduleGridState> emit,
  ) async {
    if (state is! ScheduleGridLoaded) return;
    final currentState = state as ScheduleGridLoaded;
    emit(ScheduleGridLoading());

    final result = await addClient(
      AddClientParams(
        name: event.name,
        age: event.age,
        phone: event.phone,
        details: event.details,
        bookedPackages: event.bookedPackages,
      ),
    );

    result.fold(
      (failure) => emit(
        currentState.copyWith(errorMessage: _mapFailureToMessage(failure)),
      ),
      (_) async {
        await _fetchAndEmitSchedule(
          currentState.selectedDate,
          emit,
          successMessage: 'Client added successfully!',
        );
      },
    );
  }

  Future<void> _fetchAndEmitSchedule(
    DateTime date,
    Emitter<ScheduleGridState> emit, {
    String? successMessage,
  }) async {
    final appointmentsResult = await getAppointments(date);
    final clientsResult = await getClients(NoParams());
    final doctorsResult = await getDoctors(NoParams());

    final appointments = appointmentsResult;
    final clients = clientsResult.getOrElse(() => []);
    final doctors = doctorsResult.getOrElse(() => []);

    final Map<String, Appointment> appointmentsMap = {
      for (var appt in appointments) appt.id: appt,
    };

    final String dayOfWeek = DateFormat('EEEE').format(date);
    final List<Doctor> availableDoctors =
        doctors
            .where((doctor) => doctor.availableDays.contains(dayOfWeek))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    int todayAppointmentsCount = 0;
    int cancelledAppointmentsCount = 0;
    final formattedDateKey = DateFormat('yyyy-MM-dd').format(date);

    for (var appt in appointments) {
      if (appt.id.startsWith(formattedDateKey)) {
        if (appt.status == 'booked') {
          todayAppointmentsCount++;
        } else if (appt.status == 'cancelled') {
          cancelledAppointmentsCount++;
        }
      }
    }

    final int totalClientsCount = clients.length;
    final int availableSlotsCount =
        (availableDoctors.length * timeSlots.length) - todayAppointmentsCount;

    emit(
      ScheduleGridLoaded(
        selectedDate: date,
        availableDoctors: availableDoctors,
        appointments: appointmentsMap,
        allClients: clients,
        successMessage: successMessage,
        todayAppointmentsCount: todayAppointmentsCount,
        cancelledAppointmentsCount: cancelledAppointmentsCount,
        totalClientsCount: totalClientsCount,
        availableSlotsCount: availableSlotsCount,
      ),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) return failure.message;
    if (failure is CacheFailure) return failure.message;
    if (failure is NetworkFailure) return failure.message;
    if (failure is AppointmentConflictFailure) return failure.message;
    if (failure is ClientNotFoundFailure) return 'Client not found.';
    return 'Unexpected error';
  }
}
