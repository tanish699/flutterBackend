import 'dart:io';
import 'dart:convert';

// ════════════════════════════════════════
// LAYER 1: MODEL — describes the data shape
// Analogy: The menu card item — just description, no logic
// ════════════════════════════════════════


class Post {
  final int id;
  final String title;
  final String body;
  final int userId;

  const Post({
    required this.id,
    required this.title,
    required this.body,
    required this.userId
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id:     json['id'],
    title:  json['title'],
    body:   json['body'],
    userId: json['userId'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 
    'title': title, 
    'body': body, 
    'userId': userId
  };

  @override
  String toString() => 'Post(#$id: "$title")';
}

// ════════════════════════════════════════
// LAYER 2: API SERVICE — raw HTTP calls only
// Analogy: The kitchen — it just cooks (raw HTTP), knows nothing about UI
// ════════════════════════════════════════
class PostApiService {
  final HttpClient _client = HttpClient();
  final String _base = 'https://jsonplaceholder.typicode.com';

  // Returns raw JSON Map — no business logic here
  Future<Map<String, dynamic>> getPostById(int id) async {
    var req = await _client.getUrl(Uri.parse('$_base/posts/$id'));
    var res = await req.close();
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    var body = await res.transform(utf8.decoder).join();
    return jsonDecode(body);
  }

  Future<List<dynamic>> getAllPosts({int limit = 10}) async {
    var uri = Uri.parse('$_base/posts')
      .replace(queryParameters: {'_limit': '$limit'});
    var req = await _client.getUrl(uri);
    var res = await req.close();
    var body = await res.transform(utf8.decoder).join();
    return jsonDecode(body);
  }

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> data) async {
    var req = await _client.postUrl(Uri.parse('$_base/posts'));
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode(data));
    var res = await req.close();
    var body = await res.transform(utf8.decoder).join();
    return jsonDecode(body);
  }

  void dispose() => _client.close();
}

// ════════════════════════════════════════
// LAYER 3: REPOSITORY — business logic + data conversion
// Analogy: The waiter — takes order, talks to kitchen, returns proper dish
// UI never talks to API directly — it goes through Repository
// ════════════════════════════════════════
class PostRepository {
  final PostApiService _api;
  
  PostRepository(this._api);

  // Returns proper Post models, not raw Maps
  Future<Post> getPost(int id) async {
    final json = await _api.getPostById(id);
    return Post.fromJson(json); // convert raw → model
  }

  Future<List<Post>> getPosts({int limit = 10}) async {
    final jsonList = await _api.getAllPosts(limit: limit);
    return jsonList.map((j) => Post.fromJson(j)).toList();
  }

  Future<Post> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    final json = await _api.createPost({
      'title':  title,
      'body':   body,
      'userId': userId,
    });
    return Post.fromJson(json);
  }
}

// ════════════════════════════════════════
// LAYER 4: UI / CONTROLLER — calls repository, shows data
// Analogy: The customer-facing counter — asks the waiter (repository),
// shows the result to the customer. NEVER touches the kitchen directly.
// ════════════════════════════════════════
class PostController {
  final PostRepository _repo;
  bool isLoading = false;
  String? error;
  List<Post> posts = [];

  PostController(this._repo);

  Future<void> loadPosts() async {
    isLoading = true;
    error = null;
    print('[UI] Loading...');

    try {
      posts = await _repo.getPosts(limit: 3);
      print('[UI] Loaded ${posts.length} posts');
      for (var p in posts) print('  $p');
    } catch (e) {
      error = 'Failed to load posts';
      print('[UI] Error: $error');
    } finally {
      isLoading = false;
    }
  }
}

// ════════════════════════════════════════
// WIRING IT ALL TOGETHER (Dependency Injection)
// Each layer only knows about the layer just below it
// ════════════════════════════════════════
void main() async {
  final api        = PostApiService();      // Layer 2: raw HTTP
  final repository = PostRepository(api);    // Layer 3: business logic
  final controller = PostController(repository); // Layer 4: UI state
  
  await controller.loadPosts(); // UI triggers → repo → api → server → back up

  api.dispose();
}