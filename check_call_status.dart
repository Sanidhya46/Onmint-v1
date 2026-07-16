import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final res = await http.get(Uri.parse('https://api.onmint.in/api/v1/video/call-status/6a5914f54f6e9a56d14fe81f'));
  print(res.body);
}
