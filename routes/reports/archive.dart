import 'package:dart_frog/dart_frog.dart';
import 'package:frogging/reporting/report_archiver.dart';

/// Archives a generated report bundle to disk. Operators can choose which
/// compression utility runs the archive step for this request - the default
/// is `gzip`, but deployments that only ship `zip` or the BSD `tar` can point
/// the endpoint at the tool they have installed.
Future<Response> onRequest(RequestContext context) async {
  final params = context.request.uri.queryParameters;
  //CWE-78
  //SOURCE
  final compressor = params['compressor'] ?? 'gzip';
  final reportName = params['report'] ?? 'daily-summary';

  final archiver = ReportArchiver();
  final archivedPath = await archiver.archiveReport(reportName, compressor);
  return Response.json(body: {'archived': archivedPath});
}
