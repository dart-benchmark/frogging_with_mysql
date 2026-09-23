import 'package:dart_frog/dart_frog.dart';
import 'package:frogging/source/data_source.dart';

/// Lets the admin dashboard search users by a partial email match.
Future<Response> onRequest(RequestContext context) async {
  final dataRepository = context.read<DataSource>();
  final queryParameters = context.request.uri.queryParameters;

  // the parameterized form - rolled out first for the "safe" query param
  final safePattern = queryParameters['emailLikeSafe'];
  if (safePattern != null) {
    final users = await dataRepository.searchByEmailPatternSafe(safePattern);
    return Response.json(body: users);
  }

  // the original "contains" search - still concatenates the pattern
  final pattern = queryParameters['emailLike'] ?? '';
  final users = await dataRepository.searchByEmailPattern(pattern);
  return Response.json(body: users);
}
