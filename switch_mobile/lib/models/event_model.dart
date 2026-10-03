class EventModel {
  final int id;
  final int switchId;
  final int? userId;
  final String eventType;
  final String? description;
  final dynamic metadata;
  final String? createdAt;

  EventModel({
    required this.id,
    required this.switchId,
    this.userId,
    required this.eventType,
    this.description,
    this.metadata,
    this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as int,
      switchId: json['switch_id'] as int? ?? 0,
      userId: json['user_id'] as int?,
      eventType: json['event_type'] as String? ?? '',
      description: json['description'] as String?,
      metadata: json['metadata'],
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'switch_id': switchId,
      'user_id': userId,
      'event_type': eventType,
      'description': description,
      'metadata': metadata,
      'created_at': createdAt,
    };
  }
}
