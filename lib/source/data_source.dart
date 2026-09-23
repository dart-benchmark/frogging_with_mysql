import 'package:frogging/database/model.dart';
import 'package:frogging/database/sql_client.dart';

/// data source form MySQL

class DataSource {
  /// initializing
  const DataSource(
    this.sqlClient,
  );

  ///Fetches all table fields from users table in our database
  Future<List<DatabaseModel>> fetchFields() async {
    // sqlQuey
    const sqlQuery = 'SELECT email, password FROM users;';
    // executing our sqlQuery
    final result = await sqlClient.execute(sqlQuery);
    // a list to save our users from the table -
    // i mean whatever as many as user we get from table

    final users = <DatabaseModel>[];
    for (final row in result.rows) {
      users.add(DatabaseModel.fromRowAssoc(row.assoc()));
    }
    // simply returning the whatever the the users
    // we will get from the MySQL database
    return users;
  }

  /// Searches users whose email matches a partial pattern - backs the
  /// admin dashboard's "contains" search box.
  Future<List<DatabaseModel>> searchByEmailPattern(String pattern) async {
    var sqlQuery = 'SELECT email, password FROM users WHERE email LIKE ';
    sqlQuery += "'%" + pattern + "%'";
    sqlQuery += ';';
    // SINK: PLANTED-Dart-HR-7
    final result = await sqlClient.execute(sqlQuery);
    final users = <DatabaseModel>[];
    for (final row in result.rows) {
      users.add(DatabaseModel.fromRowAssoc(row.assoc()));
    }
    return users;
  }

  /// Same search, but the pattern is bound through the parameterized form
  /// instead of being concatenated into the query text.
  Future<List<DatabaseModel>> searchByEmailPatternSafe(String pattern) async {
    const sqlQuery =
        'SELECT email, password FROM users WHERE email LIKE :pattern;';
    // SAFE_SINK: PLANTED-Dart-HR-7-safe
    final result = await sqlClient.execute(
      sqlQuery,
      params: {'pattern': '%$pattern%'},
    );
    final users = <DatabaseModel>[];
    for (final row in result.rows) {
      users.add(DatabaseModel.fromRowAssoc(row.assoc()));
    }
    return users;
  }

  // the only two real columns on this table - checked below so it's
  // always safe to splice a validated value in
  static const _sortableColumns = {'email', 'password'};

  /// Returns every user sorted by a caller-chosen column/direction - used
  /// by the admin table view so operators can click a column header to
  /// sort by it.
  Future<List<DatabaseModel>> fetchFieldsSorted(
    String sortBy,
    String direction,
  ) async {
    // only ASC/DESC are legal SQL here, so this half is safe to leave as-is
    final safeDirection = direction.toUpperCase() == 'DESC' ? 'DESC' : 'ASC';
    // sortBy is a column name, which can't be bound as a query parameter -
    // TODO: validate this against the known column list before release
    final sqlQuery =
        'SELECT email, password FROM users ORDER BY $sortBy $safeDirection;';
    // SINK: PLANTED-Dart-HR-10
    final result = await sqlClient.execute(sqlQuery);
    final users = <DatabaseModel>[];
    for (final row in result.rows) {
      users.add(DatabaseModel.fromRowAssoc(row.assoc()));
    }
    return users;
  }

  /// Same sorted listing, but the column name is checked against the
  /// table's real columns before it's spliced into the query text.
  Future<List<DatabaseModel>> fetchFieldsSortedSafe(
    String sortBy,
    String direction,
  ) async {
    final safeDirection = direction.toUpperCase() == 'DESC' ? 'DESC' : 'ASC';
    final safeSortBy =
        _sortableColumns.contains(sortBy) ? sortBy : 'email';
    final sqlQuery = 'SELECT email, password FROM users '
        'ORDER BY $safeSortBy $safeDirection;';
    // SAFE_SINK: PLANTED-Dart-HR-10-safe
    final result = await sqlClient.execute(sqlQuery);
    final users = <DatabaseModel>[];
    for (final row in result.rows) {
      users.add(DatabaseModel.fromRowAssoc(row.assoc()));
    }
    return users;
  }

  /// accessing you client
  final MySQLClient sqlClient;
}
