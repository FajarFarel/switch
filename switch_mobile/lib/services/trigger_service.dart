import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../models/trigger_model.dart';

class TriggerService {
  final ApiClient _apiClient;

  TriggerService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<List<TriggerModel>>> getTriggers(int switchId) async {
    return await _apiClient.get<List<TriggerModel>>(
      ApiConstants.switchTriggers(switchId),
      create: (json) {
        if (json is List) {
          return json
              .map((item) => TriggerModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  Future<ApiResponse<TriggerModel>> createTrigger({
    required int switchId,
    required String type, // EMAIL, WEBHOOK, WHATSAPP
    required String target,
  }) async {
    return await _apiClient.post<TriggerModel>(
      ApiConstants.switchTriggers(switchId),
      body: {
        'type': type,
        'target': target,
      },
      create: (json) => TriggerModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> updateTrigger({
    required int triggerId,
    String? target,
    bool? isEnabled,
  }) async {
    final body = <String, dynamic>{};
    if (target != null) body['target'] = target;
    if (isEnabled != null) body['is_enabled'] = isEnabled;

    return await _apiClient.put<dynamic>(
      ApiConstants.triggerDetail(triggerId),
      body: body,
    );
  }

  Future<ApiResponse<dynamic>> deleteTrigger(int triggerId) async {
    return await _apiClient.delete<dynamic>(
      ApiConstants.triggerDetail(triggerId),
    );
  }
}
