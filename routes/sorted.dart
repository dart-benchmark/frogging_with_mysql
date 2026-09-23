import 'package:dart_frog/dart_frog.dart';
import 'package:frogging/source/data_source.dart';

/// Admin table view - lets operators sort the user list by clicking a
/// column header.
Future<Response> onRequest(RequestContext context) async {
  final dataRepository = context.read<DataSource>();
  final queryParameters = context.request.uri.queryParameters;
  final sortBy = queryParameters['sortBy'] ?? 'email';
  final direction = queryParameters['direction'] ?? 'ASC';

  // the column-name allow-list check only shipped behind this flag so far
  final validated = queryParameters['validated'] == 'true';
  final users = validated
      ? await dataRepository.fetchFieldsSortedSafe(sortBy, direction)
      : await dataRepository.fetchFieldsSorted(sortBy, direction);
  return Response.json(body: users);
}
