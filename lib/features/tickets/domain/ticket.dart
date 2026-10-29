class TicketStage {
  final int id;
  final String name;
  final int sequence;
  final bool isClosed;
  final bool fold;

  const TicketStage({
    required this.id,
    required this.name,
    required this.sequence,
    required this.isClosed,
    required this.fold,
  });

  factory TicketStage.fromJson(Map<String, dynamic> json) {
    return TicketStage(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      sequence: json['sequence'] as int? ?? 1,
      isClosed: json['is_closed'] as bool? ?? false,
      fold: json['fold'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sequence': sequence,
    'is_closed': isClosed,
    'fold': fold,
  };
}

class TicketAttachment {
  final int id;
  final String name;
  final String mimetype;
  final int size;
  final String url;

  const TicketAttachment({
    required this.id,
    required this.name,
    required this.mimetype,
    required this.size,
    required this.url,
  });

  factory TicketAttachment.fromJson(Map<String, dynamic> json) {
    return TicketAttachment(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      mimetype: json['mimetype'] as String? ?? 'application/octet-stream',
      size: json['size'] as int? ?? 0,
      url: json['url'] as String? ?? '',
    );
  }
}

/// Rich Employee Assignee (hr.employee) linked to Helpdesk operations
class AssigneeEmployee {
  final int id;
  final String name;
  final String jobTitle;
  final String department;
  final String? email;
  final String? phone;
  final int openTicketsCount;

  const AssigneeEmployee({
    required this.id,
    required this.name,
    this.jobTitle = '',
    this.department = '',
    this.email,
    this.phone,
    this.openTicketsCount = 0,
  });

  factory AssigneeEmployee.fromJson(Map<String, dynamic> json) {
    return AssigneeEmployee(
      id: json['id'] as int? ?? 0,
      name: (json['name'] is String && (json['name'] as String).isNotEmpty)
          ? json['name'] as String
          : 'Employee',
      jobTitle: json['job_title'] is String ? json['job_title'] as String : '',
      department: json['department'] is String ? json['department'] as String : '',
      email: json['email'] is String ? json['email'] as String : null,
      phone: json['phone'] is String ? json['phone'] as String : null,
      openTicketsCount: json['open_tickets_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'job_title': jobTitle,
    'department': department,
    'email': email,
    'phone': phone,
    'open_tickets_count': openTicketsCount,
  };

  /// Backward-compatible map access
  dynamic operator [](String key) {
    switch (key) {
      case 'id':
        return id;
      case 'name':
        return name;
      case 'job_title':
        return jobTitle;
      case 'department':
        return department;
      case 'email':
        return email;
      case 'phone':
        return phone;
      case 'open_tickets_count':
        return openTicketsCount;
      default:
        return null;
    }
  }
}

/// Customer partner information
class CustomerInfo {
  final int id;
  final String name;
  final String? email;
  final String? phone;

  const CustomerInfo({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      id: json['id'] as int? ?? 0,
      name: (json['name'] is String && (json['name'] as String).isNotEmpty)
          ? json['name'] as String
          : 'Customer',
      email: json['email'] is String ? json['email'] as String : null,
      phone: json['phone'] is String ? json['phone'] as String : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
  };

  /// Backward-compatible map access
  dynamic operator [](String key) {
    switch (key) {
      case 'id':
        return id;
      case 'name':
        return name;
      case 'email':
        return email;
      case 'phone':
        return phone;
      default:
        return null;
    }
  }
}

class Ticket {
  final int id;
  final String number;
  final String subject;
  final TicketStage stage;
  final int priority;
  final AssigneeEmployee? assignee;
  final CustomerInfo? customer;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> allowedActions;
  final Map<String, dynamic> custom;
  final String? description;
  final String? rejectionReason;
  final DateTime? closedAt;
  final List<TicketAttachment> attachments;

  Ticket({
    required this.id,
    required this.number,
    required this.subject,
    required this.stage,
    this.priority = 0,
    dynamic assignee,
    dynamic customer,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
    this.allowedActions = const [],
    this.custom = const {},
    this.description,
    this.rejectionReason,
    this.closedAt,
    this.attachments = const [],
  })  : assignee = assignee is AssigneeEmployee
            ? assignee
            : (assignee is Map<String, dynamic>
                ? AssigneeEmployee.fromJson(assignee)
                : (assignee is Map ? AssigneeEmployee.fromJson(Map<String, dynamic>.from(assignee)) : null)),
        customer = customer is CustomerInfo
            ? customer
            : (customer is Map<String, dynamic>
                ? CustomerInfo.fromJson(customer)
                : (customer is Map ? CustomerInfo.fromJson(Map<String, dynamic>.from(customer)) : null));

  bool can(String action) => allowedActions.contains(action);

  bool get isAssigned => assignee != null;
  String get assigneeName => assignee?.name ?? 'Unassigned';
  String get customerName => customer?.name ?? 'Customer';

  factory Ticket.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final int parsedId = rawId is int ? rawId : (int.tryParse(rawId?.toString() ?? '') ?? 0);
    final rawPriority = json['priority'];
    final int parsedPriority = rawPriority is int ? rawPriority : (int.tryParse(rawPriority?.toString() ?? '') ?? 0);

    return Ticket(
      id: parsedId,
      number: json['number'] as String? ?? '#$parsedId',
      subject: json['subject'] as String? ?? '',
      stage: TicketStage.fromJson(json['stage'] as Map<String, dynamic>? ?? {}),
      priority: parsedPriority,
      assignee: json['assignee'] is Map ? Map<String, dynamic>.from(json['assignee']) : null,
      customer: json['customer'] is Map ? Map<String, dynamic>.from(json['customer']) : null,
      tags: (json['tags'] as List?)?.map((t) => (t as Map)['name'].toString()).toList() ?? [],
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
      allowedActions: (json['allowed_actions'] as List?)?.map((e) => e.toString()).toList() ?? [],
      custom: json['custom'] is Map ? Map<String, dynamic>.from(json['custom']) : {},
      description: (json['description'] is String && (json['description'] as String).isNotEmpty)
          ? json['description'] as String
          : null,
      rejectionReason: (json['rejection_reason'] is String && (json['rejection_reason'] as String).isNotEmpty)
          ? json['rejection_reason'] as String
          : null,
      closedAt: json['closed_at'] != null ? DateTime.tryParse(json['closed_at']) : null,
      attachments: (json['attachments'] as List?)
              ?.map((a) => TicketAttachment.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'subject': subject,
    'stage': stage.toJson(),
    'priority': priority,
    'assignee': assignee?.toJson(),
    'customer': customer?.toJson(),
    'tags': tags.map((t) => {'name': t}).toList(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'allowed_actions': allowedActions,
    'custom': custom,
    'description': description,
    'rejection_reason': rejectionReason,
    'closed_at': closedAt?.toIso8601String(),
  };
}
