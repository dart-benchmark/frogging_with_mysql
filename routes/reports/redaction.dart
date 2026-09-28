import 'package:dart_frog/dart_frog.dart';
import 'package:frogging/source/data_source.dart';

/// Applies an operator-supplied redaction rule to the standard report banner
/// before it is embedded in an exported report. The rule is a regular
/// expression so operators can strip whichever boilerplate line they don't
/// want to appear in a given export.
Future<Response> onRequest(RequestContext context) async {
  final params = context.request.uri.queryParameters;
  //CWE-1333
  //SOURCE
  final rule = params['rule'] ?? '';
  final dataSource = context.read<DataSource>();
  final redacted = dataSource.redactReportBanner(rule);
  return Response.json(body: {'banner': redacted});
}
