# Odoo Helpdesk Mobile Suite 📱⚡

An enterprise-grade, full-stack mobile solution for **Odoo 19 Helpdesk**, featuring a modern **Flutter** cross-platform client and a native **Odoo 19 REST API Addon**. Built with high-performance responsive UI, real-time stage workflow steppers, dynamic custom field reflection, and role-based access for both customers and support employees.

---

## 🌟 Key Highlights

- **Dual-Role Architecture**:
  - **Customer Portal**: Create incident tickets, choose urgency levels, pick incident dates with immediate visual feedback, track stage progression, and converse directly with support agents.
  - **Executive & Employee Hub**: Comprehensive dashboard with live KPI counters (`Needs Review`, `Unassigned Triage`, `Urgent Priority`, `Assigned to Me`), stage distribution metrics, and rapid employee assignment.
- **Dynamic Odoo 19 Schema Reflection**:
  - Fields such as `Site Location`, `Urgency Notes`, `Requires On-Site Visit`, and `Incident Date` are dynamically reflected from Odoo model metadata into native Flutter widgets.
- **Strict Team Stage Scoping**:
  - Real-time workflow stepper scoped to exact team stages (`New` → `Approved` → `Tracking` → `Work In Progress` → `Solving` → `Done` / `Rejected`), eliminating orphaned stages and preserving clean audit histories.
- **Employee-Centric Assignment**:
  - Fully integrated with Odoo's `hr.employee` directory for rich employee attribution (job title, department badge, workload counter) rather than raw database user IDs.
- **Human-Friendly Updates**:
  - All ticket chatter, stage audit logs, and push notification payloads are stripped of technical HTML entities and raw database keys, displaying clear layman-friendly summaries.
- **Production-Hardened**:
  - Null-safe, robust type parsing (`priority`, `id`, `datetime`), Riverpod session lifecycle management, and 100% clean static analysis (`flutter analyze: 0 issues`).

---

## 🏗️ Repository Architecture

```text
odoo-helpdesk-mobile/
├── lib/                               # Flutter Application Source
│   ├── app/                           # App routing (GoRouter) & theme definitions
│   ├── core/                          # Network client (Dio), error handlers, dialogs
│   ├── features/
│   │   ├── admin/                     # Dashboard, All Tickets, Bulk Triage, Customers
│   │   ├── auth/                      # Login, Registration, Biometrics, Forgot Password
│   │   ├── notifications/             # Notification Inbox & Alerts
│   │   ├── profile/                   # User Profile, Preferences & Sign-Out
│   │   └── tickets/                   # Ticket List, Detail, Creation & Stepper
│   └── main.dart                      # Application Entrypoint
├── backend/
│   └── helpdesk_mobile_api/           # Native Odoo 19 REST API Module
│       ├── controllers/               # Auth, Tickets, Meta & Notifications endpoints
│       ├── models/                    # Mobile Token & schema extension models
│       ├── security/                  # Access Control Lists (ir.model.access.csv)
│       └── __manifest__.py            # Odoo Module Manifest
├── test/                              # Comprehensive Unit & Widget Test Suite
├── openapi.yaml                       # Complete OpenAPI 3.0 API Specification
└── README.md                          # Project Documentation
```

---

## 🚀 Quick Start Guide

### 1. Backend Setup (Odoo 19)

1. **Link or Place Addon**:
   Ensure `backend/helpdesk_mobile_api` is in your Odoo `addons_path`:
   ```bash
   addons_path = /path/to/odoo/addons,/path/to/odoo_enterprise,/path/to/odoo-helpdesk-mobile/backend
   ```
2. **Install Module**:
   Restart Odoo and update the app list, then install `helpdesk_mobile_api`:
   ```bash
   odoo-bin -c odoo.conf -d your_database -i helpdesk_mobile_api
   ```
3. **Verify API Endpoints**:
   ```bash
   curl -s http://127.0.0.1:8069/api/v1/health
   # Returns: {"status": "ok", "version": "19.0"}
   ```

### 2. Mobile App Setup (Flutter)

1. **Install Dependencies**:
   ```bash
   flutter pub get
   ```
2. **Configure API Base URL**:
   The application defaults to the permanent 24/7 backend deployed on `tender-server`:
   ```dart
   static const String permanentServerUrl = 'https://tender.metamorphosis.com.bd';
   ```
   You can override this in `lib/core/network/api_client.dart` if testing against a custom local or staging host.
3. **Run Unit & Widget Tests**:
   ```bash
   flutter test
   ```
4. **Run Static Analysis**:
   ```bash
   flutter analyze
   ```
5. **Launch on Physical Device or Emulator**:
   ```bash
   # Run in debug mode
   flutter run

   # Or build optimized APK
   flutter build apk --debug --split-per-abi
   ```

### 3. Direct Download & Releases

Pre-compiled Android APK binaries (including `helpdeskapp_311026_v1.apk`) are available under GitHub Releases:
- Download the latest APK from the [Releases](https://github.com/nasif43/odoo-helpdesk-mobile/releases) tab.
- Install directly to your connected Android phone:
  ```bash
  adb install -r releaseApk/helpdeskapp_311026_v1.apk
  ```

---

## 🔐 Demo Credentials

| Role | Email | Password | Scope |
| :--- | :--- | :--- | :--- |
| **Support Lead / Admin** | `admin@helpdesk.local` | `admin123` | Full access, dashboard KPIs, bulk actions, stage approval |
| **Enterprise Customer** | `customer1@acme.com` | `customer123` | My Tickets, Ticket Creation, Conversation & Updates |

---

## 🧪 Testing & Verification

The suite includes 15 automated unit and widget tests covering:
- Ticket repository stage transitions (`New` → `Approved` → `Done` / `Reopen`).
- Dynamic schema deserialization for custom fields.
- Priority resilience (parsing integers and strings).
- Employee assignee deserialization and workload counters.
- Stage filtering and search scoping.

Run tests anytime with:
```bash
flutter test
```

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.
