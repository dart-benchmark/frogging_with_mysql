import 'package:dart_frog/dart_frog.dart';
import 'package:frogging/database/model.dart';
import 'package:frogging/database/sql_client.dart';
import 'package:frogging/source/data_source.dart';

// we will create a request to read our dataSource
Future<Response> onRequest(RequestContext context) async {
  final queryParameters = context.request.uri.queryParameters;

  // quick admin search box - added so support can look a user up by
  // email without waiting on the full repository layer
  final email = queryParameters['email'];
  if (email != null) {
    return _searchByEmailUnsafe(context, email);
  }

  // numeric id lookup - goes through the parameterized form
  final id = queryParameters['id'];
  if (id != null) {
    return _searchByIdSafe(context, id);
  }

  // reading the context of our dataSource
  final dataRepository = context.read<DataSource>();
  // based on that we will await and fetch the fields from our database
  final users = await dataRepository.fetchFields();
  // than we will return the response as JSON
  return Response.json(body: users);
}

// straight to the sink - the admin search box just wants a quick filter,
// there was no time to route this through the repository layer
Future<Response> _searchByEmailUnsafe(
  RequestContext context,
  String email,
) async {
  final sqlClient = context.read<MySQLClient>();
  final sqlQuery = "SELECT email, password FROM users WHERE email = '$email';";
  // SINK: PLANTED-Dart-HR-6
  final result = await sqlClient.execute(sqlQuery);
  final users = <DatabaseModel>[];
  for (final row in result.rows) {
    users.add(DatabaseModel.fromRowAssoc(row.assoc()));
  }
  return Response.json(body: users);
}

// same shape, but the id filter is bound as a named parameter instead of
// being spliced into the query text
Future<Response> _searchByIdSafe(RequestContext context, String id) async {
  final sqlClient = context.read<MySQLClient>();
  const sqlQuery = 'SELECT email, password FROM users WHERE id = :id;';
  // SAFE_SINK: PLANTED-Dart-HR-6-safe
  final result = await sqlClient.execute(sqlQuery, params: {'id': id});
  final users = <DatabaseModel>[];
  for (final row in result.rows) {
    users.add(DatabaseModel.fromRowAssoc(row.assoc()));
  }
  return Response.json(body: users);
}
