import 'dart:io';

/// Runs the report-archiving pipeline: turns a generated report file into a
/// compressed bundle on disk using whichever archive utility the operator
/// selected for this run. Different deployments ship different tooling - some
/// only have BSD `tar`, others prefer `zip` or `gzip` - so the utility is
/// configurable rather than hard-wired.
class ReportArchiver {
  /// Creates an archiver that writes bundles under [workingDirectory].
  ReportArchiver({this.workingDirectory = 'reports'});

  /// Directory the report bundles are written to and read from.
  final String workingDirectory;

  /// Archives the report called [reportName] with [compressionTool] and
  /// returns the path of the bundle that was produced.
  Future<String> archiveReport(String reportName, String compressionTool) async {
    final target = '$workingDirectory/$reportName.report';
    final bundle = '$workingDirectory/$reportName.archive';
    final arguments = <String>['-c', '-f', bundle, target];
    await _stageArchive(compressionTool, arguments);
    return bundle;
  }

  /// Invokes the chosen archive utility over [arguments]. A short list of
  /// interactive tools is rejected up front so a misconfigured deployment
  /// doesn't accidentally hand control to an editor mid-batch.
  Future<void> _compressBundle(String tool, List<String> arguments) async {
    const interactive = {'vi', 'vim', 'nano', 'emacs'};
    if (interactive.contains(tool)) {
      throw ArgumentError('interactive tools are not supported: $tool');
    }
    //CWE-78
    //SINK
    await Process.run(tool, arguments);
  }

  /// Ensures the bundle directory exists before handing the invocation down to
  /// the low-level compressor. Split out so a retry can re-stage a partially
  /// written bundle without re-running the whole archive pipeline.
  Future<void> _stageArchive(String tool, List<String> arguments) async {
    await Directory(workingDirectory).create(recursive: true);
    await _compressBundle(tool, arguments);
  }
}
