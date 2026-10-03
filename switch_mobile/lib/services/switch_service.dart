import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_response.dart';
import '../models/switch_model.dart';

class SwitchService {
  final ApiClient _apiClient;

  SwitchService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<ApiResponse<List<SwitchModel>>> getSwitches() async {
    return await _apiClient.get<List<SwitchModel>>(
      ApiConstants.switches,
      create: (json) {
        if (json is List) {
          return json
              .map((item) => SwitchModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
  }

  Future<ApiResponse<SwitchModel>> getSwitchDetail(int id) async {
    return await _apiClient.get<SwitchModel>(
      ApiConstants.switchDetail(id),
      create: (json) => SwitchModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> createSwitch({
    required String name,
    required int checkinInterval,
    required int gracePeriod,
  }) async {
    return await _apiClient.post<Map<String, dynamic>>(
      ApiConstants.switches,
      body: {
        'name': name,
        'checkin_interval': checkinInterval,
        'grace_period': gracePeriod,
      },
      create: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<dynamic>> updateSwitch({
    required int id,
    required String name,
    required int checkinInterval,
    required int gracePeriod,
  }) async {
    return await _apiClient.put<dynamic>(
      ApiConstants.switchDetail(id),
      body: {
        'name': name,
        'checkin_interval': checkinInterval,
        'grace_period': gracePeriod,
      },
    );
  }

  Future<ApiResponse<dynamic>> deleteSwitch(int id) async {
    return await _apiClient.delete<dynamic>(
      ApiConstants.switchDetail(id),
    );
  }

  Future<ApiResponse<dynamic>> armSwitch(int id) async {
    return await _apiClient.post<dynamic>(
      ApiConstants.switchArm(id),
    );
  }

  Future<ApiResponse<dynamic>> disarmSwitch(int id) async {
    return await _apiClient.post<dynamic>(
      ApiConstants.switchDisarm(id),
    );
  }

  Future<ApiResponse<dynamic>> checkinSwitch(int id, {String? deviceId}) async {
    return await _apiClient.post<dynamic>(
      ApiConstants.switchCheckin(id),
      body: deviceId != null ? {'device_id': deviceId} : {},
    );
  }
}
