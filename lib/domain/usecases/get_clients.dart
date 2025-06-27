import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../entities/client.dart';
import '../repositories/client_repository.dart';

class GetClients implements UseCase<List<Client>, NoParams> {
  final ClientRepository repository;

  GetClients(this.repository);

  @override
  Future<Either<Failure, List<Client>>> call(NoParams params) async {
    final result = await repository.getAllClients();
    return Right(result);
    // return await repository.getClient();
  }
}
