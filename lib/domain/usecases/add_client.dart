import 'package:physioprime/domain/entities/client_package.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/client.dart';
import '../repositories/client_repository.dart';

class AddClient implements UseCase<void, AddClientParams> {
  final ClientRepository repository;

  AddClient(this.repository);

  @override
  Future<Either<Failure, void>> call(AddClientParams params) async {
    final nextId = await repository.getNextClientId();
    final client = Client(
      id: nextId,
      name: params.name,
      age: params.age,
      phoneNumber: params.phone,
      details: params.details,
      bookedPackages: params.bookedPackages,
    );
    return Right(await repository.saveClient(client));
  }
}

class AddClientParams extends Equatable {
  final String name;
  final int age;
  final String phone;
  final String details;
  final List<ClientPackage> bookedPackages;

  const AddClientParams({
    required this.name,
    required this.age,
    required this.phone,
    required this.details,
    this.bookedPackages = const [],
  });

  @override
  List<Object?> get props => [name, age, phone, details, bookedPackages];
}
