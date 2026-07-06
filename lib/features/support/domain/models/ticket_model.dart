enum TicketStatus { open, inProgress, resolved, closed;

  static TicketStatus fromString(String value) {
    switch (value) {
      case 'in_progress':
        return TicketStatus.inProgress;
      case 'resolved':
        return TicketStatus.resolved;
      case 'closed':
        return TicketStatus.closed;
      default:
        return TicketStatus.open;
    }
  }

  String get dbValue {
    switch (this) {
      case TicketStatus.open:
        return 'open';
      case TicketStatus.inProgress:
        return 'in_progress';
      case TicketStatus.resolved:
        return 'resolved';
      case TicketStatus.closed:
        return 'closed';
    }
  }

  String get label {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }
}

class TicketModel {
  final String id;
  final String customerId;
  final String? customerName;
  final String? orderId;
  final String subject;
  final String message;
  final TicketStatus status;
  final String priority;
  final DateTime createdAt;

  const TicketModel({
    required this.id,
    required this.customerId,
    this.customerName,
    this.orderId,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  factory TicketModel.fromMap(Map<String, dynamic> map) {
    final customer = map['profiles'] as Map<String, dynamic>?;
    return TicketModel(
      id: map['id'] as String,
      customerId: map['customer_id'] as String,
      customerName: customer?['full_name'] as String?,
      orderId: map['order_id'] as String?,
      subject: map['subject'] as String,
      message: map['message'] as String,
      status: TicketStatus.fromString(map['status'] as String),
      priority: map['priority'] as String? ?? 'normal',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
