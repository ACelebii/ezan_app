# Plan: Automatic Location Update

This document outlines the plan to implement automatic prayer time updates based on the device's real-time location.

## 1. Objectives
- Automatically update prayer times when the user's location changes significantly (e.g., city change).
- Improve the accuracy of prayer times for traveling users.

## 2. Implementation Steps

### 2.1 Geolocator Setup
- Use `Geolocator` to watch the device's current location (`Geolocator.getPositionStream`).
- Set a threshold distance (e.g., 10km or 20km) to trigger location updates to avoid excessive API calls.

### 2.2 City Detection (Reverse Geocoding)
- When location updates, perform reverse geocoding to detect the new city/district if possible. 
- *Note: Simple approach might just update based on coordinates if the API supports it.*

### 2.3 Integration in VakitlerPage
- Implement a `StreamSubscription<Position>` to listen to location updates.
- In `initState`, start watching for location updates.
- In `dispose`, cancel the stream subscription.
- On location update:
    - Compare with the last known position.
    - If distance > threshold, trigger `_fetchData` with new city/location.
    - Save new location as the "active" location.

## 3. UI/UX Considerations
- Show a loading indicator when location is being updated or fetching new prayer times.
- Potentially add a settings option to toggle "Automatic Location Update".
