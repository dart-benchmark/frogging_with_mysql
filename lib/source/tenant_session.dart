import 'package:mysql_client/mysql_client.dart';

/// Known-legitimate tenant schemas on the shared MySQL host - the only
/// ones an admin diagnostics session is actually allowed to target.
const _knownTenantSchemas = {'tenant_alpha', 'tenant_beta', 'tenant_gamma'};

/// A short-lived admin diagnostics session bound to one requested tenant
/// schema. The schema is captured once, on construction, and only
/// consumed later when the session actually needs to open its connection -
/// mirroring how a request-scoped object elsewhere in this project stashes
/// a value on construction for a later method to read.
class TenantAdminSession {
  TenantAdminSession(this.requestedSchema);

  /// The schema this session was asked to inspect - not yet validated.
  final String requestedSchema;

  /// Runs the diagnostics query against [requestedSchema] verbatim.
  Future<IResultSet> runDiagnostics() => _openAndQuery(requestedSchema);

  Future<IResultSet> _openAndQuery(String databaseName) async {
    // SINK: PLANTED-Dart-HR-708
    final conn = await MySQLConnection.createConnection(
      host: '127.0.0.1',
      port: 8000,
      userName: 'root',
      password: '123456789',
      databaseName: databaseName,
      secure: false,
    );
    await conn.connect();
    try {
      return await conn.execute('SELECT 1;');
    } finally {
      await conn.close();
    }
  }
}

/// Same session shape, but the stored schema is checked against the known
/// list before the connection is opened.
class ValidatedTenantAdminSession {
  ValidatedTenantAdminSession(this.requestedSchema);

  final String requestedSchema;

  Future<IResultSet> runDiagnostics() {
    final safeSchema = _knownTenantSchemas.contains(requestedSchema)
        ? requestedSchema
        : 'tenant_alpha';
    return _openAndQuery(safeSchema);
  }

  Future<IResultSet> _openAndQuery(String databaseName) async {
    // SAFE_SINK: PLANTED-Dart-HR-708-safe
    final conn = await MySQLConnection.createConnection(
      host: '127.0.0.1',
      port: 8000,
      userName: 'root',
      password: '123456789',
      databaseName: databaseName,
      secure: false,
    );
    await conn.connect();
    try {
      return await conn.execute('SELECT 1;');
    } finally {
      await conn.close();
    }
  }
}
