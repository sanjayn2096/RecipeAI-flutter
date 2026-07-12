import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../data/api/api_service.dart';
import '../data/models/api_dtos.dart';
import '../data/models/recipe.dart';

enum RecipeAssistantRole { user, assistant }

class RecipeAssistantMessage {
  const RecipeAssistantMessage({
    required this.role,
    required this.content,
    this.outOfContext = false,
  });

  final RecipeAssistantRole role;
  final String content;
  final bool outOfContext;
}

class RecipeAssistantViewModel extends ChangeNotifier {
  RecipeAssistantViewModel({
    required ApiService apiService,
    required AppTelemetry appTelemetry,
    FirebaseAuth? firebaseAuth,
    SpeechToText? speechToText,
    FlutterTts? flutterTts,
  })  : _api = apiService,
        _telemetry = appTelemetry,
        _auth = firebaseAuth ?? FirebaseAuth.instance,
        _speech = speechToText ?? SpeechToText(),
        _tts = flutterTts ?? FlutterTts() {
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });
    _tts.setCancelHandler(() {
      _isSpeaking = false;
      notifyListeners();
    });
    _tts.setErrorHandler((_) {
      _isSpeaking = false;
      notifyListeners();
    });
  }

  static const _maxConversationMessages = 6;

  final ApiService _api;
  final AppTelemetry _telemetry;
  final FirebaseAuth _auth;
  final SpeechToText _speech;
  final FlutterTts _tts;

  final List<RecipeAssistantMessage> _messages = [];
  List<RecipeAssistantMessage> get messages => List.unmodifiable(_messages);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isListening = false;
  bool get isListening => _isListening;

  bool _voiceAvailable = true;
  bool get voiceAvailable => _voiceAvailable;

  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<String> _suggestedFollowUps = const [];
  List<String> get suggestedFollowUps => List.unmodifiable(_suggestedFollowUps);

  Future<void> ask(
    Recipe recipe,
    String rawQuestion, {
    bool speakAnswer = false,
  }) async {
    final question = rawQuestion.trim();
    if (question.isEmpty || _isLoading) return;

    await _telemetry.logFeatureInteraction(
      featureId: FeatureIds.recipeAssistantAsk,
      action: speakAnswer ? 'voice' : 'typed',
    );

    final priorConversation = _conversationForRequest();
    _messages.add(
      RecipeAssistantMessage(
        role: RecipeAssistantRole.user,
        content: question,
      ),
    );
    _isLoading = true;
    _errorMessage = null;
    _suggestedFollowUps = const [];
    notifyListeners();

    try {
      final user = _auth.currentUser;
      final idToken = await user?.getIdToken();
      if (idToken == null) {
        throw StateError('Sign in to use the recipe assistant.');
      }

      final response = await _api.askRecipe(
        RecipeQuestionRequest(
          recipe: recipe,
          question: question,
          conversation: priorConversation,
        ),
        idToken: idToken,
      );

      _messages.add(
        RecipeAssistantMessage(
          role: RecipeAssistantRole.assistant,
          content: response.answer,
          outOfContext: response.outOfContext,
        ),
      );
      _suggestedFollowUps = response.suggestedFollowUps;
      if (speakAnswer) {
        unawaited(speak(response.answer));
      }
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
      if (_messages.isNotEmpty && _messages.last.role == RecipeAssistantRole.user) {
        _messages.removeLast();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> startListening({
    required ValueChanged<String> onResult,
    required VoidCallback onFinalResult,
  }) async {
    if (_isListening || _isLoading) return;
    await _telemetry.logFeatureInteraction(
      featureId: FeatureIds.recipeAssistantVoice,
      action: 'start',
    );

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          notifyListeners();
        }
      },
      onError: (_) {
        _isListening = false;
        _voiceAvailable = false;
        _errorMessage = 'Voice input is not available right now.';
        notifyListeners();
      },
    );

    if (!available) {
      _voiceAvailable = false;
      _errorMessage = 'Microphone permission was not granted.';
      notifyListeners();
      return;
    }

    _voiceAvailable = true;
    _isListening = true;
    _errorMessage = null;
    notifyListeners();

    await _speech.listen(
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.confirmation,
        partialResults: true,
      ),
      onResult: (SpeechRecognitionResult result) {
        final words = result.recognizedWords.trim();
        if (words.isNotEmpty) {
          onResult(words);
        }
        if (result.finalResult) {
          _isListening = false;
          notifyListeners();
          onFinalResult();
        }
      },
    );
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    _isListening = false;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _telemetry.logFeatureInteraction(
      featureId: FeatureIds.recipeAssistantTts,
      action: 'speak',
    );
    await _tts.stop();
    _isSpeaking = true;
    notifyListeners();
    await _tts.speak(trimmed);
  }

  Future<void> stopSpeaking() async {
    if (!_isSpeaking) return;
    await _tts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  List<RecipeAssistantMessageDto> _conversationForRequest() {
    return _messages
        .where((m) => m.content.trim().isNotEmpty)
        .toList()
        .takeLast(_maxConversationMessages)
        .map(
          (m) => RecipeAssistantMessageDto(
            role: m.role == RecipeAssistantRole.user ? 'user' : 'assistant',
            content: m.content,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}

extension _TakeLast<T> on List<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) return this;
    return skip(length - count);
  }
}
