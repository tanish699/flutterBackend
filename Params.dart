import 'dart:io';
import 'dart:convert';

void main() async {
  final client = HttpClient();

  // ── 1. QUERY PARAMS (for GET — filter/search)
  // Analogy: Searching on Google — the ?q=dart is a query param
  // URL becomes: /posts?userId=1&_limit=3
  final uri = Uri.parse('https://jsonplaceholder.typicode.com/posts')
    .replace(queryParameters: {
      'userId': '1',   // filter posts by user 1
      '_limit': '3',   // only return 3 results
    });

  print('URL with params: $uri');
  var req = await client.getUrl(uri);
  var res = await req.close();
  var body = await res.transform(utf8.decoder).join();
  print('Posts for user 1 (max 3): $body\n');






  // ── 2. BODY (for POST/PUT — sending real data)
  // Analogy: The actual content inside the letter envelope
  var req2 = await client.postUrl(
    Uri.parse('https://jsonplaceholder.typicode.com/posts')
  );






  // ── 3. HEADERS (metadata about the request)
  // Analogy: The customs/shipping label on the package
  req2.headers.set('Content-Type', 'application/json'); // "I'm sending JSON"
  req2.headers.set('Accept', 'application/json');        // "I want JSON back"
  req2.headers.set('X-Custom-Header', 'my-app-v1');     // custom info

  // Sending the actual body (JSON encoded)
  req2.write(jsonEncode({
    'title': 'Learning APIs',
    'body': 'This is the payload in the body',
    'userId': 1,
  }));

  var res2 = await req2.close();
  var body2 = await res2.transform(utf8.decoder).join();
  print('Created: $body2');

  client.close();



}