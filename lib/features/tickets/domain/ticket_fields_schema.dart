class SchemaFieldOption {
  final String value;
  final String label;

  const SchemaFieldOption({required this.value, required this.label});

  factory SchemaFieldOption.fromJson(Map<String, dynamic> json) {
    return SchemaFieldOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class SchemaField {
  final String name;
  final String label;
  final String type;
  final String section;
  final int sequence;
  final bool required;
  final String help;
  final List<SchemaFieldOption> options;
  final bool showOnCreate;
  final bool showOnDetail;
  final bool showInList;
  final bool filterable;

  const SchemaField({
    required this.name,
    required this.label,
    required this.type,
    this.section = 'Additional Information',
    this.sequence = 10,
    this.required = false,
    this.help = '',
    this.options = const [],
    this.showOnCreate = true,
    this.showOnDetail = true,
    this.showInList = false,
    this.filterable = false,
  });

  factory SchemaField.fromJson(Map<String, dynamic> json) {
    final show = json['show'] as Map<String, dynamic>? ?? {};
    final opts = (json['options'] as List?)
            ?.map((o) => SchemaFieldOption.fromJson(o as Map<String, dynamic>))
            .toList() ??
        [];

    return SchemaField(
      name: json['name'] as String? ?? '',
      label: json['label'] as String? ?? '',
      type: json['type'] as String? ?? 'char',
      section: json['section'] as String? ?? 'Additional Information',
      sequence: json['sequence'] as int? ?? 10,
      required: json['required'] as bool? ?? false,
      help: json['help'] as String? ?? '',
      options: opts,
      showOnCreate: show['create'] as bool? ?? true,
      showOnDetail: show['detail'] as bool? ?? true,
      showInList: show['list'] as bool? ?? false,
      filterable: json['filterable'] as bool? ?? false,
    );
  }
}

class FieldsSchemaResponse {
  final String version;
  final List<SchemaField> fields;

  const FieldsSchemaResponse({required this.version, required this.fields});

  factory FieldsSchemaResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['fields'] as List?)
            ?.map((f) => SchemaField.fromJson(f as Map<String, dynamic>))
            .toList() ??
        [];
    return FieldsSchemaResponse(
      version: json['version'] as String? ?? '1.0',
      fields: list,
    );
  }
}
