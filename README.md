# PC Parts Store - Flutter E-Commerce App

Flutter e-commerce app for selling computer components with clean architecture.

## Setup

### 1. Firebase
```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### 2. Install & generate code
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 3. Run
```bash
flutter run
```

## Offline-First Architecture

```
UI → Repository → SQLite (local cache)
                ↕ sync when online
              Firestore (remote)
```

- Products: cached in SQLite after first fetch, served from cache when offline
- Cart: persisted in SQLite, survives app restarts
- Orders: placed directly if online; queued in `pending_sync` table if offline, auto-synced when reconnected
- Connectivity: `connectivity_plus` detects network changes, triggers sync flush automatically

## Architecture

```
lib/
├── core/
│   ├── constants/     # App constants, categories
│   ├── errors/        # Custom exceptions
│   ├── router/        # GoRouter config
│   ├── theme/         # Material theme
│   └── utils/         # Currency formatter
├── data/
│   ├── models/        # Firestore models (User, Product, Order, Review)
│   └── services/      # Firebase services (Auth, Product, Order, Review, Storage)
├── presentation/
│   ├── providers/     # Riverpod providers (Cart, Wishlist, Products)
│   ├── screens/       # All screens
│   │   ├── auth/      # Login, Register
│   │   ├── home/      # Home with banner + categories
│   │   ├── product/   # List + Detail
│   │   ├── cart/      # Cart
│   │   ├── checkout/  # Checkout (mock payment)
│   │   ├── order/     # Order history + detail
│   │   ├── profile/   # User profile
│   │   ├── wishlist/  # Wishlist
│   │   ├── admin/     # Admin dashboard, product form, orders
│   │   └── shell/     # Bottom nav shell
│   └── widgets/       # Reusable widgets (ProductCard, LoadingShimmer)
└── main.dart
```

## Firestore Structure

```
users/{uid}
  - email, name, role (user|admin), phone, address, wishlist[]

products/{id}
  - name, description, category, brand, price, salePrice
  - stock, images[], specs{}, rating, reviewCount, isFeatured

orders/{id}
  - userId, userName, items[], totalAmount, status, shippingAddress

reviews/{id}
  - productId, userId, userName, rating, comment
```

## Admin Access
Set `role: "admin"` in Firestore for a user document to enable admin features.
