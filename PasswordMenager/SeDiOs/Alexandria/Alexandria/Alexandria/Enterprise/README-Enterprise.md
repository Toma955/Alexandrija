# Enterprise – priprema prije implementacije

Svi fajlovi u ovom folderu su **samo priprema**. Ništa se ne poziva iz glavne aplikacije.

## Mapiranje na enterprise checklist

| # | Stavka | Datoteka | Što je pripremljeno |
|---|--------|----------|----------------------|
| 1 | Network lock-down | `NetworkLockdownConfig.swift` | Allowlist/blocklist pravila, ProxyConfig, CustomDNSConfig, NetworkLockdownPolicy stub |
| 2 | mTLS + cert pinning | `MTLSCertPinningConfig.swift` | CertPinningRule, ClientCertConfig, MTLSCertPinningPolicy stub |
| 3 | SSO/IdP | `SSOIdPConfig.swift` | IdPConfig (Entra/Okta/Keycloak), SSOSession, SSOIdPService stub |
| 4 | RBAC/ABAC | `RBACConfig.swift` | Tenant, Role, Capability, UserRoleAssignment, RBACPolicy stub |
| 5 | Offline-first sync | `OfflineSyncConfig.swift` | SyncQueueItem, SyncRetryConfig, ConflictResolution, OfflineSyncService stub |
| 6 | Enkripcija at rest | (Vault u `Security/`) | Već pripremljeno u Security/Vault* |
| 7 | DLP kontrole | `DLPConfig.swift` | DLPConfig (copy/paste, print, screenshot, export, clipboard timeout), DLPPolicy stub |
| 8 | Document access | `DocumentAccessConfig.swift` | ManagedFolder, DocumentAccessAuditEntry, DocumentAccessPolicy stub |
| 9 | App/Plugin izolacija | `AppPluginIsolationConfig.swift` | PluginCapability, PluginIsolationConfig (XPC, timeout, rate-limit), stub |
| 10 | Resource manager | `ResourceBudgetConfig.swift` | ResourceBudget (RAM/CPU/GPU/ML), ResourceContextId, ResourceBudgetPolicy stub |
| 11 | Audit & logging | `AuditLogConfig.swift` | AuditEvent, AuditEventCategory, correlationId, AuditLogService stub, export za SIEM |
| 12 | Update sustav | `UpdateSystemConfig.swift` | UpdateSourceConfig, UpdateManifestEntry, UpdateSystemService stub (delta, rollback) |
| 13 | MDM | `MDMConfig.swift` | MDMPolicyPayload (managed config), MDMConfigService stub |
| 14 | Zero-trust | `ZeroTrustConfig.swift` | ZeroTrustContext, ZeroTrustAction, ZeroTrustPolicy stub |
| 15 | Compliance | `ComplianceConfig.swift` | ComplianceChecks stub (code signature, tamper) |

## Sljedeći koraci

1. Uključiti provjere u stvarni tok (npr. `BrowserNetworkingService` → NetworkLockdownPolicy, MTLSPolicy).
2. Spremati konfiguraciju u UserDefaults ili čitati iz MDM (managed app config).
3. Implementirati SSO flow, RBAC provjere, DLP hooke u UI, audit log zapis, itd.
4. Povezati s postojećim Security/Vault i AppLimitsSettings gdje ima smisla.
