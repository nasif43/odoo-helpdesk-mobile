import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/ticket_fields_schema.dart';

class DynamicFieldForm extends StatelessWidget {
  final List<SchemaField> fields;
  final Map<String, dynamic> values;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final bool isEdit;

  const DynamicFieldForm({
    super.key,
    required this.fields,
    required this.values,
    required this.onChanged,
    this.isEdit = false,
  });

  void _updateValue(String fieldName, dynamic value) {
    final updated = Map<String, dynamic>.from(values);
    updated[fieldName] = value;
    onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) return const SizedBox.shrink();

    // Group fields by section
    final Map<String, List<SchemaField>> sections = {};
    for (final f in fields) {
      if (!isEdit && !f.showOnCreate) continue;
      if (isEdit && !f.showOnDetail) continue;
      sections.putIfAbsent(f.section, () => []).add(f);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                entry.key,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            ...entry.value.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildFieldWidget(context, f),
                )),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFieldWidget(BuildContext context, SchemaField f) {
    final val = values[f.name];

    switch (f.type) {
      case 'char':
      case 'text':
        return TextFormField(
          initialValue: val?.toString() ?? '',
          maxLines: f.type == 'text' ? 3 : 1,
          decoration: InputDecoration(
            labelText: '${f.label}${f.required ? ' *' : ''}',
            helperText: f.help.isNotEmpty ? f.help : null,
          ),
          onChanged: (v) => _updateValue(f.name, v),
          validator: (v) {
            if (f.required && (v == null || v.trim().isEmpty)) {
              return '${f.label} is required';
            }
            return null;
          },
        );

      case 'selection':
        return DropdownButtonFormField<String>(
          initialValue: val is Map ? val['value']?.toString() : val?.toString(),
          decoration: InputDecoration(
            labelText: '${f.label}${f.required ? ' *' : ''}',
          ),
          items: f.options
              .map((opt) => DropdownMenuItem(
                    value: opt.value,
                    child: Text(opt.label),
                  ))
              .toList(),
          onChanged: (v) => _updateValue(f.name, v),
          validator: (v) {
            if (f.required && (v == null || v.isEmpty)) {
              return '${f.label} is required';
            }
            return null;
          },
        );

      case 'boolean':
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${f.label}${f.required ? ' *' : ''}'),
          value: val is bool ? val : false,
          onChanged: (v) => _updateValue(f.name, v),
        );

      case 'date':
        return _DateFieldWidget(
          field: f,
          initialValue: val?.toString(),
          onChanged: (formatted) => _updateValue(f.name, formatted),
        );

      case 'monetary':
      case 'integer':
      case 'float':
        return TextFormField(
          initialValue: val?.toString() ?? '',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: '${f.label}${f.required ? ' *' : ''}',
            prefixText: f.type == 'monetary' ? '\$ ' : null,
          ),
          onChanged: (v) {
            if (f.type == 'integer') {
              _updateValue(f.name, int.tryParse(v) ?? 0);
            } else {
              _updateValue(f.name, double.tryParse(v) ?? 0.0);
            }
          },
        );

      default:
        // Unsupported types are skipped gracefully as required by spec Section 14.3
        return const SizedBox.shrink();
    }
  }
}

class _DateFieldWidget extends StatefulWidget {
  final SchemaField field;
  final String? initialValue;
  final ValueChanged<String> onChanged;

  const _DateFieldWidget({
    required this.field,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_DateFieldWidget> createState() => _DateFieldWidgetState();
}

class _DateFieldWidgetState extends State<_DateFieldWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant _DateFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && (widget.initialValue ?? '') != _controller.text) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: '${widget.field.label}${widget.field.required ? ' *' : ''}',
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        hintText: 'Select date',
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: const Icon(Icons.event_outlined, color: AppTheme.primaryTeal, size: 20),
        suffixIcon: const Icon(Icons.calendar_month_rounded, color: AppTheme.primaryTeal, size: 20),
        filled: true,
        fillColor: AppTheme.surfaceCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.hairlineBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.hairlineBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
        ),
      ),
      validator: (v) {
        if (widget.field.required && (v == null || v.trim().isEmpty)) {
          return '${widget.field.label} is required';
        }
        return null;
      },
      onTap: () async {
        DateTime initialDate = DateTime.now();
        if (_controller.text.isNotEmpty) {
          final parsed = DateTime.tryParse(_controller.text);
          if (parsed != null) initialDate = parsed;
        }

        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppTheme.primaryTeal,
                  onPrimary: Colors.white,
                  onSurface: AppTheme.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          final formatted = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
          setState(() {
            _controller.text = formatted;
          });
          widget.onChanged(formatted);
        }
      },
    );
  }
}
