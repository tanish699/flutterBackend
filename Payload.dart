import 'dart:convert';

void main() {
  // ── JSON Encoding (Dart object → JSON string to SEND)
  // Analogy: Translating English to French before mailing to France

  Map<String, dynamic> dartMap = {  //creating a Dart Map (like a dictionary), String → key type, dynamic → value can be anything (int, bool, list, etc.)
    'name': 'Ranjeet',
    'age': 25,
    'isActive': true,
    'scores': [98, 87, 92],
  };






  String jsonString = jsonEncode(dartMap);
  print('Encoded: $jsonString');
  // Output: {"name":"Ranjeet","age":25,"isActive":true,"scores":[98,87,92]}




  // ── JSON Decoding (JSON string → Dart object, when you RECEIVE)
  // Analogy: Translating French letter back to English
  String received = '{"city":"Ludhiana","population":1800000}';
  Map<String, dynamic> decoded = jsonDecode(received);             // Converts JSON string → Dart Map
  print('City: ${decoded['city']}');      // Ludhiana
  print('Pop:  ${decoded['population']}'); // 1800000
}



