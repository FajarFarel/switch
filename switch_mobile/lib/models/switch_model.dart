class SwitchModel {
  final int id;
  final int? userId;
  final String name;
  final String status;
  final int checkinInterval; // in minutes
  final int gracePeriod; // in minutes
  final String? lastCheckinAt;
  final String? nextDeadlineAt;
  final String? graceDeadlineAt;
  final String? armedAt;
  final String? disarmedAt;
  final String? createdAt;

  SwitchModel({
    required this.id,
    this.userId,
    required this.name,
    required this.status,
    required this.checkinInterval,
    required this.gracePeriod,
    this.lastCheckinAt,
    this.nextDeadlineAt,
    this.graceDeadlineAt,
    this.armedAt,
    this.disarmedAt,
    this.createdAt,
  });

  factory SwitchModel.fromJson(Map<String, dynamic> json) {
    return SwitchModel(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'DISARMED',
      checkinInterval: json['checkin_interval'] as int? ?? 60,
      gracePeriod: json['grace_period'] as int? ?? 15,
      lastCheckinAt: json['last_checkin_at'] as String?,
      nextDeadlineAt: json['next_deadline_at'] as String?,
      graceDeadlineAt: json['grace_deadline_at'] as String?,
      armedAt: json['armed_at'] as String?,
      disarmedAt: json['disarmed_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'status': status,
      'checkin_interval': checkinInterval,
      'grace_period': gracePeriod,
      'last_checkin_at': lastCheckinAt,
      'next_deadline_at': nextDeadlineAt,
      'grace_deadline_at': graceDeadlineAt,
      'armed_at': armedAt,
      'disarmed_at': disarmedAt,
      'created_at': createdAt,
    };
  }

  bool get isArmed => status == 'ARMED';
}
