# RentEasy (Flutter Offline Portfolio Project)

RentEasy is a role-based rental app built in Flutter only.

## Version 1 Scope
- Offline-first app (no backend, no real API)
- Role flow: Renter and Property Owner
- Local persistence:
  - `SharedPreferences`: login state, role, onboarding
  - `Hive`: properties, favorites, bookings, payments
- Fake payment simulation:
  - ABA Pay (Mock)
  - Wing (Mock)
  - Credit Card (Mock)

## Main Flow
- Splash
- Onboarding
- Login / Register
- Role selection (register only, one-time)
- Role-based app shell (Renter or Owner)

## Renter Features
- Browse property list
- Search and price filter
- Property detail view
- Add/remove favorites
- Rent/Book request + fake payment
- Payment history

## Owner Features
- Owner dashboard
- Add/Edit/Delete properties
- View own properties
- View booking requests

## Run
```bash
flutter pub get
flutter run
```
