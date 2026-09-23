import 'package:dart_frog/dart_frog.dart';
import 'package:frogging/database/tenant_selector_strategy.dart';

/// Admin tenant lookup - some older internal tools still call this with
/// `x-selector-mode: legacy` to keep using the pre-migration direct-connect
/// path.
Future<Response> onRequest(RequestContext context) async {
  final requestedSchema =
      context.request.uri.queryParameters['schema'] ?? 'tenant_alpha';
  final legacy = context.request.headers['x-selector-mode'] == 'legacy';

  final TenantDatabaseSelector selector = legacy
      ? const DirectTenantDatabaseSelector()
      : const AllowlistedTenantDatabaseSelector();

  final result = await selector.query(requestedSchema, 'SELECT 1;');
  return Response.json(body: {'rowCount': result.rows.length});
}
