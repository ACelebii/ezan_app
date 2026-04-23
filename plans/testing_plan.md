# Plan: Unit & Widget Testing

This document outlines the testing plan to ensure the reliability of core application features (prayer times and Qibla calculation).

## 1. Objectives
- Improve application stability by verifying critical calculations.
- Facilitate future refactoring without breaking existing functionality.

## 2. Testing Strategy

### 2.1 Unit Tests
- **Qibla Direction:** Test the `_calculateTrueBearing` method in `PusulaPage` (which should be extracted to a utility class) with known coordinates (e.g., Istanbul, London, New York) and verify the results against trusted calculations.
- **Prayer Time Logic:** If possible, extract the logic for prayer time display/calculation from `VakitlerPage` into a separate service and write unit tests for it.

### 2.2 Widget Tests
- **VakitlerPage UI:** Test that `VakitlerPage` correctly renders different themes and handles API data loading states.
- **PusulaPage UI:** Test that `PusulaPage` renders the compass correctly with given heading and Qibla angle inputs.

## 3. Implementation Steps

### 3.1 Refactoring
- Move `_calculateTrueBearing` from `PusulaPage` to a `GeoUtils` class.
- Move prayer time formatting/logic from `VakitlerPage` to a `PrayerTimeService` or similar.

### 3.2 Test Implementation
- Add `flutter_test` dependency (already present).
- Create `test/geo_utils_test.dart` and `test/prayer_time_service_test.dart`.
- Run tests using `flutter test`.
