# Plan: Offline Mode & Caching for Prayer Times

This document outlines the plan to implement offline mode and caching for prayer times using `shared_preferences`.

## 1. Objectives
- Enable the application to display prayer times even when the device is offline.
- Cache the latest successfully fetched prayer times data.
- Provide a clear UI indicator when the displayed data is cached (i.e., when offline).

## 2. Implementation Steps

### 2.1 AuthService Updates
- Add `Future<void> cachePrayerTimes(String city, Map<String, dynamic> data)` method.
- Add `Future<Map<String, dynamic>?> getCachedPrayerTimes(String city)` method.

### 2.2 VakitlerPage Updates
- Modify `_fetchData` to:
    - Attempt to fetch data from API.
    - If successful, cache the data.
    - If failed (network error), attempt to load data from `AuthService`'s cache.
    - If cached data is available, display it and show a visual cue (e.g., a "Offline/Cached" badge or status indicator).
    - If neither API nor cache is available, show a prominent error message.

## 3. UI/UX Considerations
- Add a small, non-intrusive "Offline" or "Cached" indicator on the UI when offline data is being displayed.
- Ensure the user is still able to attempt a retry when offline.

## 4. Dependencies
- `shared_preferences` (already in `pubspec.yaml`).
