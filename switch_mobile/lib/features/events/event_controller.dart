import 'package:flutter/foundation.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class EventController extends ChangeNotifier {
  final EventService _eventService;

  List<EventModel> _events = [];
  EventModel? _selectedEvent;
  bool _isLoading = false;
  String? _errorMessage;

  List<EventModel> get events => _events;
  EventModel? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  EventController({EventService? eventService})
      : _eventService = eventService ?? EventService();

  Future<void> fetchEvents(int switchId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _eventService.getEvents(switchId);
    _isLoading = false;

    if (response.success && response.data != null) {
      _events = response.data!;
    } else {
      _errorMessage = response.message;
    }
    notifyListeners();
  }

  Future<void> fetchEventDetail(int switchId, int eventId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _eventService.getEventDetail(switchId, eventId);
    _isLoading = false;

    if (response.success && response.data != null) {
      _selectedEvent = response.data!;
    } else {
      _errorMessage = response.message;
    }
    notifyListeners();
  }
}
