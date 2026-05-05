

import 'dart:io';
import 'dart:convert';
import 'dart:async';

// ── Model ────────────────────────────────────────────────────
class Post {
  final int id;
  final String title;
  Post({required this.id, required this.title});
  factory Post.fromJson(Map<String, dynamic> j) =>
      Post(id: j['id'], title: j['title']);
  @override
  String toString() => 'Post($id, "${title.length > 40 ? title.substring(0, 40) + "…" : title}")';
}

// ── HTTP helper ───────────────────────────────────────────────
Future<dynamic> httpGet(String url) async {
  final client = HttpClient();
  final req = await client.getUrl(Uri.parse(url));
  final res = await req.close();
  final body = jsonDecode(await res.transform(utf8.decoder).join());
  client.close();
  return body;
}

// ════════════════════════════════════════════════════════════
// PART 1 — CACHING
// Analogy: Shopkeeper remembers milk costs ₹60 — no need to
// call the supplier again until the price might have changed.
// ════════════════════════════════════════════════════════════
class Cache<T> {
  final Map<String, ({T value, DateTime savedAt})> _store = {};
  final Duration ttl;
  Cache({this.ttl = const Duration(minutes: 5)});

  void set(String key, T value) {
    _store[key] = (value: value, savedAt: DateTime.now());
    print('  [Cache]  saved "$key"');
  }

  T? get(String key) {
    final e = _store[key];
    if (e == null) { print('  [Cache] ❌ miss "$key"'); return null; }
    if (DateTime.now().difference(e.savedAt) > ttl) {
      _store.remove(key);
      print('  [Cache] ⏰ expired "$key"');
      return null;
    }
    print('  [Cache] ✅ hit "$key" — no network call!');
    return e.value;
  }
}

Future<void> demoCaching() async {
  print('\n━━━ PART 1: CACHING ━━━');
  // First call  → network. Same call again → instant from cache.
  final cache = Cache<Post>();

  Future<Post> getPost(int id) async {
    final key = 'post_$id';
    final hit = cache.get(key);
    if (hit != null) return hit;
    print('  [Net] 🌐 fetching post $id…');
    final post = Post.fromJson(await httpGet(
        'https://jsonplaceholder.typicode.com/posts/$id'));
    cache.set(key, post);
    return post;
  }

  print('\nFirst fetch (network):');
  print('  ${await getPost(1)}');
  print('\nSecond fetch (cache):');
  print('  ${await getPost(1)}');
  print('\nDifferent post (network):');
  print('  ${await getPost(2)}');
  print('\nSame post again (cache):');
  print('  ${await getPost(2)}');

  // Show expiry with 1-second TTL
  print('\nExpiry demo (TTL = 1s):');
  final c = Cache<String>(ttl: Duration(seconds: 1));
  c.set('x', 'hello');
  c.get('x');                                    // hit
  await Future.delayed(Duration(seconds: 2));
  c.get('x');                                    // expired
}

// ════════════════════════════════════════════════════════════
// PART 2 — PAGINATION
// Analogy: Read a newspaper page by page — not the whole
// archive at once. Load 4 posts, then next 4 on scroll.
// ════════════════════════════════════════════════════════════
class Paginator {
  final int pageSize;
  int _page = 1;
  bool hasMore = true;
  final List<Post> posts = [];
  Paginator({this.pageSize = 4});

  // _start = offset (where to begin), _limit = how many per page
  // Page1: _start=0 _limit=4 → posts 1-4
  // Page2: _start=4 _limit=4 → posts 5-8
  Future<List<Post>> loadNext() async {
    if (!hasMore) { 
      print('  [Page] no more pages'); return []; 
    }

    final offset = (_page - 1) * pageSize;
    final url = 'https://jsonplaceholder.typicode.com/posts?_start=$offset&_limit=$pageSize';

    final items = (await httpGet(url) as List).map((j) => Post.fromJson(j)).toList();
    
    if (items.length < pageSize) hasMore = false;
    posts.addAll(items);
    _page++;
    
    print('  [Page] ✅ loaded ${items.length} (total: ${posts.length})');
    
    return items;
  }
}

Future<void> demoPagination() async {
  print('\n━━━ PART 2: PAGINATION ━━━');
  final p = Paginator(pageSize: 4);

  print('\nPage 1 (user opens app):');
  for (final p in await p.loadNext()) print('  $p');

  print('\nPage 2 (user scrolls down):');
  for (final p in await p.loadNext()) print('  $p');

  print('\nPage 3 (user scrolls again):');
  for (final p in await p.loadNext()) print('  $p');

  print('\nTotal in memory: ${p.posts.length}, hasMore: ${p.hasMore}');
}

// ════════════════════════════════════════════════════════════
// PART 3 — DEBOUNCING
// Analogy: Your assistant waits until you stop shouting your
// order before calling the restaurant — not after every word.
// Every keystroke resets the timer. API fires only once.
// ════════════════════════════════════════════════════════════
class Debouncer {
  final Duration wait;
  Timer? _t;
  Debouncer({this.wait = const Duration(milliseconds: 500)});

  void run(void Function() fn) {
    if (_t?.isActive ?? false) {
      _t!.cancel();
      print('  [Deb] ✋ cancelled (new input)');
    }
    print('  [Deb] ⏳ waiting ${wait.inMilliseconds}ms…');
    _t = Timer(wait, () {
      print('  [Deb] 🔥 firing!');
      fn();
    });
  }

  void dispose() => _t?.cancel();
}

Future<void> search(String q) async {
  print('  [API] searching "$q"');
  await httpGet('https://jsonplaceholder.typicode.com/posts?_limit=2');
  print('  [API] done for "$q"');
}

Future<void> demoDebouncing() async {
  print('\n━━━ PART 3: DEBOUNCING ━━━');
  print('User types "dart" (100ms/key) — only last call should fire:\n');

  final d = Debouncer(wait: Duration(milliseconds: 500));

  // Rapid keystrokes — only "dart" should reach the API
  for (final q in ['d', 'da', 'dar', 'dart']) {
    d.run(() => search(q));
    await Future.delayed(Duration(milliseconds: 100));
  }
  print('\n  [user stops typing — waiting 600ms]');
  await Future.delayed(Duration(milliseconds: 600)); // dart fires here

  print('\nUser types "flutter":\n');
  for (final q in ['f', 'fl', 'flu', 'flut', 'flutt', 'flutter']) {
    d.run(() => search(q));
    await Future.delayed(Duration(milliseconds: 80));
  }
  print('\n  [user stops typing — waiting 600ms]');
  await Future.delayed(Duration(milliseconds: 600)); // flutter fires here

  d.dispose();
}

// ── Main ─────────────────────────────────────────────────────
void main() async {
  

  await demoCaching();
  await demoPagination();
  await demoDebouncing();

  print('\n━━━ Summary ━━━');
  print('Caching    → reuse saved responses, skip network');
  print('Pagination → load in chunks (4 at a time)');
  print('Debouncing → wait for user to stop typing, then call once');

  print('\n📌 Try it yourself:');
  print('  1. Change pageSize to 2');
  print('  2. Change cache TTL to Duration(seconds: 3)');
  print('  3. Change debounce wait to 200ms');
}