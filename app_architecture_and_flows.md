# Tài liệu Kiến trúc & Luồng hoạt động - App Linh Kiện

Ứng dụng này được phát triển bằng **Flutter**, sử dụng kiến trúc phân lớp (Layered Architecture) tương tự Clean Architecture, kết hợp với các thư viện hiện đại:
- **State Management**: `flutter_riverpod`
- **Routing**: `go_router`
- **Local Storage**: `sqflite` và `shared_preferences`

Dưới đây là chi tiết chức năng của từng thư mục, file code và cách chúng tương tác với nhau.

---

## 1. Cấu trúc thư mục (`lib/`)

```
lib/
├── core/             # Cốt lõi của ứng dụng (Router, Theme, Constants, Utils)
├── data/             # Tầng Dữ liệu (Database, Models, Services)
├── presentation/     # Tầng Giao diện UI (Screens, Widgets, Providers)
└── main.dart         # Entry point của ứng dụng
```

---

## 2. Phân tích chi tiết chức năng từng File

### 🔴 `main.dart`
- **Chức năng**: Điểm bắt đầu (Entry point) của ứng dụng.
- **Hoạt động**: 
  1. Gọi `WidgetsFlutterBinding.ensureInitialized()` để khởi tạo Flutter.
  2. Chạy `_seedDemoUsers()`: Tạo tài khoản admin và user mẫu (nếu chưa có) vào SQLite.
  3. Bọc toàn bộ app bằng `ProviderScope` để khởi tạo Riverpod.
  4. Khởi chạy `MyApp` với cấu hình router từ `appRouterProvider`.

---

### 🟡 Tầng Core (`core/`)

- **`core/router/app_router.dart`**:
  - Quản lý toàn bộ điều hướng của app bằng `go_router`.
  - **Luồng hoạt động**: Sử dụng `_RouterNotifier` để lắng nghe sự thay đổi của `currentUserProvider`. Nếu trạng thái đăng nhập thay đổi, router sẽ tự động chuyển hướng (Redirect):
    - Chưa đăng nhập -> Đá về `/login`.
    - Đã đăng nhập (Role: Admin) -> Chuyển vào `/admin`.
    - Đã đăng nhập (Role: User) -> Chuyển vào `/home`.

- **`core/theme/app_theme.dart`**: Định nghĩa màu sắc chủ đạo, font chữ và kiểu dáng các UI component (Button, Input) cho toàn app.
- **`core/utils/currency_formatter.dart`**: Các hàm tiện ích để format số tiền (VD: `1000000` -> `1.000.000 ₫`).

---

### 🟢 Tầng Data (`data/`)

#### a. Thư mục `data/local/`
- **`database_helper.dart`**: File quan trọng nhất của tầng Data. 
  - **Chức năng**: Trực tiếp giao tiếp với SQLite để lưu trữ toàn bộ dữ liệu offline.
  - **Hoạt động**: Khi app chạy lần đầu, nó tạo các bảng (`users`, `products`, `cart`, `orders`, `reviews`, `categories`). Nó chứa sẵn code "Seed" để tự động thêm dữ liệu mẫu (các danh mục linh kiện, 10 sản phẩm mẫu, tài khoản mẫu). Chứa tất cả các hàm CRUD (Thêm, Sửa, Xóa) cho mọi bảng.

#### b. Thư mục `data/models/`
Chứa các class Data Model để parse dữ liệu từ SQLite (Map) thành các Object trong Dart và ngược lại.
- `user_model.dart`, `product_model.dart`, `order_model.dart`, `cart_item_model.dart`, v.v...

#### c. Thư mục `data/services/`
Tầng trung gian giữa UI và Database, chứa logic nghiệp vụ (Business Logic).
- **`auth_service.dart`**: 
  - Chứa `AuthService` để xử lý đăng nhập, đăng ký qua `DatabaseHelper`.
  - Chứa `currentUserProvider` (Riverpod StateNotifier) để lưu trạng thái user đang đăng nhập.
  - **Luồng hoạt động**: Lấy `uid` từ `SharedPreferences` để tự động đăng nhập khi mở app. Khi người dùng login, gọi xuống Database check pass -> Cập nhật Riverpod State -> Lưu `uid` vào thiết bị.
- **`product_service.dart`, `order_service.dart`**: Các service gọi xuống DatabaseHelper để lấy danh sách sản phẩm, tạo đơn hàng...

---

### 🔵 Tầng Presentation (`presentation/`)

#### a. Thư mục `presentation/providers/`
Chứa các Riverpod Provider để cung cấp dữ liệu cho UI.
- **`product_provider.dart`**: 
  - Chứa `productFilterProvider` (lưu trữ điều kiện lọc hiện tại).
  - Chứa `productsProvider` (FutureProvider): Tự động gọi `ProductService` để lấy danh sách sản phẩm bất cứ khi nào bộ lọc thay đổi.
- **`cart_provider.dart`**: Quản lý state của giỏ hàng. Thêm/sửa/xóa item trong giỏ và gọi xuống DatabaseHelper để lưu vào SQLite.

#### b. Thư mục `presentation/screens/`
Chứa các màn hình giao diện, phân chia theo từng chức năng.

- **`auth/` (Login & Register)**:
  - Cho phép người dùng nhập email/mật khẩu. Khi submit, gọi `ref.read(currentUserProvider.notifier).login()`.

- **`shell/main_shell.dart`**:
  - Giao diện khung chứa thanh `BottomNavigationBar`. Các tab Home, Products, Cart, Profile sẽ được nhúng vào màn hình này.

- **`home/home_screen.dart`**:
  - Hiển thị danh mục nổi bật, sản phẩm nổi bật (Featured).

- **`product/`**:
  - `product_list_screen.dart`: Màn hình danh sách. Lắng nghe `productsProvider` để hiển thị dạng lưới (Grid). 
  - `product_detail_screen.dart`: Lấy chi tiết sản phẩm và review. Cho phép bấm "Thêm vào giỏ".

- **`cart/` & `checkout/`**:
  - `cart_screen.dart`: Hiển thị các sản phẩm trong giỏ, cho phép tăng giảm số lượng.
  - `checkout_screen.dart`: 
    - **Luồng hoạt động**: Form điền địa chỉ -> Bấm Đặt Hàng -> Gọi `OrderService.createOrder()` -> Tạo đơn vào DB -> Trừ số lượng tồn kho (Stock) của sản phẩm -> Xóa giỏ hàng -> Điều hướng sang màn chi tiết đơn hàng.

- **`admin/`**:
  - Các màn hình chỉ dành cho Admin (Dashboard, Quản lý sản phẩm, đơn hàng, người dùng, doanh thu). Gọi trực tiếp các Service để thay đổi dữ liệu của toàn hệ thống.

---

## 3. Tổng kết luồng hoạt động chính của người dùng (User Flow)

1. **Khởi động**: `main.dart` -> App đọc `SharedPreferences` để xem đã đăng nhập chưa.
2. **Đăng nhập**: Vào `LoginScreen` -> Nhập Data -> `AuthService` kiểm tra SQLite -> Thành công -> Router chuyển sang `MainShell`.
3. **Mua hàng**: 
   - Vào `HomeScreen` -> Chọn sản phẩm -> Vào `ProductDetailScreen`.
   - Bấm thêm giỏ hàng -> `cart_provider` cập nhật state và lưu SQLite.
   - Qua tab Giỏ hàng -> Chọn Thanh toán -> Chuyển sang `CheckoutScreen`.
   - Điền thông tin -> Đặt hàng -> Database lưu Order mới -> Chuyển qua lịch sử đơn hàng.
4. **Đăng xuất**: Nút Đăng xuất ở Profile gọi `logout()` -> Xóa Token -> State thành Null -> Router đá văng về `LoginScreen`.
