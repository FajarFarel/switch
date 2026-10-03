import 'package:flutter/foundation.dart';
import '../../models/switch_model.dart';
import '../../models/trigger_model.dart';
import '../../services/switch_service.dart';
import '../../services/trigger_service.dart';

class SwitchController extends ChangeNotifier {
  final SwitchService _switchService;
  final TriggerService _triggerService;

  List<SwitchModel> _switches = [];
  SwitchModel? _selectedSwitch;
  List<TriggerModel> _triggers = [];

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<SwitchModel> get switches => _switches;
  SwitchModel? get selectedSwitch => _selectedSwitch;
  List<TriggerModel> get triggers => _triggers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  SwitchController({
    SwitchService? switchService,
    TriggerService? triggerService,
  })  : _switchService = switchService ?? SwitchService(),
        _triggerService = triggerService ?? TriggerService();

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> fetchSwitches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _switchService.getSwitches();
    _isLoading = false;

    if (response.success && response.data != null) {
      _switches = response.data!;
    } else {
      _errorMessage = response.message;
    }
    notifyListeners();
  }

  Future<void> fetchSwitchDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _switchService.getSwitchDetail(id);
    _isLoading = false;

    if (response.success && response.data != null) {
      _selectedSwitch = response.data!;
      await fetchTriggers(id);
    } else {
      _errorMessage = response.message;
    }
    notifyListeners();
  }

  Future<bool> createSwitch({
    required String name,
    required int checkinInterval,
    required int gracePeriod,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _switchService.createSwitch(
      name: name,
      checkinInterval: checkinInterval,
      gracePeriod: gracePeriod,
    );

    _isLoading = false;
    if (response.success) {
      _successMessage = response.message;
      await fetchSwitches();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSwitch({
    required int id,
    required String name,
    required int checkinInterval,
    required int gracePeriod,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _switchService.updateSwitch(
      id: id,
      name: name,
      checkinInterval: checkinInterval,
      gracePeriod: gracePeriod,
    );

    _isLoading = false;
    if (response.success) {
      _successMessage = response.message;
      await fetchSwitchDetail(id);
      await fetchSwitches();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSwitch(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _switchService.deleteSwitch(id);
    _isLoading = false;

    if (response.success) {
      _successMessage = response.message;
      await fetchSwitches();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> armSwitch(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _switchService.armSwitch(id);
    _isLoading = false;

    if (response.success) {
      _successMessage = response.message;
      await fetchSwitchDetail(id);
      await fetchSwitches();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> disarmSwitch(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _switchService.disarmSwitch(id);
    _isLoading = false;

    if (response.success) {
      _successMessage = response.message;
      await fetchSwitchDetail(id);
      await fetchSwitches();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkinSwitch(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _switchService.checkinSwitch(id);
    _isLoading = false;

    if (response.success) {
      _successMessage = response.message;
      await fetchSwitchDetail(id);
      await fetchSwitches();
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  // --- Triggers ---
  Future<void> fetchTriggers(int switchId) async {
    final response = await _triggerService.getTriggers(switchId);
    if (response.success && response.data != null) {
      _triggers = response.data!;
      notifyListeners();
    }
  }

  Future<bool> createTrigger({
    required int switchId,
    required String type,
    required String target,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _triggerService.createTrigger(
      switchId: switchId,
      type: type,
      target: target,
    );

    _isLoading = false;
    if (response.success) {
      _successMessage = response.message;
      await fetchTriggers(switchId);
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleTrigger(int switchId, int triggerId, bool isEnabled) async {
    final response = await _triggerService.updateTrigger(
      triggerId: triggerId,
      isEnabled: isEnabled,
    );
    if (response.success) {
      await fetchTriggers(switchId);
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTrigger(int switchId, int triggerId) async {
    final response = await _triggerService.deleteTrigger(triggerId);
    if (response.success) {
      await fetchTriggers(switchId);
      return true;
    } else {
      _errorMessage = response.message;
      notifyListeners();
      return false;
    }
  }
}
