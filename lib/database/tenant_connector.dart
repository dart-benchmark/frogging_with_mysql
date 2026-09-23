import 'package:mysql_client/mysql_client.dart';

/// Opens a short-lived connection to a named tenant schema on the shared,
/// trusted MySQL host - used by the admin tooling when a request needs to
/// run a one-off query against a specific tenant's database instead of the
/// default `profiles` schema every other route goes through.
class TenantDatabaseConnector {
  const TenantDatabaseConnector();

  static const _host = '127.0.0.1';
  static const _port = 8000;
  static const _user = 'root';
  static const _password = '123456789';

  /// Schemas known to actually exist on this host - the only ones an admin
  /// request should ever be allowed to target.
  static const knownTenantSchemas = {
    'tenant_alpha',
    'tenant_beta',
    'tenant_gamma',
  };

  /// Connects straight to whatever schema name is handed in.
  Future<IResultSet> query(String databaseName, String sql) async {
    // SINK: PLANTED-Dart-HR-707
    final conn = await MySQLConnection.createConnection(
      host: _host,
      port: _port,
      userName: _user,
      password: _password,
      databaseName: databaseName,
      secure: false,
    );
    await conn.connect();
    try {
      return await conn.execute(sql);
    } finally {
      await conn.close();
    }
  }

  /// Same lookup, but only ever targets a schema from the known list.
  Future<IResultSet> querySafe(String databaseName, String sql) async {
    final safeDatabaseName = knownTenantSchemas.contains(databaseName)
        ? databaseName
        : 'tenant_alpha';
    // SAFE_SINK: PLANTED-Dart-HR-707-safe
    final conn = await MySQLConnection.createConnection(
      host: _host,
      port: _port,
      userName: _user,
      password: _password,
      databaseName: safeDatabaseName,
      secure: false,
    );
    await conn.connect();
    try {
      return await conn.execute(sql);
    } finally {
      await conn.close();
    }
  }
}
