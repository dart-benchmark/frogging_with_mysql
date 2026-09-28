import 'package:dart_frog/dart_frog.dart';
import 'package:frogging/database/sql_client.dart';
import 'package:frogging/reporting/report_strategy.dart';

/// Admin reports summary - some older internal tools still call this with
/// `x-report-engine: legacy` to keep using the pre-migration mysql1 path.
Future<Response> onRequest(RequestContext context) async {
  final category = context.request.uri.queryParameters['category'] ?? '';
  final engine = context.request.headers['x-report-engine'];

  final ReportStrategy strategy;
  if (engine == 'legacy') {
    strategy = const LegacyMysql1ReportStrategy();
  } else if (engine == 'audit') {
    strategy = const AuditMysql1ReportStrategy();
  } else {
    strategy = ParameterizedReportStrategy(context.read<MySQLClient>());
  }

  final rows = await strategy.generate(category);
  return Response.json(body: rows);
}
