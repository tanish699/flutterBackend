// pubspec.yaml:
// dependencies:
//   http: ^1.2.0

import 'http/http.dart' as http;
import 'dart:convert';

void main() async {
  // ── GET is super simple
  final response = await http.get(
    Uri.parse('https://jsonplaceholder.typicode.com/posts/1'),
  );

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    print('Title: ${data['title']}');
  }

  // ── POST with headers and body
  final response2 = await http.post(
    Uri.parse('https://jsonplaceholder.typicode.com/posts'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'title': 'New Post',
      'body':  'Content here',
      'userId': 1,
    }),
  );
  print('Created: ${response2.statusCode}');
  
  // ── PATCH (partial update)
  final response3 = await http.patch(
    Uri.parse('https://jsonplaceholder.typicode.com/posts/1'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'title': 'Updated title only'}),
  );
  print('Patched: ${response3.statusCode}');

  // ── DELETE
  final response4 = await http.delete(
    Uri.parse('https://jsonplaceholder.typicode.com/posts/1'),
  );
  print('Deleted: ${response4.statusCode}');
}