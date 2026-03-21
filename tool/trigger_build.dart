import 'dart:io';
import 'dart:convert';

/// Trigger a GitHub Actions build.
/// Usage: dart run tool/trigger_build.dart <GITHUB_PAT>
void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run tool/trigger_build.dart <GITHUB_PAT>');
    exit(1);
  }
  final token = args[0];
  final client = HttpClient();
  try {
    final req = await client.postUrl(Uri.parse(
        'https://api.github.com/repos/3zonestudio-pixel/math-helper-ai/actions/workflows/build.yml/dispatches'));
    req.headers.set('Authorization', 'Bearer $token');
    req.headers.set('Accept', 'application/vnd.github+json');
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'ref': 'master'}));
    final resp = await req.close();
    print('Build triggered! Status: ${resp.statusCode}');
  } finally {
    client.close();
  }
}
