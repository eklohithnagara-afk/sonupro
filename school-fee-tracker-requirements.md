# School Fee Tracker — Requirements Document

> Source of truth for what we're building and why.
> Version: 0.1.1 (prototype phase)

---

## 1. Project Overview

A **web-based (PWA) fee management system** for a single school (~64 students) to track:
- Academic fees
- Transport (van) fees
- Day care fees (with hourly check-in/check-out tracking)
- Extracurricular activity (ECA) fees

**Two user roles** with identical access in v1 (RBAC-ready for future restriction):
- **Admin** — full access
- **Manager** — same access (intended for audit/oversight; differentiation deferred)

**No parent portal** in v1. Parents do not log in.

---

## 2. School & Student Setup

| Item | Decision |
|---|---|
| School count | Single school |
| Student count | ~64 |
| Classes | Play Group, Nursery-A, Nursery-B, Euro Junior, Euro Senior |
| Class structure | Fixed (not user-defined in v1) |
| Academic year | June to March (e.g., `2025-2026`) |
| Student info stored | Name, Class, Parent name, Parent phone (with country code) |
| Siblings | Allowed; one parent can have multiple children (family-linked) |
| Soft delete | Yes — archive, never hard-delete (financial records retained) |

---

## 3. Fee Structure

| Aspect | Decision |
|---|---|
| Academic fee | **Per class** (default), with **per-student override** capability |
| Van fee | **Per route**, set in settings; per-student override possible |
| Day care fee | **Student-specific** (event-based log) |
| ECA fee | **Student-specific** (linked via many-to-many) |
| Multi-head | Yes — each head is a separate `FeeHead` record |
| Sibling discount | **Admin-configurable** in settings: type (flat % or fixed ₹), value, scope (all heads or academic only). Calculated at invoice time, not stored on student. |
| Late fee / penalty | **No** |
| Discounts beyond sibling | No (in v1) |
| Collection frequency | Academic = monthly, Van = per-route (monthly OR 2-term/half-yearly), Day care = monthly (billed after month end), ECA = per activity (default monthly) |
| Pro-rating | Not in v1 |

**Schema principle:** `FeeSchedule` supports different frequencies per head so we're not locked in.

---

## 4. Transport (Van)

| Aspect | Decision |
|---|---|
| Route model | Route = name + fee amount (no stops in v1) |
| Fee frequency | **Admin picks per route**: monthly OR 2-term (half-yearly) — stored as `billing_frequency` on route |
| Fee assignment | Per route by default; per-student override available |
| Mid-year route change | Admin creates new route or uses override |
| Sibling van sharing | Per student (not per family) in v1 |

---

## 5. Day Care (Complex — Handled Carefully)

| Aspect | Decision |
|---|---|
| Who logs check-in/out | Admin/Manager manually |
| Time format | Exact HH:MM, no rounding (round up to nearest hour at billing) |
| Rate | Flat single rate per hour (slab-based deferred to v2) |
| Daily minimum | 1 hour minimum (any stay = 1 hr billed) |
| Non-school students | Not supported (day care is only for enrolled school students) |
| Carry-over of unpaid hours | No (billed monthly with regular fee cycle) |
| Schema | Separate `day_care_logs` table — event-based, not schedule-based |

---

## 6. Extracurricular Activities (ECA)

| Aspect | Decision |
|---|---|
| User-defined | Yes — Admin creates activity name, fee, frequency from UI |
| Attendance tracking | Not in v1 (flat fee only) |
| Multiple per student | Yes (many-to-many relationship) |

---

## 7. Payments

| Aspect | Decision |
|---|---|
| Payment modes | Cash, UPI, Bank Transfer, Cheque, Card |
| Who records | Admin or Manager |
| Partial payments | **Supported** — manual allocation by user to fee heads |
| Auto-suggest allocation | No (v2 nice-to-have) |
| Receipt numbering | Auto-generated, per-year reset, format `RCP-2025-0001` |
| Receipt content | School header, logo, parent name, student name, class, fee head breakdown, amount paid, mode, date, balance remaining, signature line |
| Receipt generation | One-tap PDF with timestamp in filename and footer |
| Payment reminders | Manual "Send via WhatsApp" button — opens `wa.me/` link with pre-filled message. No API integration in v1. |
| Online gateway | Not in v1 |
| Cheque clearing | Deferred to v2 (cheque number, date, bank, status: pending/cleared/bounced) |
| Payment history | Append-only; void + re-issue pattern (no edits/deletes) |

---

## 8. Billing & Outstanding

| Aspect | Decision |
|---|---|
| Bill generation | **Manual trigger** — Admin clicks "Generate Bills for [Month]". No auto-cron. |
| Bill structure | **One consolidated invoice per student** (all heads: academic + van + ECA + day care) |
| Outstanding carry-forward | **No** — June unpaid stays as June dues. July bill = July only. Outstanding report shows each unpaid month as separate line. |
| Defaulter list | Yes — students with unpaid fees past due date |

**Schema principle:** No running balance column needed. Each `fee_invoice` row has its own `paid_amount` and `status` (unpaid / partial / paid).

---

## 9. Reports

All reports exportable to **PDF with timestamp** in filename and footer (`DD/MM/YYYY HH:MM`).

1. Fee collection (daily / monthly / date range)
2. Outstanding dues (per student / per class / overall)
3. Van route-wise collection
4. Day care attendance vs billing summary
5. Defaulter list
6. Receipt register
7. Audit log
8. Sibling discount report
9. ECA enrollment + collection
10. **Monthly consolidated summary** (all heads combined)

---

## 10. Roles & Access

| Aspect | Decision |
|---|---|
| Current roles | Admin, Manager (same access) |
| Future restriction | **RBAC schema from day 1** with `can_edit`, `can_delete`, `can_manage_users` flags — just both `true` for now |
| Audit log | **Mandatory** — every create/update/delete logs `user_id`, `action`, `table/area`, `record_id`, `details`, `timestamp` |
| Concurrent editing | Last-write-wins (no optimistic locking in v1) |
| Edit indicator | Show "last updated by X at Y" on records |

---

## 11. Technical

| Aspect | Decision |
|---|---|
| Platform | **PWA** (web app, installable on mobile home screen) |
| Mobile support | Android + iOS, both browsers |
| Offline support | Cache app shell only; data entry requires connectivity |
| Backend (future) | **Firebase or Supabase** suggested (auth + DB + file storage) |
| Current prototype | Single `index.html` file, vanilla JS + Tailwind via CDN, localStorage |
| Data persistence | Browser `localStorage` + Export/Import JSON buttons |
| Multi-user | 2-3 concurrent users expected |
| Cloud backup | Required (when moving to real backend) |
| Multi-language | Not in v1 (English only), but `i18n`-ready |
| Bulk import | **No** — dropped. Only ~64 students; manual entry via UI is sufficient. |
| Currency | INR (₹) |
| Date format | DD/MM/YYYY |
| School branding | Configurable (name, address, phone, logo text) on receipts and reports |
| Database migration | None in prototype; schema designed for clean migration to real DB |

---

## 12. Multi-Year Support

| Aspect | Decision |
|---|---|
| Multiple academic years | Yes — full support from day 1 |
| Year status | `active` (editable) or `archived` (read-only) |
| Switching | UI badge in top bar + Settings → Year Management |
| Year-end process | Archive previous year, create new one, start fresh fee records |
| Archive view | Old data always viewable, just read-only |

**Schema principle:** `academic_year_id` is the top-level partition. Every fee, payment, and report is scoped to an academic year.

---

## 13. Engineering Flags (Critical for Schema Design)

These are **non-negotiable** for a financial system and are reflected in the data model:

1. **Academic Year is the top-level partition** — every fee/payment/report scoped to `academic_year_id`.
2. **Day care needs a separate `day_care_logs` table** — event-based, not schedule-based.
3. **Payment allocation table** — `payment_allocations` join table handles partial payments and one-payment-covers-multiple-heads.
4. **Sibling discount calculated at invoice time** — store `family_id` on students, query at bill generation, never store computed discount on student row.
5. **Receipts are append-only** — never edit/delete; void with reason and re-issue.
6. **Cheque clearing workflow** — required for v2 (status tracking, bounce reversal).
7. **Soft delete only** — archive flag, never hard delete.
8. **Audit log on every mutation** — non-negotiable for fee system trust.

---

## 14. Out of Scope for v1 (Deferred to v2+)

- Slab-based day care rates
- ECA attendance tracking
- Auto-suggest payment allocation
- Cheque clearing/bounce workflow
- SMS/Email notifications
- Online payment gateway integration
- Real authentication & RBAC enforcement (schema-ready, not enforced)
- Thermal printer support
- Multi-language
- Parent portal/login
- Optimistic locking for concurrent edits
- Pro-rating of fees for mid-month joins

---

## 15. Build Approach

**Prototype first, real backend later.**

1. **v0.1** — Login, Dashboard, Students CRUD, Classes, Settings, Audit Log ✅
2. **v0.1.1** — Archived students + restore, family-based sibling UI, multi-year switcher ✅
3. **v0.2** — Transport (routes + per-route fee + frequency), ECA, Day Care logs, Manual bill generation
4. **v0.3** — Payments, Receipts (PDF), WhatsApp share, Outstanding reports
5. **v0.4** — All remaining reports
6. **v0.5** — Polish, edge cases, real backend migration (Firebase/Supabase)

---

## 16. Decisions Log (for traceability)

| Question | Decision | Rationale |
|---|---|---|
| Auto bill generation? | No, manual trigger | Simpler, predictable, no missed jobs to debug |
| Carry-forward unpaid months? | No | Cleaner accounting, each month independent |
| WhatsApp integration? | Manual via wa.me link | No API cost, no approval needed, works everywhere |
| Discount stored on student? | No, calculated at invoice | Avoids stale data, single source of truth |
| Receipt editing? | No, void + re-issue | Audit trail integrity, financial trust |
| Concurrent editing strategy? | Last-write-wins + "last updated" banner | Simple, sufficient for 2-3 users |
| Multi-year support? | Built in from day 1 | Schools always need historical data |
| Single HTML prototype? | Yes | Validate UX before committing to backend |
| Mock data? | 10 students, includes 1 sibling pair | Test all critical flows end-to-end |

---

*Last updated: end of v0.1.1 build*
