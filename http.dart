import 'dart:io';
import 'dart:convert';

// We use this free test API:  https://jsonplaceholder.typicode.com

void main() async {
  final client = HttpClient();





  // ── GET: "Give me post #1"
  // Analogy: Asking the librarian for book #1 → they hand it to you
  var req = await client.getUrl(                               // client.getUrl() → prepares a GET request
    Uri.parse('https://jsonplaceholder.typicode.com/posts/1')  // Uri.parse(...) → converts string to URL object
  );
  var res = await req.close();                                 // Sends request to server
  var body = await res.transform(utf8.decoder).join();         // utf8.decoder → converts bytes → text; .join() → combines chunks into full string
  print('GET → ${res.statusCode}');                            // Prints status code (e.g., 200)
  print(body);                                                 // Prints actual response JSON






  // ── POST: "Create a new post"
  // Analogy: Filling a form and submitting it at a counter
  var req2 = await client.postUrl(
    Uri.parse('https://jsonplaceholder.typicode.com/posts')       // Preparing request to: “Create a new post”
  );
  req2.headers.contentType = ContentType.json;                    //    Sets header

  req2.write(jsonEncode({                                         //
    'title': 'My First Post',                                     // Payload
    'body':  'Hello API world!',                                  //
    'userId': 1,
  }));
  var res2 = await req2.close();
  print('\nPOST → ${res2.statusCode}'); // 201 Created






  // ── PUT: "Replace post #1 entirely"
  // Analogy: Throwing away an old form and submitting a brand new one
  var req3 = await client.putUrl(
    Uri.parse('https://jsonplaceholder.typicode.com/posts/1')           // “Update post #1 completely”
  );
  req3.headers.contentType = ContentType.json;                          // Same as POST → sending JSON
  req3.write(jsonEncode({
    'id': 1,
    'title': 'Updated Title',
    'body': 'New full body text',
    'userId': 1,
  }));
  var res3 = await req3.close();                                        // Sends update request
  print('\nPUT → ${res3.statusCode}');                                  // Usually 200 or 204






  // ── DELETE: "Remove post #1"
  // Analogy: Telling the librarian to throw away book #1
  var req4 = await client.deleteUrl(
    Uri.parse('https://jsonplaceholder.typicode.com/posts/1')
  );
  var res4 = await req4.close();
  print('\nDELETE → ${res4.statusCode}'); // 200 OK

  client.close();                          //    loses network connection, Frees memory/resources
}