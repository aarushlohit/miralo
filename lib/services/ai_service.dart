import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Supported AI Models for MIRALO AI
class AiModels {
  // Flagship NVIDIA NIM Models (Verified Active on integrate.api.nvidia.com)
  static const String nemotronSuper120b = 'Nemotron 3 Super 120B';
  static const String nemotronOmni30b = 'Nemotron 3 Omni 30B';
  static const String llamaVision11b = 'Llama 3.2 Vision 11B';
  static const String gemma26b = 'Gemma 26B Instruct';
  static const String gptOss20b = 'GPT-OSS 20B';

  // Google Gemini Cloud Models
  static const String gemini25Flash = 'Gemini 2.5 Flash';
  static const String gemini25Pro = 'Gemini 2.5 Pro';

  // Aliases for backwards compatibility
  static const String nvidiaNim = nemotronSuper120b;
  static const String nvidiaLlamaVision = llamaVision11b;
  static const String nvidiaGlm = nemotronOmni30b;
  static const String nvidiaKimi = gemma26b;
  static const String nvidiaLlama31 = nemotronSuper120b;
  static const String gemini35Flash = gemini25Flash;
  static const String gemini20Flash = gemini25Flash;
  static const String gemini25 = gemini25Flash;
  static const String gpt56 = 'GPT-5.6 (Local Neural)';
  static const String nemotron35Lightning = nemotronOmni30b;
  static const String nemotron3Ultra = nemotronSuper120b;

  static List<String> get all => [
        gemini25Flash,
        gemini25Pro,
        nemotronSuper120b,
        nemotronOmni30b,
        llamaVision11b,
        gemma26b,
        gptOss20b,
      ];

  static bool supportsImage(String model) {
    return model == llamaVision11b ||
        model == nvidiaLlamaVision ||
        model == gemini25Flash ||
        model == gemini25Pro ||
        model == gemini35Flash;
  }

  static String modelIdFor(String model) {
    switch (model) {
      case nemotronSuper120b:
        return 'nvidia/nemotron-3-super-120b-a12b';
      case nemotronOmni30b:
        return 'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning';
      case llamaVision11b:
        return 'meta/llama-3.2-11b-vision-instruct';
      case gemma26b:
        return 'google/diffusiongemma-26b-a4b-it';
      case gptOss20b:
        return 'openai/gpt-oss-20b';
      case gemini25Flash:
        return 'gemini-2.5-flash';
      case gemini25Pro:
        return 'gemini-2.5-pro';
      default:
        return model.contains('/') ? model : 'nvidia/nemotron-3-super-120b-a12b';
    }
  }

  static String descriptionFor(String model) {
    switch (model) {
      case nemotronSuper120b:
        return '120B MoE Flagship Architecture';
      case nemotronOmni30b:
        return '30B High-Speed Reasoning Engine';
      case llamaVision11b:
        return 'Multimodal Vision & Deep Analysis';
      case gemma26b:
        return '26B Instruction Tuned Cloud Model';
      case gptOss20b:
        return '20B Conversational Model';
      case gemini25Flash:
        return 'High-speed multimodal inference';
      case gemini25Pro:
        return 'Flagship deep reasoning & code';
      default:
        return 'High-Performance Cloud AI';
    }
  }
}

/// Service to handle real AI inference across NVIDIA NIM and Google Gemini
class AiService {
  static final AiService instance = AiService._();
  AiService._();

  static const String _prefGeminiKey = 'miralo_ai_gemini_key';
  static const String _prefNvidiaKey = 'miralo_ai_nvidia_key';
  static const String _prefSelectedModel = 'miralo_ai_selected_model';

  // Default verified backend API keys (configured in .env)
  static const String defaultGeminiKey =
      'YOUR_GEMINI_KEY';
  static const String defaultNvidiaKey =
      'YOUR_NVIDIA_KEY';

  String? _geminiApiKey;
  String? _nvidiaApiKey;
  String _selectedModel = AiModels.gemini35Flash;

  String get selectedModel => _selectedModel;
  String? get geminiApiKey => _geminiApiKey;
  String? get nvidiaApiKey => _nvidiaApiKey;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _geminiApiKey = prefs.getString(_prefGeminiKey);
    _nvidiaApiKey = prefs.getString(_prefNvidiaKey);
    _selectedModel = prefs.getString(_prefSelectedModel) ?? AiModels.gemini35Flash;
  }

  Future<void> setSelectedModel(String model) async {
    _selectedModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefSelectedModel, model);
  }

  Future<void> setGeminiApiKey(String key) async {
    _geminiApiKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefGeminiKey, _geminiApiKey!);
  }

  Future<void> setNvidiaApiKey(String key) async {
    _nvidiaApiKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefNvidiaKey, _nvidiaApiKey!);
  }

  /// Sends a user prompt (with optional image) to the active model
  Future<String> sendPrompt({
    required String prompt,
    String? model,
    String? imageBase64,
    bool isSpecialUser = false,
  }) async {
    final targetModel = model ?? _selectedModel;

    // Determine effective API keys (Special users or users with empty BYOK use backend keys)
    final effectiveGeminiKey = (_geminiApiKey != null && _geminiApiKey!.isNotEmpty)
        ? _geminiApiKey!
        : defaultGeminiKey;

    final effectiveNvidiaKey = (_nvidiaApiKey != null && _nvidiaApiKey!.isNotEmpty)
        ? _nvidiaApiKey!
        : defaultNvidiaKey;

    // Route: Google Gemini Models
    if (targetModel.startsWith('Gemini')) {
      try {
        final modelId = AiModels.modelIdFor(targetModel);
        return await _callGeminiApi(
          prompt: prompt,
          apiKey: effectiveGeminiKey,
          model: modelId,
          imageBase64: imageBase64,
        );
      } catch (e) {
        debugPrint('Gemini API Exception, falling back to NVIDIA NIM: $e');
        return await _callNvidiaNimApi(
          prompt: prompt,
          apiKey: effectiveNvidiaKey,
          model: 'nvidia/nemotron-3-super-120b-a12b',
          imageBase64: imageBase64,
        );
      }
    }

    // Route: NVIDIA NIM Models
    if (targetModel == AiModels.nemotronSuper120b ||
        targetModel == AiModels.nemotronOmni30b ||
        targetModel == AiModels.llamaVision11b ||
        targetModel == AiModels.gemma26b ||
        targetModel == AiModels.gptOss20b ||
        targetModel == AiModels.nvidiaLlamaVision ||
        targetModel == AiModels.nvidiaGlm ||
        targetModel == AiModels.nvidiaKimi ||
        targetModel == AiModels.nvidiaLlama31) {
      try {
        final modelId = AiModels.modelIdFor(targetModel);
        return await _callNvidiaNimApi(
          prompt: prompt,
          apiKey: effectiveNvidiaKey,
          model: modelId,
          imageBase64: imageBase64,
        );
      } catch (e) {
        debugPrint('NVIDIA NIM API Exception, falling back to Gemini: $e');
        return await _callGeminiApi(
          prompt: prompt,
          apiKey: effectiveGeminiKey,
          model: 'gemini-2.5-flash',
          imageBase64: imageBase64,
        );
      }
    }

    // Default: dispatch to primary Gemini cloud model
    return await _callGeminiApi(
      prompt: prompt,
      apiKey: effectiveGeminiKey,
      model: 'gemini-2.5-flash',
      imageBase64: imageBase64,
    );
  }

  Future<String> _callGeminiApi({
    required String prompt,
    required String apiKey,
    required String model,
    String? imageBase64,
  }) async {
    // Standardize Gemini model ID for Google Generative Language API
    final effectiveModel = (model == 'gemini-1.5-flash' || model == 'gemini-1.5-pro' || model.contains('3.'))
        ? 'gemini-2.5-flash'
        : model;

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$effectiveModel:generateContent?key=$apiKey',
    );

    final parts = <Map<String, dynamic>>[];
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      parts.add({
        'inlineData': {
          'mimeType': 'image/jpeg',
          'data': imageBase64,
        }
      });
    }
    parts.add({'text': prompt});

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {'parts': parts}
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 2048,
        }
      }),
    ).timeout(const Duration(seconds: 25));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (text != null && text is String && text.trim().isNotEmpty) {
        return text.trim();
      }
    }
    throw Exception('Gemini HTTP ${response.statusCode}: ${response.body}');
  }

  Future<String> _callNvidiaNimApi({
    required String prompt,
    required String apiKey,
    required String model,
    String? imageBase64,
  }) async {
    final url = Uri.parse('https://integrate.api.nvidia.com/v1/chat/completions');

    dynamic content;
    if (imageBase64 != null && imageBase64.isNotEmpty) {
      content = [
        {'type': 'text', 'text': prompt},
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:image/jpeg;base64,$imageBase64',
          }
        }
      ];
    } else {
      content = prompt;
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'user', 'content': content}
        ],
        'temperature': 0.6,
        'max_tokens': 1024,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices']?[0]?['message']?['content'];
      if (text != null && text is String && text.trim().isNotEmpty) {
        return text.trim();
      }
      final reasoning = data['choices']?[0]?['message']?['reasoning_content'];
      if (reasoning != null && reasoning is String && reasoning.trim().isNotEmpty) {
        return reasoning.trim();
      }
    }
    throw Exception('NVIDIA NIM HTTP ${response.statusCode}: ${response.body}');
  }
}

