# UI Redesign: Premium Modern PC Parts Store

Redesign the application into a premium, modern, SaaS-quality interface inspired by Apple, Linear, and Stripe.

## Proposed Changes

### [Design System & Theme]

Establish a robust design system and update the application theme to reflect the new aesthetic.

#### [NEW] [design_tokens.dart](file:///E:/CN8/pc-parts-store/lib/core/theme/design_tokens.dart)
- Define colors: Indigo, Cyan, Emerald, Amber, Rose, Background, Surface.
- Define typography: Inter, Plus Jakarta Sans.
- Define spacing (8pt grid), border radius (18-28px), and shadows.

#### [app_theme.dart](file:///E:/CN8/pc-parts-store/lib/core/theme/app_theme.dart)
- Update `ThemeData` to use `design_tokens.dart`.
- Configure `ColorScheme`, `TextTheme`, and component themes (Button, Card, Input).

---

### [Core Premium Widgets]

Create a set of reusable, high-quality components to ensure consistency across the app.

#### [NEW] [premium_button.dart](file:///E:/CN8/pc-parts-store/lib/presentation/widgets/common/premium_button.dart)
- Custom button with support for gradients, shadows, and loading states.

#### [NEW] [premium_card.dart](file:///E:/CN8/pc-parts-store/lib/presentation/widgets/common/premium_card.dart)
- Card with soft shadows, large rounded corners, and subtle glassmorphism options.

#### [NEW] [premium_text_field.dart](file:///E:/CN8/pc-parts-store/lib/presentation/widgets/common/premium_text_field.dart)
- Modern text field with clean borders and focused states.

#### [product_card.dart](file:///E:/CN8/pc-parts-store/lib/presentation/widgets/product_card.dart)
- Redesign with larger images, premium typography, and subtle shadows.

---

### [Screen Redesign]

Redesign major screens to follow the new design language.

#### [home_screen.dart](file:///E:/CN8/pc-parts-store/lib/presentation/screens/home/home_screen.dart)
- Modernized banner carousel, premium category chips, and clean product grid.

#### [login_screen.dart](file:///E:/CN8/pc-parts-store/lib/presentation/screens/auth/login_screen.dart) & [register_screen.dart](file:///E:/CN8/pc-parts-store/lib/presentation/screens/auth/register_screen.dart)
- Clean, focused layout with premium input fields and buttons.

#### [product_list_screen.dart](file:///E:/CN8/pc-parts-store/lib/presentation/screens/product/product_list_screen.dart) & [product_detail_screen.dart](file:///E:/CN8/pc-parts-store/lib/presentation/screens/product/product_detail_screen.dart)
- Improved information hierarchy, larger images, and smooth interactions.

#### [admin_dashboard_screen.dart](file:///E:/CN8/pc-parts-store/lib/presentation/screens/admin/admin_dashboard_screen.dart)
- Premium KPI cards, interactive charts (mocked if needed), and clean sidebar/navigation.

---

### [Animations]

#### [main.dart](file:///E:/CN8/pc-parts-store/lib/main.dart)
- Add page transition animations to `GoRouter`.

## Verification Plan

### Manual Verification
- **Visual Audit**: Compare each screen against the design requirements (colors, spacing, typography).
- **Responsive Test**: Test on different screen sizes (Portrait, Landscape).
- **Interaction Test**: Verify all buttons, inputs, and navigations work correctly with new styles.
- **Dark Mode**: (Optional if time allows) Check if colors adapt well to dark mode.
