import 'dart:io';
import 'dart:convert';

/*.  
Status Codes:-
  2xx  Success[
    200 OK, 201 Created, 204 No Content
  ]
  
  3xx Redirect [
    301 Moved, 304 Not Modified
  ]

  4xx Client error [
    400 Bad Request, 401 Unauth, 404 Not Found
  ]

  5xx Server error [
    500 Internal, 503 Service Unavailable  
  ]
   
*/

// ── Step 1: Create a MODEL class
// Analogy: A "Post" model is like a printed form template.
// Every response fills in one of these forms neatly.
class Post {
  final int id;
  final String title;
  final String body;
  final int userId;

  Post({
    required this.id,
    required this.title,
    required this.body,
    required this.userId,
  });

  // Factory: converts a raw Map (from JSON) into a Post object
  // Analogy: A clerk who reads a raw handwritten form and types it into the system
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id:     json['id'],
      title:  json['title'],
      body:   json['body'],
      userId: json['userId'],
    );
  }

  // Convert Post back to Map (to send as JSON)
  Map<String, dynamic> toJson() => {                      //Used when sending data to API
    'id':     id,
    'title':  title,
    'body':   body,
    'userId': userId, 
  };

  @override
  String toString() => 'Post(id: $id, title: "$title")';    //Controls how object prints
}

void main() async {
  final client = HttpClient();

  // ── Fetch a single post and parse it
  var req = await client.getUrl(
    Uri.parse('https://jsonplaceholder.typicode.com/posts/1')
  );
  var res = await req.close();

  // ── Always check status code FIRST
  if (res.statusCode == 200) {
    var bodyStr = await res.transform(utf8.decoder).join();
    
    // JSON string → Dart Map → Post model
    Map<String, dynamic> rawJson = jsonDecode(bodyStr);
    Post post = Post.fromJson(rawJson);
    
    print('Got post: $post');
    print('Title: ${post.title}');
    print('User: ${post.userId}');
  } else {
    print('Error! Status: ${res.statusCode}');
  }

  // ── Fetch a LIST of posts
  var req2 = await client.getUrl(
    Uri.parse('https://jsonplaceholder.typicode.com/posts')
      .replace(queryParameters: {'_limit': '3'})                    //Adds query param → only 3 posts  
  );
  var res2 = await req2.close();

  if (res2.statusCode == 200) {
    var bodyStr = await res2.transform(utf8.decoder).join();
    
    // JSON array → List of Post models
    List<dynamic> rawList = jsonDecode(bodyStr);
    List<Post> posts = rawList.map((item) => Post.fromJson(item)).toList();
    
    print('\nAll posts:');
    for (var p in posts) {
      print('  - $p');
    }
  }

  client.close();
}