# mawa_erp_admin

MAWA ERP Admin Console

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Google Secret Manager

Tenant detail now supports saving sensitive tenant properties to Google Secret Manager. Use **Add Secret** or enable **Store value in Google Secret Manager** when adding a property. The admin console sends the raw value to `mawa-admin-bes`; the backend creates or updates a GCP Secret Manager secret and stores only the generated `gcp-secret://...` reference against the tenant property.

Secret names are displayed read-only before saving and follow `mawa-{environment}-{tenant-host-normalised}-{property-normalised}`. Custom secret names are not accepted.
