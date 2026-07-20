# ProtonSpace platform

ProtonSpace is an external social platform with an embedded CityOS surface. The web application and the F2 browser must use the same API and database. FiveM only provides short-lived identity tickets, character association, presence, notifications, and safe deep links.

Phase 1 deliberately excludes chat, livestreaming, crypto, creator payments, App Store distribution, and user-authored HTML/CSS. Those features require separate authority and moderation contracts.

## Phase 1 API contract

```text
POST /api/auth/ticket/exchange
GET  /api/me
GET  /api/feed
POST /api/posts
POST /api/posts/:id/comments
PUT  /api/posts/:id/reaction
GET  /api/profiles/:slug
PUT  /api/profile
POST /api/follows/:accountId
DELETE /api/follows/:accountId
GET  /api/notifications
```

The existing packaged F2 app remains a compatibility client while the external SvelteKit/API deployment is brought online. It must not replace NPWD or make the website dependent on FXServer uptime.

## Deployment

Apply `migrations/001_protonspace_phase1.sql` to the CityOS MariaDB database. Rollback is documented at the end of that migration. Do not commit Qbox, database, or CityOS signing secrets to this tree.
