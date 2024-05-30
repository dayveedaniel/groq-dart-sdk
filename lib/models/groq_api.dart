import 'dart:convert';

import 'package:groq_sdk/models/groq_chat.dart';
import 'package:groq_sdk/models/groq_conversation_item.dart';
import 'package:groq_sdk/models/groq_exceptions.dart';
import 'package:groq_sdk/models/groq_llm_model.dart';
import 'package:groq_sdk/models/groq_message.dart';
import 'package:groq_sdk/models/groq_rate_limit_information.dart';
import 'package:groq_sdk/models/groq_response.dart';
import 'package:groq_sdk/models/groq_usage.dart';
import 'package:groq_sdk/utils/auth_http.dart';

class GroqApi {
  static const String _chatCompletionUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _getModelBaseUrl =
      'https://api.groq.com/openai/v1/models';

  static Future<GroqLLMModel> getModel(String modelId, String apiKey) async {
    final response =
        await AuthHttp.get(url: '$_getModelBaseUrl/$modelId', apiKey: apiKey);
    if (response.statusCode == 200) {
      return GroqLLMModel.fromJson(json.decode(response.body));
    } else {
      throw GroqException.fromResponse(response);
    }
  }

  static Future<List<GroqLLMModel>> listModels(String apiKey) async {
    final response = await AuthHttp.get(url: _getModelBaseUrl, apiKey: apiKey);
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final List<dynamic> jsonList = jsonData['data'] as List<dynamic>;
      return jsonList.map((json) => GroqLLMModel.fromJson(json)).toList();
    } else {
      throw GroqException.fromResponse(response);
    }
  }

  static Future<(GroqResponse, GroqUsage, GroqRateLimitInformation)>
      getNewChatCompletion({
    required String apiKey,
    required GroqMessage prompt,
    required GroqChat chat,
  }) async {
    final Map<String, dynamic> jsonMap = {};
    List<Map<String, dynamic>> messages = [];
    List<GroqConversationItem> allMessages = chat.allMessages;
    if (chat.allMessages.length > chat.settings.maxConversationalMemoryLength) {
      allMessages.removeRange(
          0, allMessages.length - chat.settings.maxConversationalMemoryLength);
    }
    for (final message in allMessages) {
      messages.add(message.request.toJson());
      messages.add(message.response!.choices.first.messageData.toJson());
    }
    messages.add(prompt.toJson());
    jsonMap['messages'] = messages;
    jsonMap['model'] = chat.model;
    jsonMap.addAll(chat.settings.toJson());
    final response = await AuthHttp.post(
        url: _chatCompletionUrl, apiKey: apiKey, body: jsonMap);
    //Rate Limit information
    final rateLimitInfo =
        GroqRateLimitInformation.fromHeaders(response.headers);
    if (response.statusCode < 300) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final GroqResponse groqResponse = GroqResponse.fromJson(jsonData);
      final GroqUsage groqUsage = GroqUsage.fromJson(jsonData["usage"]);
      return (groqResponse, groqUsage, rateLimitInfo);
    } else if (response.statusCode == 429) {
      throw GroqRateLimitException(
        retryAfter: Duration(
          seconds: int.tryParse(response.headers['retry-after'] ?? '0') ?? 0,
        ),
      );
    } else {
      throw GroqException.fromResponse(response);
    }
  }
}