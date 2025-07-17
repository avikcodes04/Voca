import 'dart:convert';

import 'package:ai_app/secrets.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  final List<Map<String, dynamic>> messages = [];
  Future<Map<String, dynamic>> isArtPrompt(String prompt) async {
    try {
      final res = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
        ),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': geminiAPIKey, // To be defined in secrets.dart
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      'Does this message want to generate an AI picture, image, art or anything similar? ( $prompt ). Simply answer with a yes or a no.',
                },
              ],
            },
          ],
        }),
      );
      print(res.body);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'];
        text = text.trim();
        print(" (is this a image generation request ?) -> $text ");
        switch (text) {
          case "Yes":
          case "yes":
            return await googleGeminiImage(prompt);
          default:
            final res = await googleGemini(prompt);
            return {'text': res, 'image': null};
        }
      }
      return {'text': "Failed: \\${res.body}", 'image': null};
    } catch (e) {
      return {'text': e.toString(), 'image': null};
    }
  }

  Future<String> googleGemini(String prompt) async {
    messages.add({
      "parts": [
        {"text": prompt},
      ],
      "role": "user", // or whatever role is appropriate
      // "timestamp": DateTime.now().toIso8601String(),
    });
    try {
      final res = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
        ),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': geminiAPIKey, // To be defined in secrets.dart
        },
        body: jsonEncode({"contents": messages}),
      );
      //print(res.body);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        String text = data['candidates'][0]['content']['parts'][0]['text'];
        text = text.trim();
        print("the response from GEMINI is $text");
        messages.add({
          "parts": [
            {"text": text},
          ],
          'role': 'assistant',
        });
        return text;
      }
      return "Failed: \\${res.body}";
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>> googleGeminiImage(String prompt) async {
    messages.add({
      "parts": [
        {"text": prompt},
      ],
      "role": "user",
    });

    try {
      final res = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-preview-image-generation:generateContent',
        ),
        headers: {
          'Content-Type': 'application/json',
          'X-goog-api-key': geminiAPIKey,
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
          "generationConfig": {
            "responseModalities": ["TEXT", "IMAGE"],
          },
        }),
      );
      print("THE RESPONSE OF GEMINI IS -------");
      print(res.body);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final parts = data['candidates'][0]['content']['parts'];

        // Extract all text parts
        final textParts = parts
            .where(
              (part) =>
                  part is Map<String, dynamic> && part.containsKey('text'),
            )
            .map((part) => part['text'] as String)
            .join(' ');

        // Extract the first image part (if any)
        final imagePart = parts.firstWhere(
          (part) =>
              part is Map<String, dynamic> && part.containsKey('inlineData'),
          orElse: () => null,
        );

        String? base64Image;
        if (imagePart != null) {
          base64Image = imagePart['inlineData']['data'];
        }

        return {'text': textParts, 'image': base64Image};
      }

      return {'text': "Error: ${res.body}", 'image': null};
    } catch (e) {
      return {'text': "Error: ${e.toString()}", 'image': null};
    }
  }
}
