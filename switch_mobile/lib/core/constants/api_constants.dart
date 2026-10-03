class ApiConstants {
  // General
  static const String status = '/api/status';

  // Auth
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String me = '/api/auth/me';

  // Switch
  static const String switches = '/api/switch';
  static String switchDetail(int id) => '/api/switch/$id';
  static String switchArm(int id) => '/api/switch/$id/arm';
  static String switchDisarm(int id) => '/api/switch/$id/disarm';
  static String switchCheckin(int id) => '/api/switch/$id/checkin';

  // Triggers
  static String switchTriggers(int switchId) => '/api/switch/$switchId/triggers';
  static String triggerDetail(int triggerId) => '/api/switch/triggers/$triggerId';

  // Events
  static String switchEvents(int switchId) => '/api/switch/$switchId/events';
  static String switchEventDetail(int switchId, int eventId) =>
      '/api/switch/$switchId/events/$eventId';
}
