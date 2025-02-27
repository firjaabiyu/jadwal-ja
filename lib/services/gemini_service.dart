import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/tasks.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";
  final String apiKey;
  GeminiService() :apiKey = dotenv.env["GEMINI_API_KEY"] ?? "" {
    if (apiKey.isEmpty) {
      throw ArgumentError("API key is missing");
    }
  }

  Future<String> generateSchedule(List<Task> tasks) async {
    _validateTasks(tasks);
    final prompt =_buildPrompt(tasks);

    try {
      print("Prompt: \n$prompt");
      final response = await http.post(
        Uri.parse("$_baseUrl?key=$apiKey"),
        headers: {
          "Content-Type" : "application/json"
        },
        body: jsonEncode({
          "contents": [{
            "role": "user",
            "parts":[ {"text": prompt }
            ]
          }]
        }),
      );
    return _handleResponse(response);
    } catch (e) {
      throw ArgumentError("Failed to generate schedule: $e");
    }
  }

  String _handleResponse(http.Response response) {
    final data = jsonDecode(response.body);
    if (response.statusCode == 401){
      throw ArgumentError("Invalid API Key or Unauthorized Access");
    } else if (response.statusCode == 429){
      throw ArgumentError("Rate Limit Exceeded");
    } else if (response.statusCode == 500){
      throw ArgumentError("Internal Server Error");
    } else if (response.statusCode == 503){
      throw ArgumentError("Service Unavailable");
    } else if (response.statusCode == 200){
      return data["candidates"][0]["contents"][0]["parts"][0]["text"];
    } else {
      throw ArgumentError("Unknown Error");
    }
  }

  String _buildPrompt(List<Task> tasks){
    final tasksList = tasks.map((task) => "${task.name} (Priority: ${task.priority}, Duration: ${task.duration} minutes, Deadline: ${task.deadline})").join("\n");
    return "Buatkan jadwal harian yang optimal berdasarkan task berikut:\n$tasksList";
  }

  void _validateTasks(List<Task> tasks) {
    if(tasks.isEmpty) throw ArgumentError("Tasks cannot be Empty");
  }
}
