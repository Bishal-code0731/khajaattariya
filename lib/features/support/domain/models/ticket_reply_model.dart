class TicketReplyModel {
  final String id;
  final String ticketId;
  final String actorId;
  final String? actorName;
  final String message;
  final bool isInternal;
  final DateTime createdAt;

  const TicketReplyModel({
    required this.id,
    required this.ticketId,
    required this.actorId,
    this.actorName,
    required this.message,
    required this.isInternal,
    required this.createdAt,
  });

  factory TicketReplyModel.fromMap(Map<String, dynamic> map) {
    final actor = map['profiles'] as Map<String, dynamic>?;
    return TicketReplyModel(
      id: map['id'] as String,
      ticketId: map['ticket_id'] as String,
      actorId: map['actor_id'] as String,
      actorName: actor?['full_name'] as String?,
      message: map['message'] as String,
      isInternal: map['is_internal'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
