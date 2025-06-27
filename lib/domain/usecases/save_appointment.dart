import 'package:clinic_management_system/domain/entities/client_package.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/appointment.dart';
import '../entities/client.dart';
import '../repositories/appointment_repository.dart';
import '../repositories/client_repository.dart';

class SaveAppointment implements UseCase<void, SaveAppointmentParams> {
  final AppointmentRepository appointmentRepository;
  final ClientRepository clientRepository;

  SaveAppointment(this.appointmentRepository, this.clientRepository);

  @override
  Future<Either<Failure, void>> call(SaveAppointmentParams params) async {
    try {
      final selectedClient = params.selectedClient;
      final serviceType = params.serviceType;

      if (serviceType == 'Follow-up Session') {
        if (selectedClient != null && params.followUpPackageName != null) {
          final client = await clientRepository.getClient(selectedClient.id);
          if (client == null) return const Left(ClientNotFoundFailure());

          List<ClientPackage> updatedPackages = List.from(client.bookedPackages);
          bool packageSessionDecremented = false;

          for (int i = 0; i < updatedPackages.length; i++) {
            final pkg = updatedPackages[i];
            if (pkg.name == params.followUpPackageName && pkg.remainingSessions > 0) {
              updatedPackages[i] =
                  pkg.copyWith(remainingSessions: pkg.remainingSessions - 1);
              packageSessionDecremented = true;
              break;
            }
          }

          if (packageSessionDecremented) {
            await clientRepository.updateClient(
              client.copyWith(bookedPackages: updatedPackages),
            );
          } else {
            return const Left(AppointmentConflictFailure(
              message: 'Selected follow-up package not found or has no sessions.',
            ));
          }

          await appointmentRepository.saveAppointment(params.appointment);
          return const Right(null);
        } else {
          return const Left(AppointmentConflictFailure(
            message: 'Follow-up package not specified for a follow-up session.',
          ));
        }
      }

      if (selectedClient != null && serviceType != null) {
        final client = await clientRepository.getClient(selectedClient.id);
        if (client == null) return const Left(ClientNotFoundFailure());

        List<ClientPackage> updatedPackages = List.from(client.bookedPackages);
        String? targetCategory;
        final lowerService = serviceType.toLowerCase();

        if (lowerService.contains('physio') || lowerService.contains('recovery')) {
          targetCategory = 'Package Physio';
        } else if (lowerService.contains('machine')) {
          targetCategory = 'Package Machines';
        } else if (lowerService.contains('rehab')) {
          targetCategory = 'Package Rehabilitation';
        }

        if (targetCategory != null) {
          bool packageFoundAndDecremented = false;
          for (int i = 0; i < updatedPackages.length; i++) {
            final pkg = updatedPackages[i];
            if (pkg.category == targetCategory && pkg.remainingSessions > 0) {
              updatedPackages[i] =
                  pkg.copyWith(remainingSessions: pkg.remainingSessions - 1);
              packageFoundAndDecremented = true;
              break;
            }
          }

          if (packageFoundAndDecremented) {
            await clientRepository.updateClient(
              client.copyWith(bookedPackages: updatedPackages),
            );
          } else {
            return const Left(AppointmentConflictFailure(
              message:
                  'No suitable package with remaining sessions found for this service type.',
            ));
          }
        }

        await appointmentRepository.saveAppointment(params.appointment);
        return const Right(null);
      }

      // الحالة العامة بدون شروط خاصة
      await appointmentRepository.saveAppointment(params.appointment);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}

class SaveAppointmentParams extends Equatable {
  final Appointment appointment;
  final Client? selectedClient;
  final String? serviceType;
  final String? followUpPackageName;

  const SaveAppointmentParams({
    required this.appointment,
    this.selectedClient,
    this.serviceType,
    this.followUpPackageName,
  });

  @override
  List<Object?> get props =>
      [appointment, selectedClient, serviceType, followUpPackageName];
}
