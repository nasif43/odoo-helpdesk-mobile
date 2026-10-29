import 'package:flutter_test/flutter_test.dart';
import 'package:odoo_helpdesk_mobile/core/utils/formatters.dart';

void main() {
  group('Formatters Tests', () {
    test('cleanHtml decodes entities and strips html tags properly', () {
      expect(
        Formatters.cleanHtml('<p>Stage changed to &lt;strong&gt;Done&lt;/strong&gt; by Marcus Vance.</p>'),
        'Stage changed to Done by Marcus Vance.',
      );

      expect(
        Formatters.cleanHtml('Ticket assigned to David Kim &amp; verified &quot;cleanly&quot;&#39;s update'),
        'Ticket assigned to David Kim & verified "cleanly"\'s update',
      );

      expect(Formatters.cleanHtml('<p></p>'), '');
      expect(Formatters.cleanHtml('   <p>   <br>  </p>  '), '');
      expect(Formatters.cleanHtml(''), '');
    });

    test('formatCustomValue handles empty strings and booleans cleanly', () {
      // Booleans
      expect(Formatters.formatCustomValue(true), 'Yes');
      expect(Formatters.formatCustomValue(false), 'No');

      // Empty / falsy strings from Odoo false or empty text fields
      expect(Formatters.formatCustomValue('false'), '');
      expect(Formatters.formatCustomValue('null'), '');
      expect(Formatters.formatCustomValue(''), '');
      expect(Formatters.formatCustomValue(null), '');

      // Valid text and dates
      expect(Formatters.formatCustomValue('2026-10-30'), '2026-10-30');
      expect(Formatters.formatCustomValue('Urgent server reboot needed'), 'Urgent server reboot needed');

      // Selection maps
      expect(Formatters.formatCustomValue({'value': 'branch_dhaka', 'label': 'Dhaka Branch'}), 'Dhaka Branch');
    });

    test('humanizeFieldName converts snake_case to human words', () {
      expect(Formatters.humanizeFieldName('x_urgency_notes'), 'Urgency Notes');
      expect(Formatters.humanizeFieldName('x_requires_onsite'), 'Requires On-Site Visit');
      expect(Formatters.humanizeFieldName('x_incident_date'), 'Incident Date');
      expect(Formatters.humanizeFieldName('random_custom_prop'), 'Random Custom Prop');
    });
  });
}
