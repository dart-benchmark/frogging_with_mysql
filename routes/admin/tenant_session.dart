import 'package:dart_frog/dart_frog.dart';
import 'package:frogging/source/tenant_session.dart';

/// Admin diagnostics endpoint - opens a per-request session bound to
/// whichever tenant schema the caller names, then runs a health check.
Future<Response> onRequest(RequestContext context) async {
  final schema =
      context.request.uri.queryParameters['schema'] ?? 'tenant_alpha';
  final safe = context.request.uri.queryParameters['safe'] == 'true';

  final result = safe
      ? await ValidatedTenantAdminSession(schema).runDiagnostics()
      : await TenantAdminSession(schema).runDiagnostics();

  return Response.json(body: {'rowCount': result.rows.length});
}
