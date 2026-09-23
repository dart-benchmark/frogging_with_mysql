import 'package:mysql_client/mysql_client.dart';

/// Strategy for opening a connection to a caller-named tenant schema -
/// which concrete implementation runs depends on which client integration
/// asked for it (see routes/admin/tenant_selector.dart), mirroring how
/// this project already picks between two report backends by header.
abstract class TenantDatabaseSelector {
  Future<IResultSet> query(String requestedSchema, String sql);
}

/// Connects straight to whatever schema name is handed in - kept around
/// for older internal tooling that hasn't been migrated to the
/// allowlisted selector yet.
class DirectTenantDatabaseSelector implements TenantDatabaseSelector {
  const DirectTenantDatabaseSelector();

  @override
  Future<IResultSet> query(String requestedSchema, String sql) async {
    // SINK: PLANTED-Dart-HR-709
    final conn = await MySQLConnection.createConnection(
      host: '127.0.0.1',
      port: 8000,
      userName: 'root',
      password: '123456789',
      databaseName: requestedSchema,
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

/// The current backend - every new admin tool should be built against
/// this one. Only ever targets a schema from the known list.
class AllowlistedTenantDatabaseSelector implements TenantDatabaseSelector {
  const AllowlistedTenantDatabaseSelector();

  static const _allowedSchemas = {
    'tenant_alpha',
    'tenant_beta',
    'tenant_gamma',
  };

  @override
  Future<IResultSet> query(String requestedSchema, String sql) async {
    final safeSchema = _allowedSchemas.contains(requestedSchema)
        ? requestedSchema
        : 'tenant_alpha';
    // SAFE_SINK: PLANTED-Dart-HR-709-safe
    final conn = await MySQLConnection.createConnection(
      host: '127.0.0.1',
      port: 8000,
      userName: 'root',
      password: '123456789',
      databaseName: safeSchema,
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
