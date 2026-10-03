class TriggerModel {
  final int id;
  final int switchId;
  final String type;
  final String target;
  final dynamic payload;
  final bool isEnabled;
  final String? createdAt;
  final String? updatedAt;

  TriggerModel({
    required this.id,
    required this.switchId,
    required this.type,
    required this.target,
    this.payload,
    required this.isEnabled,
    this.createdAt,
    this.updatedAt,
  });

  factory TriggerModel.fromJson(Map<String, dynamic> json) {
    return TriggerModel(
      id: json['id'] as int,
      switchId: json['switch_id'] as int? ?? 0,
      type: json['type'] as String? ?? 'EMAIL',
      target: json['target'] as String? ?? '',
      payload: json['payload'],
      isEnabled: json['is_enabled'] == 1 || json['is_enabled'] == true,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'switch_id': switchId,
      'type': type,
      'target': target,
      'payload': payload,
      'is_enabled': isEnabled,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
