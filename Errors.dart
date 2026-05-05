import 'dart:io';
import 'dart:convert';

// ── Custom error types
// Analogy: Different types of receipts for different problems
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  
  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

// ── Retry logic
// Analogy: If the auto-rickshaw doesn't come in 2 min, try again, up to 3 times


Future<T> withRetry<T>(                                //Generic function: Can retry ANY async function
  Future<T> Function() fn, {
  int maxAttempts = 3,
  Duration delay = const Duration(seconds: 2),
}) async {
  int attempt = 0;
  while (true) {
    attempt++;
    try {
      print('[Retry] Attempt $attempt of $maxAttempts');
      return await fn();
    } catch (e) {
      if (attempt >= maxAttempts) rethrow; // give up after max attempts
      print('[Retry] Failed, waiting ${delay.inSeconds}s...');
      await Future.delayed(delay);
    }
  }
}

// ── Main API call with full error handling
Future<Map<String, dynamic>> fetchPost(int id) async {
  final client = HttpClient();
  
  try {
    // Set timeout — don't wait forever
    // Analogy: If pizza hasn't arrived in 45 min, cancel the order
    client.connectionTimeout = Duration(seconds: 10);
    
    var req = await client.getUrl(
      Uri.parse('https://jsonplaceholder.typicode.com/posts/$id')
    ).timeout(
      Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Request timed out after 10s'),
    );
    
    var res = await req.close().timeout(Duration(seconds: 10));
    var body = await res.transform(utf8.decoder).join();
    
    // ── Handle different status codes
    switch (res.statusCode) {
      case 200:
      case 201:
        return jsonDecode(body);
        
      case 400:
        throw ApiException('Bad request — check your input', statusCode: 400);
        
      case 401:
        throw ApiException('Unauthorized — please login again', statusCode: 401);
        
      case 403:
        throw ApiException('Forbidden — you don\'t have access', statusCode: 403);
        
      case 404:
        throw ApiException('Post #$id not found', statusCode: 404);
        
      case 429:
        throw ApiException('Too many requests — slow down', statusCode: 429);
        
      default:
        if (res.statusCode >= 500) {
          throw ApiException('Server error — try again later', statusCode: res.statusCode);
        }
        throw ApiException('Unexpected status: ${res.statusCode}', statusCode: res.statusCode);
    }
    
  } on SocketException catch (e) {
    // No internet connection
    throw NetworkException('No internet connection: ${e.message}');
    
  } on TimeoutException catch (e) {
    throw NetworkException('Request timed out: $e');
    
  } finally {
    client.close(); // ALWAYS close the client
  }
}

// ── Convert technical error to user-friendly message
String getUserMessage(Object error) {
  if (error is NetworkException) {
    return 'Please check your internet connection and try again.';
  }
  if (error is ApiException) {
    switch (error.statusCode) {
      case 404: return 'The item you\'re looking for doesn\'t exist.';
      case 401: return 'Please login to continue.';
      case 429: return 'You\'re doing that too fast. Please wait a moment.';
      default:  return error.message;
    }
  }
  return 'Something went wrong. Please try again.';
}

void main() async {
  // ── Normal fetch with error handling
  try {
    var post = await fetchPost(1);
    print('Success: ${post['title']}');
  } catch (e) {
    print('User sees: ${getUserMessage(e)}');
    print('Dev sees: $e'); // log the real error
  }

  // ── Fetch with retry (for unreliable networks)
  try {
    var post = await withRetry(
      () => fetchPost(99999), // will 404, demonstrating retry
      maxAttempts: 3,
      delay: Duration(seconds: 1),
    );
    print('Got: ${post['title']}');
  } catch (e) {
    print('Final failure: ${getUserMessage(e)}');
  }
}