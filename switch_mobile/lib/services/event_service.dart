import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../models/event_model.dart';

class EventService {
  final ApiClient _apiClient;

  EventService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<List<EventModel>>> getEvents(int switchId) async {
    return await _apiClient.get<List<EventModel>>(
      ApiConstants.switchEvents(switchId),
      create: (json) {
        if (json is List) {
          return json
              .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  Future<ApiResponse<EventModel>> getEventDetail(
    int switchId,
    int eventId,
  ) async {
    return await _apiClient.get<EventModel>(
      ApiConstants.switchEventDetail(switchId, eventId),
      create: (json) => EventModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
