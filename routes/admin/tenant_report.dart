import 'package:dart_frog/dart_frog.dart';
import 'package:mysql1/mysql1.dart';

/// Per-tenant billing report - the tenant code picks which schema on the
/// shared host the report is generated against.
Future<Response> onRequest(RequestContext context) async {
  final tenantCode = context.request.uri.queryParameters['tenantCode'] ?? '';
  final validated = context.request.uri.queryParameters['validated'] == 'true';
  return validated
      ? _billingReportForValidatedTenant(tenantCode)
      : _billingReportForTenant(tenantCode);
}

/// The tenant code is folded into the schema name before the connection is
/// opened - the transform doesn't restrict which schema ends up selected,
/// it only fixes a prefix an attacker can still pick the rest of.
Future<Response> _billingReportForTenant(String tenantCode) async {
  final schemaName = 'tenant_' + tenantCode.trim().toLowerCase();
  // SINK: PLANTED-Dart-HR-706
  final conn = await MySqlConnection.connect(
    ConnectionSettings(
      host: '127.0.0.1',
      port: 3306,
      user: 'root',
      password: '123456789',
      db: schemaName,
    ),
  );
  try {
    final results = await conn.query(
      'SELECT SUM(amount) AS total FROM invoices;',
    );
    return Response.json(
      body: {'total': results.isEmpty ? 0 : results.first[0]},
    );
  } finally {
    await conn.close();
  }
}

/// Same report, but the tenant code only ever selects a real schema name
/// out of the known table - a miss rejects rather than falling back to
/// the raw input.
Future<Response> _billingReportForValidatedTenant(String tenantCode) async {
  const knownSchemas = {
    'alpha': 'tenant_alpha',
    'beta': 'tenant_beta',
    'gamma': 'tenant_gamma',
  };
  final key = tenantCode.trim().toLowerCase();
  if (!knownSchemas.containsKey(key)) {
    return Response.json(statusCode: 400, body: {'error': 'unknown tenant'});
  }
  final schemaName = knownSchemas[key]!;
  // SAFE_SINK: PLANTED-Dart-HR-706-safe
  final conn = await MySqlConnection.connect(
    ConnectionSettings(
      host: '127.0.0.1',
      port: 3306,
      user: 'root',
      password: '123456789',
      db: schemaName,
    ),
  );
  try {
    final results = await conn.query(
      'SELECT SUM(amount) AS total FROM invoices;',
    );
    return Response.json(
      body: {'total': results.isEmpty ? 0 : results.first[0]},
    );
  } finally {
    await conn.close();
  }
}
