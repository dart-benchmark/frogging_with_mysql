import 'package:dart_frog/dart_frog.dart';
import 'package:mysql1/mysql1.dart';

/// Admin tenant inspector - lets an operator open a short-lived connection
/// to a specific tenant's schema on the shared, trusted MySQL host to run a
/// quick health check, instead of routing through the shared `profiles`
/// connection every other route uses.
Future<Response> onRequest(RequestContext context, String schema) async {
  final validated = context.request.uri.queryParameters['safe'] == 'true';
  return validated ? _inspectValidatedSchema(schema) : _inspectSchema(schema);
}

/// The path segment names the schema to connect to, verbatim.
Future<Response> _inspectSchema(String schema) async {
  // SINK: PLANTED-Dart-HR-705
  final conn = await MySqlConnection.connect(
    ConnectionSettings(
      host: '127.0.0.1',
      port: 3306,
      user: 'root',
      password: '123456789',
      db: schema,
    ),
  );
  try {
    final results = await conn.query('SHOW TABLE STATUS;');
    return Response.json(body: {'tableCount': results.length});
  } finally {
    await conn.close();
  }
}

/// The only schemas an admin inspection request is actually allowed to
/// target - anything else falls back to the default tenant.
const _knownTenantSchemas = {'tenant_alpha', 'tenant_beta', 'tenant_gamma'};

/// Same inspection, but the schema is checked against the known list
/// before the connection is ever opened.
Future<Response> _inspectValidatedSchema(String schema) async {
  final safeSchema = _knownTenantSchemas.contains(schema)
      ? schema
      : 'tenant_alpha';
  // SAFE_SINK: PLANTED-Dart-HR-705-safe
  final conn = await MySqlConnection.connect(
    ConnectionSettings(
      host: '127.0.0.1',
      port: 3306,
      user: 'root',
      password: '123456789',
      db: safeSchema,
    ),
  );
  try {
    final results = await conn.query('SHOW TABLE STATUS;');
    return Response.json(body: {'tableCount': results.length});
  } finally {
    await conn.close();
  }
}
