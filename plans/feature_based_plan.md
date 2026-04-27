# Feature-based Project Structure Plan

The goal is to transition to a feature-based structure to enhance modularity.

## Proposed Structure

```
lib/
├── core/                # Shared services, utilities, models, networking
│   ├── api_client.dart
│   ├── local_db.dart
│   ├── network_service.dart
│   ├── base_repository.dart
│   └── theme/
├── features/
│   ├── sync/            # SyncManager, SyncNotifier
│   ├── auth/            # Auth logic
│   ├── camiler/
│   ├── dini_gunler/
│   ├── dualar/
│   ├── hutbe/
│   ├── imsakiye/
│   ├── kuran/           # KuranDownloadService, KuranPage
│   ├── kutuphane/       # KutuphaneRepository, KutuphanePage, model
│   ├── menu/
│   ├── pusula/
│   ├── settings/
│   ├── vakitler/
│   └── zikirmatik/
└── main.dart
```

## Steps

1. Create `lib/core` directory and move shared items.
2. Consolidate feature-related files (pages, repositories, services) into their respective `lib/features/<feature_name>` directories.
3. Update all imports in the project to reflect the new structure.
4. Update `main.dart` and `locator.dart` to reflect moved files.

Would you like me to start executing this plan, starting with the `sync` feature?
