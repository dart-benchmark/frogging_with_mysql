import 'package:dart_frog/dart_frog.dart';
import 'package:frogging/database/tenant_connector.dart';

/// Ad-hoc admin diagnostics query - runs a fixed health-check statement
/// against whichever tenant schema the caller names.
Future<Response> onRequest(RequestContext context) async {
  const connector = TenantDatabaseConnector();
  final schema =
      context.request.uri.queryParameters['schema'] ?? 'tenant_alpha';
  final safe = context.request.uri.queryParameters['safe'] == 'true';

  final result = safe
      ? await connector.querySafe(schema, 'SELECT 1;')
      : await connector.query(schema, 'SELECT 1;');

  return Response.json(body: {'rowCount': result.rows.length});
}
