import 'dart:io';
import 'dart:convert';

// Simulated token storage (in real Flutter apps, use flutter_secure_storage)
class TokenStorage {
  static String? accessToken;      // short-lived (used in requests)
  static String? refreshToken;     // long-lived (used to get new access token)
  
  static void save({required String access, required String refresh}) {    // Method to save tokens

    //A temporary storage for tokens
    accessToken = access;            
    refreshToken = refresh;           
    print('[Storage] Tokens saved!');
  }
  
  static bool get hasToken => accessToken != null;   //    Returns true if user is logged in
}

class AuthService {
  final HttpClient _client = HttpClient();

  // Using a real test API that supports auth (we'll simulate it here)
  final String baseUrl = 'https://jsonplaceholder.typicode.com';

  // ── STEP 1 & 2: Login → receive tokens
  // Real API would be: POST /auth/login with email+password
  Future<void> login(String email, String password) async {
    print('\n[Auth] Logging in...');
    
    // Simulating a login call. In real life:
    var req = await _client.postUrl(Uri.parse('$baseUrl/auth/login'));
    req.write(jsonEncode({'email': email, 'password': password}));
    var res = await req.close();
    var body = jsonDecode(await res.transform(utf8.decoder).join());
    
    // Simulated response from server:
    var simulatedResponse = {
      'access_token':  'eyJhbGciOiJIUzI1NiJ9.user123.abc',  // JWT token
      'refresh_token': 'refresh_xyz_9999',                    // long-lived token
      'expires_in':    3600,                                  // 1 hour
    };
    
    // ── STEP 3: Store the tokens
    TokenStorage.save(
      access:  simulatedResponse['access_token'] as String,
      refresh: simulatedResponse['refresh_token'] as String,
    );
    print('[Auth] Login successful!');
  }

  // ── STEP 4: Use token in future requests
  Future<void> fetchProtectedData() async {
    if (!TokenStorage.hasToken) {
      print('[Auth] No token! Please login first.');
      return;
    }

    var req = await _client.getUrl(
      Uri.parse('$baseUrl/posts/1') // a protected endpoint
    );
    
    // Add token to header — the "key card swipe"
    req.headers.set('Authorization', 'Bearer ${TokenStorage.accessToken}');
    req.headers.set('Content-Type', 'application/json');
    
    var res = await req.close();
    var body = await res.transform(utf8.decoder).join();
    print('[Auth] Protected data: ${jsonDecode(body)['title']}');
  }

  // ── STEP 5: Refresh token (when access token expires)
  // Analogy: Getting a new key card at the front desk with your old receipt
  Future<void> refreshAccessToken() async {
    print('\n[Auth] Access token expired, refreshing...');
    
    // Real API call:
    // POST /auth/refresh with { refresh_token: ... }
    // Server returns a new access_token
    
    // Simulated:
    String newAccessToken = 'eyJhbGciOiJIUzI1NiJ9.newtoken.xyz';
    TokenStorage.accessToken = newAccessToken;
    print('[Auth] Token refreshed! New token: $newAccessToken');
  }
}

// ── API KEY auth (simpler — no login needed)
// Some APIs just give you a key. You send it every request.
// Analogy: A library membership card number
Future<void> apiKeyExample() async {
  final client = HttpClient();
  const apiKey = 'your-api-key-here'; // never hardcode in real apps!
  
  var req = await client.getUrl(
    Uri.parse('https://api.example.com/data?api_key=$apiKey')
    // OR in header: req.headers.set('X-API-Key', apiKey);
  );
  var res = await req.close();
  print('API Key request: ${res.statusCode}');
  client.close();
}

void main() async {
  final auth = AuthService();
  
  await auth.login('user@example.com', 'password123');
  await auth.fetchProtectedData();
  
  // Simulating token expiry:
  await auth.refreshAccessToken();
  await auth.fetchProtectedData(); // works again with new token
}