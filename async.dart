import 'dart:io';
import 'dart:convert';

// Future<String> means: "I promise to give you a String... eventually"
// Like a token at a restaurant — you'll get your food, just wait.
Future<String> fetchUserName(int id) async {
  final client = HttpClient();
  
  var req = await client.getUrl(
    Uri.parse('https://jsonplaceholder.typicode.com/users/$id')
  );
  var res = await req.close();
  var body = await res.transform(utf8.decoder).join();
  client.close();
  
  Map<String, dynamic> user = jsonDecode(body);
  return user['name']; // returns the name after waiting for the response
}

void main() async {
  print('1. Starting program...');
  
  // await = "pause HERE and wait for the promise to be fulfilled"
  // Without await, the next line would run before we get the response!
  String name = await fetchUserName(1);
  
  print('2. Got user: $name');
  print('3. Program continues...');
  
  // ── Running multiple requests in PARALLEL (faster!)
  // Analogy: Ordering tea AND food at the same time instead of waiting
  // for tea before ordering food.
  print('\nFetching 3 users in parallel...');
  
  List<Future<String>> futures = [
    fetchUserName(1),
    fetchUserName(2),
    fetchUserName(3),
  ];
  
  // Future.wait runs them all at once and waits for ALL to finish
  List<String> names = await Future.wait(futures);
  print('Users: $names');
}


// In real apps (Flutter), you track 3 states: loading, success, error.
// This pattern works for any data-fetching scenario.

enum LoadingState { idle, loading, success, error }

class DataFetcher {
  LoadingState state = LoadingState.idle;
  String? data;
  String? errorMessage;

  Future<void> fetchData() async {
    // 1. Set loading state (show spinner in UI)
    state = LoadingState.loading;
    print('[UI] Showing loading spinner...');

    try {
      // 2. Do the async work
      final client = HttpClient();
      var req = await client.getUrl(
        Uri.parse('https://jsonplaceholder.typicode.com/posts/1')
      );
      var res = await req.close();
      data = await res.transform(utf8.decoder).join();
      client.close();

      // 3. Success state (show data)
      state = LoadingState.success;
      print('[UI] Showing data! $data');

    } catch (e) {
      // 4. Error state (show error message)
      state = LoadingState.error;
      errorMessage = e.toString();
      print('[UI] Showing error: $errorMessage');
    }
  }
}

void main2() async {
  var fetcher = DataFetcher();
  await fetcher.fetchData();
  print('Final state: ${fetcher.state}');
}