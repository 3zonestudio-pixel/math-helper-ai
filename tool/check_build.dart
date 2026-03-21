import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  final token = args.isNotEmpty ? args[0] : '';
  final c = HttpClient();
  try {
    // Get latest runs
    var r = await c.getUrl(Uri.parse(
        'https://api.github.com/repos/3zonestudio-pixel/math-helper-ai/actions/runs?per_page=5'));
    r.headers.set('Authorization', 'Bearer $token');
    r.headers.set('Accept', 'application/vnd.github+json');
    var resp = await r.close();
    var body = await resp.transform(utf8.decoder).join();
    var j = jsonDecode(body);
    var run;
    for (var wr in j['workflow_runs']) {
      print('Run ${wr['id']}: status=${wr['status']} conclusion=${wr['conclusion']} created=${wr['created_at']}');
      if (wr['conclusion'] == 'failure' && run == null) run = wr;
    }
    if (run == null) {
      print('\nNo failed runs found in recent history.');
      return;
    }
    print('\n--- Inspecting failed run ${run['id']} ---');

    if (run['conclusion'] == 'failure') {
      // Get jobs
      r = await c.getUrl(Uri.parse(
          'https://api.github.com/repos/3zonestudio-pixel/math-helper-ai/actions/runs/${run['id']}/jobs'));
      r.headers.set('Authorization', 'Bearer $token');
      r.headers.set('Accept', 'application/vnd.github+json');
      resp = await r.close();
      body = await resp.transform(utf8.decoder).join();
      j = jsonDecode(body);
      for (var job in j['jobs']) {
        print('\nJob: ${job['name']} - ${job['conclusion']}');
        for (var step in job['steps']) {
          if (step['conclusion'] == 'failure') {
            print('  FAILED Step: ${step['name']}');
          }
        }
        // Get logs
        if (job['conclusion'] == 'failure') {
          r = await c.getUrl(Uri.parse(
              'https://api.github.com/repos/3zonestudio-pixel/math-helper-ai/actions/jobs/${job['id']}/logs'));
          r.headers.set('Authorization', 'Bearer $token');
          r.headers.set('Accept', 'application/vnd.github+json');
          resp = await r.close();
          if (resp.statusCode == 302) {
            final loc = resp.headers.value('location');
            if (loc != null) {
              r = await c.getUrl(Uri.parse(loc));
              resp = await r.close();
            }
          }
          body = await resp.transform(utf8.decoder).join();
          // Print last 150 lines
          final lines = body.split('\n');
          final start = lines.length > 150 ? lines.length - 150 : 0;
          print('\n--- Last 150 lines of failed job log ---');
          for (var i = start; i < lines.length; i++) {
            print(lines[i]);
          }
        }
      }
    }
  } finally {
    c.close();
  }
}
