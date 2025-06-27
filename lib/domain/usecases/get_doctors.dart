import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/doctor.dart';
import '../repositories/doctor_repository.dart';

class GetDoctors implements UseCase<List<Doctor>, NoParams> {
  final DoctorRepository repository;

  GetDoctors(this.repository);

  @override
  Future<Either<Failure, List<Doctor>>> call(NoParams params) async {
    final result = await repository.getAllDoctors();
    return Right(result);
  }
}
