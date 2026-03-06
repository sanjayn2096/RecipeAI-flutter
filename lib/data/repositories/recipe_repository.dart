import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/recipe.dart';
import '../../services/session_manager.dart';
import '../../core/prompt_builder.dart';

/// Fetches recipes via Gemini. Prompt built from session preferences (single place).
class RecipeRepository {
  RecipeRepository({
    required String apiKey,
    required SessionManager sessionManager,
    PromptBuilder? promptBuilder,
  })  : _apiKey = apiKey,
        _session = sessionManager,
        _promptBuilder = promptBuilder ?? PromptBuilder(sessionManager: sessionManager);

  final String _apiKey;
  final SessionManager _session;
  final PromptBuilder _promptBuilder;

  Future<List<Recipe>> fetchRecipes() async {
    final prompt = _promptBuilder.build();
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    final text = response.text;
    if (text == null || text.isEmpty) return [];
    try {
      final list = jsonDecode(text) as List<dynamic>;
      return list
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
