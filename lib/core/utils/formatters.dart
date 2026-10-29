/// Human-friendly formatting utilities to eliminate developer lingo and technical semantics.
class Formatters {
  static const Map<String, String> _knownFieldLabels = {
    'x_site_location': 'Site Location',
    'x_urgency_notes': 'Urgency Notes',
    'x_requires_onsite': 'Requires On-Site Visit',
    'x_incident_date': 'Incident Date',
    'x_estimated_cost': 'Estimated Cost',
    'x_equipment_serial': 'Equipment Serial Number',
    'x_asset_tag': 'Asset Tag',
    'x_room_number': 'Room Number',
    'x_rejection_reason': 'Rejection Reason',
  };

  /// Converts snake_case and technical field names into natural, polished English labels.
  /// Example: 'x_site_location' -> 'Site Location', 'is_closed' -> 'Is Closed'
  static String humanizeFieldName(String key) {
    final lowerKey = key.toLowerCase().trim();
    if (_knownFieldLabels.containsKey(lowerKey)) {
      return _knownFieldLabels[lowerKey]!;
    }

    // Strip custom field prefix 'x_'
    var clean = key.startsWith('x_') ? key.substring(2) : key;

    // Split words by underscore or camelCase
    clean = clean.replaceAll('_', ' ');
    final words = clean.split(RegExp(r'\s+'));

    return words.map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Formats custom field values into clean, layman-friendly text.
  /// Booleans become 'Yes' or 'No', selection maps extract their human 'label', nulls become empty.
  static String formatCustomValue(dynamic value) {
    if (value == null) return '';

    if (value is bool) {
      return value ? 'Yes' : 'No';
    }

    if (value is Map) {
      if (value.containsKey('label') && value['label'] != null) {
        return value['label'].toString();
      }
      if (value.containsKey('name') && value['name'] != null) {
        return value['name'].toString();
      }
      if (value.containsKey('value') && value['value'] != null) {
        return humanizeFieldName(value['value'].toString());
      }
      return value.values.map((v) => v.toString()).join(', ');
    }

    if (value is num) {
      // If it's a zero floating cost or integer
      if (value == value.roundToDouble() && value is! int) {
        return value.toInt().toString();
      }
      return value.toString();
    }

    final str = value.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'null' || str.toLowerCase() == 'false') {
      return '';
    }
    if (str.toLowerCase() == 'true') {
      return 'Yes';
    }

    return cleanHtml(str);
  }

  /// Decodes HTML entities and strips HTML tags, returning clean, natural, human-readable text.
  static String cleanHtml(String html) {
    if (html.isEmpty) return '';

    var clean = html;

    // 1. Unescape escaped tag brackets if double-escaped like &lt;strong&gt;
    clean = clean.replaceAll('&lt;', '<').replaceAll('&gt;', '>');

    // 2. Strip HTML tags and replace with a space so words don't merge
    clean = clean.replaceAll(RegExp(r'<[^>]*>'), ' ');

    // 3. Unescape standard HTML entities
    clean = clean
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#8217;', "'")
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"');

    // 4. Decode numeric unicode entities &#123; and &#x1F;
    clean = clean.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      final code = int.tryParse(match.group(1)!);
      return code != null ? String.fromCharCode(code) : match.group(0)!;
    });
    clean = clean.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
      final code = int.tryParse(match.group(1)!, radix: 16);
      return code != null ? String.fromCharCode(code) : match.group(0)!;
    });

    // 5. Clean up excessive whitespace and newlines
    clean = clean.replaceAll(RegExp(r'[ \t]+'), ' ');
    clean = clean.replaceAll(RegExp(r'\n\s*\n+'), '\n').trim();

    return clean;
  }

  /// Generates a friendly relative timestamp for ticket updates and activities.
  static String formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative || difference.inSeconds < 45) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '${mins}m ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '${hours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dateTime.month - 1]} ${dateTime.day}';
    }
  }
}
