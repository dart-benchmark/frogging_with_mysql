import 'package:frogging/database/sql_client.dart';
import 'package:mysql1/mysql1.dart';

/// A single row of the reports summary - one count per category.
class ReportRow {
  const ReportRow(this.category, this.total);

  final String category;
  final int total;

  Map<String, dynamic> toJson() => {'category': category, 'total': total};
}

/// Strategy for generating the admin "reports summary" - which backend
/// actually runs the query depends on which client integration asked for
/// it (see routes/reports/summary.dart).
abstract class ReportStrategy {
  Future<List<ReportRow>> generate(String category);
}

/// Talks to MySQL through the legacy `mysql1` driver - kept around for the
/// handful of older admin dashboards that were built against it before the
/// rest of the project switched to `mysql_client`.
class LegacyMysql1ReportStrategy implements ReportStrategy {
  const LegacyMysql1ReportStrategy();

  @override
  Future<List<ReportRow>> generate(String category) async {
    final conn = await MySqlConnection.connect(
      ConnectionSettings(
        host: '127.0.0.1',
        port: 3306,
        user: 'root',
        password: '123456789',
        db: 'profiles',
      ),
    );
    try {
      final sqlQuery = 'SELECT category, count(*) AS total '
          'FROM reports '
          "WHERE category = '$category' "
          'GROUP BY category;';
      // SINK: PLANTED-Dart-HR-9
      final results = await conn.query(sqlQuery);
      return [
        for (final row in results)
          ReportRow(row[0] as String, row[1] as int),
      ];
    } finally {
      await conn.close();
    }
  }
}

/// The current, parameterized backend - every new report should be built
/// against this one.
class ParameterizedReportStrategy implements ReportStrategy {
  const ParameterizedReportStrategy(this._sqlClient);

  final MySQLClient _sqlClient;

  @override
  Future<List<ReportRow>> generate(String category) async {
    const sqlQuery = 'SELECT category, count(*) AS total '
        'FROM reports '
        'WHERE category = :category '
        'GROUP BY category;';
    // SAFE_SINK: PLANTED-Dart-HR-9-safe
    final result = await _sqlClient.execute(
      sqlQuery,
      params: {'category': category},
    );
    return [
      for (final row in result.rows)
        ReportRow(
          row.assoc()['category'] ?? '',
          int.tryParse(row.assoc()['total'] ?? '0') ?? 0,
        ),
    ];
  }
}
