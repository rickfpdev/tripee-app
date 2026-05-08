class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException({super.message = 'Erro de conexão. Verifique sua internet.'});
}

class ServerException extends AppException {
  const ServerException({super.message = 'Erro no servidor. Tente novamente.', super.statusCode});
}

class NotFoundException extends AppException {
  const NotFoundException({super.message = 'Corrida não encontrada.'});
}