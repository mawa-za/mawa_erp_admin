# Admin Console Platform Management UI

This admin console update adds platform-management screens and tenant detail actions.

## Screens and actions

- Home dashboard now shows tenant and subscription summary counts.
- Tenants screen still lists all tenants and now shows subscription plan where available.
- Tenant detail now includes:
  - Tenant Profile card
  - Subscription card
  - Module management card
  - ERP integration card
  - Google Secret Manager card
  - System properties
  - Activity log
- Subscription Plans screen is available from the home dashboard.

## Tenant-specific ERP URL

Each tenant should have its own ERP App URL on the tenant record. The Open ERP button uses that tenant URL when generating the admin handoff URL.

Examples:

```text
https://client-a.beta.app.mawa.co.za
https://client-b.beta.app.mawa.co.za
```

The backend environment variable `MAWA_ERP_APP_URL` is only a fallback.
