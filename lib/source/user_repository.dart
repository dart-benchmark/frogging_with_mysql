import 'package:frogging/database/model.dart';
import 'package:frogging/database/sql_client.dart';

/// Thin repository layer in front of [MySQLClient] for user-lookup
/// features that don't map cleanly onto [DataSource]'s simple table scan.
class UserRepository {
  /// The token is stashed on construction and only consumed once a
  /// lookup method actually needs to build the query.
  UserRepository(this._sqlClient, this._recoveryToken);

  final MySQLClient _sqlClient;
  final String _recoveryToken;

  /// Resolves the account tied to a legacy account-recovery token. Some
  /// older client integrations still send the user's own email back as
  /// the "token".
  Future<List<DatabaseModel>> resolve() => _lookupUnsafe();

  /// Same resolution, but bound as a named parameter instead of being
  /// spliced into the query text.
  Future<List<DatabaseModel>> resolveSafe() => _lookupSafe();

  Future<List<DatabaseModel>> _lookupUnsafe() async {
    final condition = "email = '$_recoveryToken'";
    final sqlQuery = 'SELECT email, password FROM users WHERE $condition;';
    // SINK: PLANTED-Dart-HR-8
    final result = await _sqlClient.execute(sqlQuery);
    return _toUsers(result.rows);
  }

  Future<List<DatabaseModel>> _lookupSafe() async {
    const sqlQuery =
        'SELECT email, password FROM users WHERE email = :token;';
    // SAFE_SINK: PLANTED-Dart-HR-8-safe
    final result = await _sqlClient.execute(
      sqlQuery,
      params: {'token': _recoveryToken},
    );
    return _toUsers(result.rows);
  }

  List<DatabaseModel> _toUsers(Iterable<dynamic> rows) {
    final users = <DatabaseModel>[];
    for (final row in rows) {
      final assoc = row.assoc() as Map<String, String?>;
      users.add(DatabaseModel.fromRowAssoc(assoc));
    }
    return users;
  }
}
