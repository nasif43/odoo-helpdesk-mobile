# Odoo Helpdesk Mobile App (Flutter) — Master Specification

Version 1.0 · Audience: development agent (Antigravity) and human reviewers · Status: ready for implementation

## 1. Purpose and scope

Build a Flutter mobile app (Android and iOS) on top of the existing Odoo Helpdesk module. The app serves two user classes:

- **Customer**: registers or logs in, raises tickets, tracks their status, chats with support, and confirms or closes tickets.
- **Admin** (the business owner): sees all tickets, approves or rejects them, assigns them, moves them through stages, replies, and monitors the overall workload.

The complete ticket lifecycle (create → approve → assign → track → work → solve → done) must be possible entirely from the app. Odoo remains the single source of truth: tickets created in the app appear in the Odoo backend, and changes made in Odoo appear in the app.

### Out of scope for v1

SLA configuration, helpdesk team and stage configuration, billing or timesheets, multi-company switching, knowledge base, live chat, and web portal replacement. These stay in the Odoo backend.

## 2. Assumptions and decisions (confirm before build)

1. **Odoo version**: 18 or 19 (Enterprise, `helpdesk` module installed). Confirm the exact version and hosting (Odoo.sh, on-premise, Odoo Online). Odoo Online does not allow custom addons, which changes the API approach (see 5.1).
2. **Role mapping**: Customers are Odoo **portal users** (`share = True`). Admin is an **internal user** in the group *Helpdesk / Administrator* (`helpdesk.group_helpdesk_manager`). Role is derived on the server at login; the app never trusts a client-chosen role.
3. **Single helpdesk team** for v1 (for example "Customer Support"), configurable later. The team id is a server-side setting.
4. **Approval** is modelled with stages, not a new Odoo concept: new tickets land in stage *New* (pending approval); the admin either approves (moves to *Approved*) or rejects (moves to *Rejected*, a closing stage).
5. **Stages are fetched dynamically** from Odoo (`helpdesk.stage`). The app must not hard-code stage ids. Stage *names* below are the recommended configuration.
6. **A thin API layer inside Odoo** is the recommended integration (custom addon `helpdesk_mobile_api`), instead of the app calling raw `call_kw` ORM methods. Reasons: smaller attack surface, stable contract across Odoo upgrades, server-side role checks, push notification hooks, and cleaner pagination and errors.

## 3. Odoo configuration required (backend checklist)

- Helpdesk team created and active; assignment method set (manual is fine, admin assigns).
- Stages on the team, in order:

| Seq | Stage | Closing stage | Meaning |
| --- | --- | --- | --- |
| 1 | New | No | Raised by customer, awaiting approval |
| 2 | Approved | No | Accepted by admin, ready to assign |
| 3 | Tracking | No | Assigned, being tracked or triaged |
| 4 | Work In Progress | No | Actively being worked on |
| 5 | Solving | No | Fix applied, in verification |
| 6 | Done | Yes | Resolved and closed |
| 7 | Rejected | Yes | Declined by admin (reason required) |

- Ticket types and tags created (for example Bug, Question, Request) and exposed as dropdown values.
- Priority uses Odoo's native 0–3 star scale (0 Normal, 1 Low, 2 High, 3 Urgent).
- Portal access enabled for customers; record rules ensure a portal user sees only tickets where `partner_id` is their own partner (default Odoo portal behaviour; verify).
- Optional: email templates on stage change, which keep working alongside push notifications.
- Server-side **API key / JWT** secret and FCM service account stored in Odoo system parameters or environment config, never in the app.

## 4. Functional requirements

### 4.1 Authentication and session (both roles)

- FR-A1: Login with email and password. Server returns tokens and the user profile with `role` (`customer` or `admin`).
- FR-A2: Customer self-registration (name, email, phone, password) creating a portal user and partner. Email verification is recommended (configurable). If the business prefers invite-only customers, hide registration behind a flag.
- FR-A3: Forgot and reset password via Odoo's reset flow (email link) and a mobile-friendly confirmation screen.
- FR-A4: Short-lived access token plus refresh token; refresh is silent. Logout revokes the refresh token and unregisters the push device token.
- FR-A5: Tokens are stored only in secure storage. Optional biometric unlock on app resume.
- FR-A6: After login the app routes to the customer shell or the admin shell based on `role`.

### 4.2 Customer features

- FR-C1: **Create ticket**: subject (required), description (required), ticket type, priority (optional), attachments (up to 5 images or files, 10 MB each). Customer name and email are taken from the profile.
- FR-C2: **My tickets list**: filter by status group (Open, In progress, Done, Rejected), search by subject or ticket number, newest first, pull-to-refresh, infinite scroll.
- FR-C3: **Ticket detail**: reference number, subject, description, stage timeline, assigned agent name, priority, type, created and last updated times, attachments, and the conversation thread.
- FR-C4: **Reply**: add a message and attachments to the thread while the ticket is not closed.
- FR-C5: **Status visibility**: a visual stage progress indicator (New → Approved → Tracking → Work In Progress → Solving → Done) and a clear Rejected state with the admin's reason.
- FR-C6: **Confirm or reopen**: when the ticket reaches *Solving* or *Done*, the customer can confirm resolution or reopen with a comment (reopen moves the ticket back to *Work In Progress*; the admin is notified). Reopen is allowed within a configurable window (default 7 days).
- FR-C7: **Rate** a closed ticket (1–5 stars and an optional comment). Uses Odoo's rating mechanism if the Customer Ratings feature is enabled; otherwise hide it.
- FR-C8: **Notifications**: push and in-app inbox for stage changes, assignment, and new agent replies.
- FR-C9: **Profile**: view and edit name, phone, language; change password; manage notification preference; delete account request (stores a request, does not delete data automatically).

### 4.3 Admin features

- FR-D1: **Dashboard**: counts by stage (New, Approved, Tracking, Work In Progress, Solving, Done), tickets awaiting approval, unassigned tickets, urgent tickets, tickets assigned to me, and recent activity.
- FR-D2: **All tickets list**: filters by stage, assignee, priority, type, customer, and date range; search by number, subject, or customer name; sort by created, updated, or priority; saved quick filters (Needs approval, Unassigned, Mine, Overdue).
- FR-D3: **Ticket detail (admin view)**: everything the customer sees, plus customer contact details, internal notes (never visible to the customer), assignee, and a full audit history of stage changes.
- FR-D4: **Approve or reject**: from a ticket in *New*. Approve moves it to *Approved* and can optionally set priority and assignee in one step. Reject requires a reason that is posted to the customer.
- FR-D5: **Assign**: pick an assignee from helpdesk team members (users of the team). The assignee is notified.
- FR-D6: **Change stage**: move the ticket to any allowed stage (Tracking, Work In Progress, Solving, Done). Optional comment posted with the change. Forward and backward moves both allowed for admin.
- FR-D7: **Change priority, type, and tags**.
- FR-D8: **Reply and internal notes**: toggle between *Reply to customer* (sends message and email) and *Internal note* (admin-only).
- FR-D9: **Bulk actions** on the list: approve selected, assign selected, change stage for selected (max 50 per action).
- FR-D10: **Notifications**: push for new tickets, customer replies, and customer reopen or confirmation actions.
- FR-D11: **Customers directory** (read-only): list of customers with their ticket counts, tapping opens their tickets.
- FR-D12: **Settings**: notification toggles, language, logout.

### 4.4 Cross-cutting

- FR-X1: **Real-time feel**: poll the ticket detail every 15–30 s while open, and refresh lists on push receipt and on app resume. WebSocket or Odoo bus support is a later enhancement.
- FR-X2: **Offline behaviour**: cached lists and tickets are readable offline with a banner. Creating a ticket or reply offline is queued locally and sent when back online, with a visible "pending" state and retry.
- FR-X3: **Localization**: English and Bengali, with a language switcher; all strings externalized (ARB files); dates in the user's locale; timezone from the Odoo user.
- FR-X4: **Accessibility**: scalable text, sufficient contrast, semantic labels, light and dark themes.
- FR-X5: **Attachments**: preview images and PDFs; download others via the system share sheet.
- FR-X6: **Deep links** from push notifications open the exact ticket.

## 5. API plan

### 5.1 Integration approach

**Primary (recommended)**: custom Odoo addon `helpdesk_mobile_api` exposing JSON endpoints under `/api/mobile/v1/`, implemented with Odoo `http.Controller` routes (`type='json'` or `type='http'` with JSON bodies) with `auth='none'` plus our own token check, so that tokens, not browser sessions, are the mechanism. Controllers call the ORM with `.with_user(user)` so Odoo's record rules and access rights apply naturally; admin-only actions additionally check `helpdesk.group_helpdesk_manager`.

**Fallback (if custom addons are not possible, for example Odoo Online)**: use Odoo's standard external API directly: JSON-RPC (`/jsonrpc`, `/web/dataset/call_kw`) on Odoo 17/18, or the JSON-2 API (`/json/2/<model>/<method>`, bearer API key) on Odoo 19, against `helpdesk.ticket`, `helpdesk.stage`, `mail.message`, and `ir.attachment`. In that case the Flutter repository layer maps the same contract below onto ORM calls. Keep the Flutter data layer behind the repository interfaces so either backend works without UI changes. Push notifications in this mode require a separate small relay service.

The rest of this section specifies the primary approach. All endpoints return JSON.

### 5.2 Conventions

- Base URL configured per environment (dev, staging, prod); HTTPS only.
- Auth header: `Authorization: Bearer <access_token>`.
- Content type `application/json`, except uploads (multipart).
- Success envelope: `{"ok": true, "data": ..., "meta": {...}}`.
- Error envelope: `{"ok": false, "error": {"code": "STRING_CODE", "message": "Human readable", "fields": {"field": "msg"}}}` with proper HTTP status (400, 401, 403, 404, 409, 422, 429, 500).
- Pagination: `?page=1&page_size=20`; response `meta` contains `total`, `page`, `page_size`, `has_more`.
- Timestamps in ISO 8601 UTC.
- Idempotency: write endpoints accept an optional `Idempotency-Key` header (used by the offline queue to prevent duplicates).
- Rate limiting on login, register, and reset endpoints.
- Versioned path; the app sends `X-App-Version` and `X-Platform` and the server can answer `426 Upgrade Required`.

### 5.3 Endpoint catalogue

#### Auth

| Method | Path | Role | Purpose |
| --- | --- | --- | --- |
| POST | `/auth/login` | public | Email and password → `access_token`, `refresh_token`, `expires_in`, `user` |
| POST | `/auth/register` | public | Create portal user and partner (customer only) |
| POST | `/auth/refresh` | public | Exchange refresh token for new tokens (rotating) |
| POST | `/auth/logout` | any | Revoke refresh token |
| POST | `/auth/forgot-password` | public | Trigger Odoo reset email |
| POST | `/auth/change-password` | any | Old and new password |
| GET | `/me` | any | Profile, role, permissions, team info |
| PATCH | `/me` | any | Update name, phone, language |
| POST | `/me/devices` | any | Register FCM token `{token, platform, app_version}` |
| DELETE | `/me/devices/{token}` | any | Unregister device |

#### Reference data

| Method | Path | Role | Purpose |
| --- | --- | --- | --- |
| GET | `/meta/stages` | any | Stages in order with `id`, `name`, `sequence`, `is_closed`, `fold` |
| GET | `/meta/ticket-types` | any | Ticket types |
| GET | `/meta/tags` | any | Tags |
| GET | `/meta/priorities` | any | Priority scale (0–3) with labels |
| GET | `/meta/agents` | admin | Assignable users of the helpdesk team |
| GET | `/meta/config` | any | Limits (attachment size and count), reopen window, feature flags (ratings, registration) |

#### Tickets (customer-scoped automatically; admin sees all)

| Method | Path | Role | Purpose |
| --- | --- | --- | --- |
| GET | `/tickets` | any | List. Query: `stage_id`, `stage_group`, `assignee_id`, `priority`, `type_id`, `customer_id`, `q`, `date_from`, `date_to`, `sort`, `page`, `page_size`. Customers only get their own |
| POST | `/tickets` | customer, admin | Create `{subject, description, type_id?, priority?, attachment_ids?}`. Server sets team, partner, stage *New* |
| GET | `/tickets/{id}` | any | Detail incl. stage, assignee, SLA info if enabled, attachments, timeline |
| GET | `/tickets/{id}/messages` | any | Conversation thread (paged); internal notes only for admin |
| POST | `/tickets/{id}/messages` | any | Post `{body, attachment_ids?, internal?}`. `internal=true` admin only |
| GET | `/tickets/{id}/history` | any | Stage and assignment changes (customers see stage changes only) |
| POST | `/tickets/{id}/confirm` | customer | Confirm resolution (moves to *Done* if allowed) |
| POST | `/tickets/{id}/reopen` | customer | Reopen with `{reason}`; enforces reopen window |
| POST | `/tickets/{id}/rating` | customer | `{rating, comment?}` for closed tickets |

#### Admin actions

| Method | Path | Role | Purpose |
| --- | --- | --- | --- |
| POST | `/tickets/{id}/approve` | admin | Optional `{priority?, assignee_id?, comment?}` → stage *Approved* |
| POST | `/tickets/{id}/reject` | admin | `{reason}` (required) → stage *Rejected* |
| POST | `/tickets/{id}/assign` | admin | `{assignee_id}` (null to unassign) |
| POST | `/tickets/{id}/stage` | admin | `{stage_id, comment?}` |
| PATCH | `/tickets/{id}` | admin | Update `priority`, `type_id`, `tag_ids` |
| POST | `/tickets/bulk` | admin | `{ids[], action: approve\|assign\|stage, params}` (max 50), returns per-id result |
| GET | `/dashboard` | admin | Counts by stage, awaiting approval, unassigned, urgent, mine, recent activity |
| GET | `/customers` | admin | Paged customer list with ticket counts |

#### Attachments and notifications

| Method | Path | Role | Purpose |
| --- | --- | --- | --- |
| POST | `/attachments` | any | Multipart upload (staged, not yet linked) → `{id, name, mimetype, size}` |
| GET | `/attachments/{id}` | any | Authenticated download; checked against ticket access |
| GET | `/notifications` | any | In-app notification inbox (paged) |
| POST | `/notifications/{id}/read` | any | Mark read; `/notifications/read-all` also provided |

### 5.4 Key payload shapes

**Ticket (summary)**

```json
{
  "id": 128,
  "number": "#128",
  "subject": "Printer not working",
  "stage": {"id": 4, "name": "Work In Progress", "is_closed": false},
  "priority": 2,
  "type": {"id": 1, "name": "Issue"},
  "assignee": {"id": 7, "name": "Rafi Ahmed", "avatar_url": "..."},
  "customer": {"id": 55, "name": "Acme Ltd"},
  "created_at": "2026-10-28T08:12:00Z",
  "updated_at": "2026-10-28T09:40:00Z",
  "unread_count": 1
}
```

**Ticket (detail)** extends the summary with: `description` (HTML sanitized to a safe subset), `tags[]`, `attachments[]`, `allowed_actions[]` (for example `["reply","confirm","reopen"]` for customers or `["approve","reject","assign","change_stage","internal_note"]` for admin), `rejection_reason`, `closed_at`, `sla` (if used).

The app drives button visibility from `allowed_actions`, so business rules live on the server.

### 5.5 Business rules enforced by the server

1. Customers can only see and act on their own tickets.
2. Only admin can approve, reject, assign, change stage, edit metadata, and post internal notes.
3. Approve and reject are valid only from stage *New*.
4. Reject requires a reason; the reason is posted to the thread as a customer-visible message.
5. Closed tickets (*Done*, *Rejected*) reject customer replies except reopen; admin may still move a ticket out of a closed stage.
6. Customer reopen is allowed only within the reopen window and only from *Solving* or *Done*.
7. Every stage change, assignment, and approval posts a tracking message on the ticket so Odoo's chatter stays consistent with the app.
8. Attachments are scanned for type and size limits (allow-list: jpg, png, webp, pdf, txt, docx, xlsx, zip is optional).
9. Concurrent edits: stage change requests may send `If-Match` with the ticket's `write_date`; on mismatch return `409 CONFLICT` and the app refreshes.

### 5.6 Push notifications

- Use Firebase Cloud Messaging (APNs through FCM on iOS).
- Odoo-side model `helpdesk.mobile.device` (user, token, platform, last seen). The addon sends pushes from `create`/`write` overrides on `helpdesk.ticket` and `mail.message`, via a queued job (`ir.cron` or `queue_job`) so requests are not blocked.
- Events and recipients:

| Event | Customer | Admin |
| --- | --- | --- |
| Ticket created | Confirmation | Yes (needs approval) |
| Approved or rejected | Yes | No |
| Assigned | Yes | Assignee |
| Stage changed | Yes | No |
| New message | If from agent | If from customer |
| Reopened or confirmed | No | Yes |

- Payload carries `type`, `ticket_id`, and a short body; tapping opens `/tickets/{id}`. No sensitive text in the push body beyond subject.

### 5.7 Security

- Passwords never stored on the device; tokens in `flutter_secure_storage`.
- Access token lifetime 15–30 minutes; refresh tokens rotate and are revocable per device.
- All object access re-checked server-side (never rely on client-supplied ids).
- Input validation and HTML sanitization on descriptions and messages; escape on render.
- TLS only; optional certificate pinning in production builds.
- No Odoo master password, database manager, or admin credentials ever reach the client.
- Audit: log admin actions with user and timestamp.
- Compliance: privacy policy, data deletion request path, and minimal personal data.

## 6. Mobile app design

### 6.1 Technical stack (recommended defaults)

- **Flutter** stable, Dart 3, null-safe, Material 3.
- **State management**: Riverpod (with `riverpod_generator`) or Bloc; choose one and use it consistently.
- **Routing**: `go_router` with role-based redirects and deep links.
- **Networking**: `dio` with interceptors for auth, refresh-and-retry, logging (debug only), and error mapping to a typed `Failure`.
- **Models**: `freezed` and `json_serializable`.
- **Storage**: `flutter_secure_storage` (tokens), `drift` or `isar` (offline cache and queue), `shared_preferences` (settings).
- **Push**: `firebase_messaging` and `flutter_local_notifications`.
- **Media**: `image_picker`, `file_picker`, `cached_network_image`, `open_filex`/`share_plus`.
- **Localization**: `flutter_localizations` with ARB (en, bn).
- **Connectivity**: `connectivity_plus`.
- **Testing**: `flutter_test`, `mocktail`, `integration_test`, golden tests for key screens.

### 6.2 Architecture

Feature-first clean architecture:

```
lib/
  core/        # network, errors, theme, l10n, utils, storage
  features/
    auth/        (data, domain, presentation)
    tickets/     (data, domain, presentation)
    admin/       (dashboard, bulk, customers)
    notifications/
    profile/
  app/         # router, DI, app shell
```

Repositories expose interfaces (`TicketRepository`, `AuthRepository`, etc.) implemented against the REST contract in section 5; a mock implementation backed by fixtures must exist so the UI can be built and tested without a running Odoo.

### 6.3 Navigation map

- **Shared**: Splash → Login / Register / Forgot password → role router.
- **Customer shell** (bottom nav): Tickets · New Ticket · Notifications · Profile.
- **Admin shell** (bottom nav): Dashboard · Tickets · Notifications · Customers · Settings.

## 7. Screen inventory

### 7.1 Shared screens

| ID | Screen | Key elements |
| --- | --- | --- |
| S1 | Splash | Logo, session check, app version gate (force update) |
| S2 | Login | Email, password, show/hide, forgot link, register link (if enabled), server error states |
| S3 | Register | Name, email, phone, password, confirm, terms; success → verify email notice |
| S4 | Forgot password | Email field, confirmation message |
| S5 | Notifications inbox | Grouped by day, unread dot, tap to open ticket, mark all read |
| S6 | Profile and settings | Edit profile, language, theme, notification toggles, change password, delete-account request, logout, app version |
| S7 | Attachment viewer | Image zoom, PDF viewer, share or download |
| S8 | Generic states | Empty, error with retry, offline banner, no permission |

### 7.2 Customer screens

| ID | Screen | Key elements |
| --- | --- | --- |
| C1 | My tickets | Status chips (All, Open, In progress, Done, Rejected), search, ticket cards (number, subject, stage badge, priority, updated time, unread badge), pull-to-refresh, FAB new ticket |
| C2 | Create ticket | Subject, description, type picker, priority, attachment picker with thumbnails, validation, submit with progress, success screen with ticket number |
| C3 | Ticket detail | Header (number, stage badge, priority), stage progress stepper, description, attachments, assigned agent, thread, reply composer, contextual actions (confirm, reopen, rate) |
| C4 | Reopen dialog | Required reason, submit |
| C5 | Rate ticket | Stars and comment |

### 7.3 Admin screens

| ID | Screen | Key elements |
| --- | --- | --- |
| A1 | Dashboard | KPI tiles (Awaiting approval, Unassigned, Urgent, Mine), stage breakdown bars, recent activity list, tap-through to filtered lists |
| A2 | All tickets | Search, filter sheet (stage, assignee, priority, type, customer, dates), quick-filter chips, multi-select mode with bulk action bar |
| A3 | Ticket detail (admin) | All of C3 plus customer card (name, email, phone, tap to call or mail), action bar (Approve, Reject, Assign, Change stage), priority/type/tag editors, tabs: Conversation · Internal notes · History |
| A4 | Approve sheet | Optional priority, assignee, comment; confirm |
| A5 | Reject sheet | Reason (required), confirm |
| A6 | Assign sheet | Searchable agent list with workload counts, unassign option |
| A7 | Change stage sheet | Ordered stage list with current highlighted, optional comment, confirm |
| A8 | Bulk action sheet | Choose action and parameters, per-ticket result summary |
| A9 | Customers | Searchable list, ticket counts; tap opens A2 filtered by customer |
| A10 | Admin settings | Notification toggles per event, language, logout |

## 8. Ticket lifecycle (state flow)

1. Customer creates ticket → stage **New**; admin receives push.
2. Admin opens ticket → **Approve** (→ **Approved**) or **Reject** (→ **Rejected**, customer notified with reason).
3. Admin assigns an agent (can be combined with approval) and moves to **Tracking**.
4. Work starts → **Work In Progress**.
5. Fix applied → **Solving** (customer asked to verify).
6. Customer confirms, or admin closes → **Done**. If the customer reopens, the ticket returns to **Work In Progress**.
7. Every transition creates a thread message and a notification, visible in both the app and Odoo chatter.

Allowed transitions for admin: any stage to any stage (with comment encouraged). Customers can only trigger confirm and reopen.

## 9. Non-functional requirements

- **Performance**: list first paint under 1.5 s on 4G with cached data, API p95 under 800 ms, app cold start under 3 s.
- **Reliability**: network errors retried with backoff for idempotent calls; no data loss on offline writes.
- **Compatibility**: Android 8+ (API 26), iOS 14+; phones first, tablet layouts tolerated.
- **Observability**: crash reporting (Firebase Crashlytics or Sentry), non-PII analytics (screen views, action counts), server-side request logging with request ids.
- **Environments**: dev, staging, prod via Flutter flavors; build-time base URL; separate FCM projects.
- **CI/CD**: lint (`flutter analyze`), tests on every PR, signed release builds, store submission checklist.
- **Code quality**: no business rules in widgets; strings externalized; no hard-coded stage ids; secrets never committed.

## 10. Testing and acceptance

### Test scope

- Unit tests for repositories, mappers, and state notifiers.
- Widget tests for each screen state (loading, data, empty, error).
- Integration tests for the two golden paths below against a mock server, then against staging Odoo.
- API contract tests on the Odoo addon (access rights, record rules, state transitions).

### Acceptance criteria (summary)

1. A newly registered customer can log in, create a ticket with an image, and see it in Odoo Helpdesk in stage *New* under their own partner.
2. A customer cannot see any other customer's ticket by any means (list, id guess, attachment URL, push).
3. The admin receives a push, approves the ticket, assigns an agent, and moves it through Tracking, Work In Progress, Solving, and Done; every change is visible in Odoo chatter and in the customer's app with a push.
4. Reject without a reason is blocked; with a reason the customer sees it.
5. Internal notes never appear in any customer response.
6. Customer reopen within the window returns the ticket to *Work In Progress* and notifies admin; outside the window it is refused.
7. Offline-created ticket syncs once without duplicates after reconnect.
8. Changing stage names or order in Odoo is reflected in the app without a release.
9. English and Bengali render correctly across all screens.

## 11. Delivery plan

| Phase | Deliverables |
| --- | --- |
| 0 Setup | Confirm Odoo version and hosting, stage configuration, FCM project, flavors, repo, CI, design tokens |
| 1 Backend API | Addon `helpdesk_mobile_api`: auth, tickets, messages, attachments, meta, role checks, contract tests (or fallback repository layer) |
| 2 App foundation | Theme, l10n, routing, DI, networking, auth screens, mock repositories |
| 3 Customer flow | C1–C5, attachments, offline queue, notifications |
| 4 Admin flow | A1–A10, approvals, assignment, stage changes, internal notes, bulk actions |
| 5 Push and polish | FCM end to end, deep links, accessibility, performance pass |
| 6 QA and release | Test plan execution, UAT with the business owner, store listings, production rollout |

## 12. Open questions for the product owner

1. Exact Odoo version, edition, and hosting (decides custom addon versus direct API).
2. Is customer self-registration open, or invite-only by the admin?
3. Does one customer company have several app users who should share tickets?
4. Is there more than one helpdesk team or agent besides the owner, and should agents (non-admin staff) get an app role later?
5. Should the customer be able to close tickets themselves, or only confirm for the admin to close?
6. Are SLA deadlines, customer ratings, or email-to-ticket in use and should they appear in the app?
7. Required languages beyond English and Bengali, and branding assets (logo, colours).
8. Data retention and account deletion expectations.

## 13. Instructions for the implementing agent

- Treat this document as the source of truth; where something is marked *confirm*, implement behind a configuration flag and note the assumption in the README.
- Build against the mock repositories first, then swap to the real API through dependency injection.
- Do not hard-code stage ids, role names beyond `customer` and `admin`, or any base URL.
- Drive UI actions from `allowed_actions` returned by the API.
- Deliver in the phase order of section 11, with tests for each phase, and keep the API contract in section 5 as an OpenAPI file (`openapi.yaml`) generated alongside the code.

## 14. Addendum v1.1: Client-configurable custom fields

**Goal:** the client adds business-specific fields to tickets using Odoo's own configuration tools (Settings > Technical > Fields, or Odoo Studio if installed) and sees them in the app without an app release. The app is therefore **schema-driven** for ticket fields. No custom field is ever hard-coded in Flutter.

### 14.1 Principles

1. Odoo is the source of truth for field definitions (label, type, required, options, order).
2. **Opt-in exposure**: a custom field appears in the app only when explicitly exposed, so adding a technical or sensitive field in Odoo never leaks it to customers.
3. The app renders from a schema fetched at runtime and cached; schema changes propagate on the next refresh.
4. The server validates everything; client-side rules only mirror it for convenience.

### 14.2 What the client configures in Odoo

1. Create the field on the model *Helpdesk Ticket* (`helpdesk.ticket`). Technical name starts with `x_` (or `x_studio_` when made in Studio).
2. Add one row in a new menu *Helpdesk > Configuration > Mobile App Fields* (model `helpdesk.mobile.field.config`, shipped by the addon) with:

| Setting | Meaning |
| --- | --- |
| Field | Picker limited to custom fields of `helpdesk.ticket` |
| Section label | Optional group heading in the app |
| Sequence | Display order |
| Show on create form | Customer and admin create screens |
| Show on detail | Ticket detail screens |
| Show in list card | Up to 2 fields recommended |
| Filterable (admin) | Appears in the admin filter sheet |
| Visible to | Customer, Admin, or Both |
| Customer editable | Never, on create only, or always while open |
| Admin editable | Yes or No |
| Required in app | Adds to Odoo's own required flag |

If the custom addon is not possible (see section 15), the same keys are read from a JSON system parameter `helpdesk_mobile.fields` (Settings > Technical > System Parameters). Behaviour is identical for the app.

### 14.3 Supported field types

| Odoo type | App widget | Notes |
| --- | --- | --- |
| char | Single-line input | Max length from `size` if set |
| text | Multi-line input |  |
| html | Read-only rich text (sanitized) | Not editable in v1 |
| integer, float | Numeric input |  |
| monetary | Numeric input with currency symbol | Uses the field's currency |
| boolean | Switch |  |
| date, datetime | Pickers | ISO 8601; datetime in UTC, shown in local time |
| selection | Dropdown or chips | Options and localized labels from Odoo |
| many2one | Searchable picker | Via lookup endpoint, only for exposed fields |
| many2many (tags) | Multi-select chips | Via lookup endpoint |
| binary, image | Attachment picker | Stored as attachment linked to the ticket |
| one2many, related, computed | Read-only text if exposed | Never editable in v1 |
| properties, reference, others | Skipped | Server logs a warning and omits them from the schema |

### 14.4 API additions

**GET `/meta/ticket-fields`** returns the schema for the current user's role. It supports `ETag` and `If-None-Match`; `/meta/config` also returns `fields_schema_version` so the app knows when to refetch (on login, on resume, and when the version changes).

```json
{
  "ok": true,
  "data": {
    "version": "a91f3c",
    "fields": [
      {
        "name": "x_site_location",
        "label": "Site location",
        "type": "selection",
        "section": "Site details",
        "sequence": 10,
        "required": true,
        "help": "Where the issue is happening",
        "options": [{"value": "hq", "label": "Head office"}, {"value": "branch", "label": "Branch"}],
        "show": {"create": true, "detail": true, "list": true},
        "editable": {"customer": "create", "admin": true},
        "filterable": true
      }
    ]
  }
}
```

Relational fields add `"relation": {"lookup": "/meta/lookup/x_assigned_asset"}`. Monetary fields add `"currency": {"symbol": "BDT", "position": "before"}`. Labels and option labels follow the user's language (`Accept-Language`).

**Ticket payloads** gain a `custom` object keyed by technical name, values formatted by type: selection as `{"value","label"}`, many2one as `{"id","name"}`, many2many as an array of those, dates as ISO strings, booleans and numbers native.

**Writes**: `POST /tickets` and `PATCH /tickets/{id}` accept `"custom": {"x_site_location": "hq"}` (relational values sent as ids).

**GET `/meta/lookup/{field_name}?q=&page=`** returns `{id, name}` options for relational fields, limited to exposed fields and the user's access.

**Filtering**: `GET /tickets?custom[x_site_location]=hq` for fields flagged filterable (equality for selection, boolean, many2one; `_from` and `_to` suffixes for date and numeric).

### 14.5 Server rules

1. Only fields with an active config row and `Visible to` matching the caller's role appear in the schema or in any payload. Everything else is dropped, including from message tracking text sent to customers.
2. Writes are validated against the schema for the caller's role: unknown, hidden, or non-editable fields return `422` with per-field errors. Required rules and Odoo's own constraints apply.
3. Type coercion and parsing happen on the server; invalid values never reach the ORM.
4. Customer reads and writes go through Odoo access rights and record rules, so field-level `groups` set in Odoo are respected as an additional layer.
5. Deleting or archiving the Odoo field, or deactivating its config row, removes it from the schema on the next fetch. Stored data in Odoo is untouched.
6. Admin-created tickets honour the same required fields as customer-created ones.

### 14.5b App behaviour

- A generic `DynamicFieldForm` widget maps each schema entry to a widget by type; the create ticket screen (C2), the ticket detail (C3, A3), the admin filter sheet (A2) and the list card (C1, A2) all render from the schema.
- Fields are grouped under their section label and ordered by sequence; required fields are marked and validated before submit.
- Unknown or unsupported types are hidden (read-only text fallback at most); the app must never crash on an unrecognised type.
- The schema is cached locally with its version; offline create reuses the cached schema, and queued drafts store custom values by technical name.
- If the schema changed while a draft was queued, submission re-validates and surfaces any new required field to the user.
- Admin edits custom fields from the ticket detail (A3) in the same way as priority and type, where `editable.admin` is true.

### 14.6 Acceptance criteria

1. A new selection field added in Odoo and exposed through a config row appears in the customer create form and in the ticket detail after the next schema refresh, with no app release.
2. A field marked admin-only never appears in any customer response (schema, ticket, list, push, history).
3. Required custom fields block submission in the app and are also rejected by the server when bypassed.
4. Changing a label, option, order, or section in Odoo is reflected in the app; removing the config row removes the field.
5. Filterable fields appear in the admin filter sheet and filtering returns correct results.
6. All supported types in 14.3 round-trip correctly (create in app, visible in Odoo, edit in Odoo, visible in app).
7. A field of an unsupported type is ignored gracefully and logged.

### 14.7 Later (not v1)

Conditional visibility and required rules (Studio-style), custom fields per ticket type or team, editable one2many tables, custom fields on the customer profile, custom fields in bulk actions.

## 15. Addendum v1.1: Odoo discovery and integration strategy

**Precedence:** this section overrides the recommendation in 5.1. The API contract in section 5 and the custom field contract in section 14 stay the same whichever path is chosen; only *where* the contract is implemented changes.

### 15.1 Rule of choice: path of least resistance

Pick the path with the fewest moving parts that still meets all four non-negotiables:

1. Per-user identity, with Odoo access rights and record rules enforced (customers see only their own tickets).
2. No admin or master credentials on any device.
3. Push notifications are possible.
4. Custom field schema (section 14) can be served and written safely.

### 15.2 Candidate paths

| Path | Description | Pick when | Trade-offs |
| --- | --- | --- | --- |
| A. Custom Odoo addon | Controllers under `/api/mobile/v1/`, config model, device tokens, push hooks | Addons can be deployed (Odoo.sh, on-premise, partner-managed hosting) | Best security and cleanest contract; needs deployment per Odoo upgrade |
| B. Odoo JSON-2 API directly | Bearer API key per user against `/json/2/<model>/<method>` (Odoo 19) | Version is 19 and addons cannot be deployed | App carries ORM-shaped logic; push needs a relay; verify portal users may use it |
| C. Odoo JSON-RPC directly | `/web/session/authenticate` and `call_kw` (Odoo 17 or 18) | Version below 19 and addons cannot be deployed | Same as B; session handling is heavier; XML-RPC and JSON-RPC are being phased out in newer versions |
| D. Thin middleware (BFF) | Small service (Python or Node) exposing the section 5 contract, calling Odoo with a service account | Addons impossible and per-user API access is blocked or impractical | One more service to host; the service must enforce ownership and roles itself |

In B and C the mapping from the section 5 contract onto ORM calls lives in the Flutter data layer behind the repository interfaces. Acceptable for an MVP, but push notifications still need a small relay, which is why D is usually the better fallback to A.

### 15.3 Discovery tasks for the implementing agent

Run these **read-only**, against a dev or staging database first, never production:

1. **Version and edition**: read `server_version` from `/web/webclient/version_info`; confirm Enterprise and that `helpdesk` is installed.
2. **Hosting**: identify Odoo.sh, on-premise, or Odoo Online (Online generally means no custom addons). Ask the user if it cannot be inferred.
3. **Installed modules**: list `ir.module.module` where state is installed; note `helpdesk` sub-modules, `web_studio`, `portal`, `rating`, `website_helpdesk`, any custom partner modules.
4. **Codebase access**: check whether an addons repository or path is available for adding `helpdesk_mobile_api`, and what the deployment process looks like.
5. **Helpdesk configuration**: teams, stages, ticket types, assignment method, existing custom fields (`ir.model.fields` for `helpdesk.ticket` where name starts with `x_`).
6. **Auth capability tests**: with a test portal user and a test admin user, verify login and a basic read through the candidate API. Specifically confirm whether **portal users** can authenticate and call the ORM through the candidate API (some installations restrict this). If not, Path A or D is required.
7. **API key availability**: whether API keys can be issued per user and whether the user has the rights to create them.
8. **Outbound mail and push**: outgoing mail server working (for password reset and registration); an FCM project available.
9. **Network**: HTTPS with a valid certificate, base URL, any reverse proxy or IP restrictions that could block mobile clients.

### 15.4 Decision output

Produce `docs/odoo-discovery.md` containing: the findings above, the chosen path with a short rationale, rejected paths with reasons, the exact Odoo-side changes required (addon, config rows, stages, parameters), risks and open questions, and an updated `openapi.yaml` if the contract changed.

**Default if findings are inconclusive:** Path A when an addons repository is reachable; otherwise Path D. Do not choose B or C unless the portal-user test in 15.3 step 6 passes.

### 15.5 Stop and ask conditions

The agent stops and asks the user when it needs: the Odoo URL and database name, a test admin account or API key, a test portal user, the addons repository path or deployment access, or an FCM project. It never guesses credentials, never stores them in the repository, and never writes to production.

### 15.6 Kickoff prompt for the agent

> Read this specification completely. Before writing any app code, execute section 15: inspect my Odoo installation (read-only, dev or staging), choose the path of least resistance using the rule in 15.1, and write `docs/odoo-discovery.md`. Ask me for any credentials or access you need. Then implement phases in order, building the section 14 custom field system as schema-driven from the start. Do not hard-code stage ids or custom fields anywhere.
