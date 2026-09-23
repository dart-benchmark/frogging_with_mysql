import 'package:dart_frog/dart_frog.dart';
import 'package:frogging/database/sql_client.dart';
import 'package:frogging/source/user_repository.dart';

/// Legacy account-recovery endpoint - some older clients still send the
/// user's own email back as the "recovery token".
Future<Response> onRequest(RequestContext context, String token) async {
  final sqlClient = context.read<MySQLClient>();
  final repository = UserRepository(sqlClient, token);

  // the parameterized path is opt-in until every client is migrated
  final safe = context.request.uri.queryParameters['safe'] == 'true';
  final users = safe ? await repository.resolveSafe() : await repository.resolve();
  return Response.json(body: users);
}
