import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user.dart';

class ApiService {
  static const String baseUrl =
      'https://jsonplaceholder.typicode.com/users';

  Future<List<User>> fetchUsers() async {
    try {
      // Send GET request
      final response = await http.get(Uri.parse(baseUrl));

      // Check if request was successful
      if (response.statusCode == 200) {
        // Convert JSON String into List
        final List<dynamic> data = jsonDecode(response.body);

        // Convert List<dynamic> into List<User>
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load users. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Something went wrong: $e');
    }
  }
}