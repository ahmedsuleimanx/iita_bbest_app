# IITA BBEST - Agricultural Products E-commerce App

![IITA BBEST Logo](assets/images/iita-logo.jpeg)

A comprehensive cross-platform mobile application built with Flutter for IITA BBEST, featuring a complete agricultural products marketplace with modern UI/UX, Firebase integration, and robust e-commerce functionality.

## 🌟 Features

### Core Functionality
- **Complete Authentication System**
  - Email/Password signup and login
  - Password reset functionality
  - User profile management
  - Firebase Authentication integration

- **Product Management**
  - Browse products by categories (Animal Feed, Organic Fertilizer, Seeds, Tools, etc.)
  - Product search and filtering
  - Detailed product views with ratings and reviews
  - Real-time product availability

- **Shopping Cart & Checkout**
  - Add/remove items from cart
  - Quantity management
  - Order placement and tracking
  - Multiple payment methods support

- **User Experience**
  - Beautiful splash screen with animations
  - Intuitive navigation with bottom tab bar
  - Search functionality
  - Responsive design for all screen sizes

- **Admin Panel**
  - Product management (CRUD operations)
  - Order management and tracking
  - Analytics and reporting
  - User management

### Technical Features
- **State Management**: Riverpod for robust state management
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **Navigation**: GoRouter for type-safe routing
- **UI/UX**: Custom Material 3 design system with agricultural theme
- **Animations**: Beautiful transitions and loading states
- **Architecture**: Clean architecture with separation of concerns

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── app.dart                    # Main app widget
│   ├── firebase_options.dart       # Firebase configuration
│   └── theme/
│       └── app_theme.dart         # App theme and colors
├── models/
│   ├── user_model.dart            # User data model
│   ├── product_model.dart         # Product data model
│   ├── cart_model.dart            # Shopping cart models
│   └── order_model.dart           # Order management models
├── services/
│   ├── auth_service.dart          # Authentication services
│   ├── product_service.dart       # Product data services
│   └── cart_service.dart          # Cart management services
├── providers/
│   ├── auth_provider.dart         # Authentication state
│   ├── product_provider.dart      # Product state management
│   └── cart_provider.dart         # Cart state management
├── presentation/
│   ├── routes/
│   │   └── app_router.dart        # App routing configuration
│   ├── screens/
│   │   ├── auth/                  # Authentication screens
│   │   ├── home/                  # Home and main screens
│   │   ├── products/              # Product listing and details
│   │   ├── cart/                  # Shopping cart
│   │   ├── checkout/              # Checkout process
│   │   ├── orders/                # Order history
│   │   ├── profile/               # User profile
│   │   ├── search/                # Product search
│   │   └── admin/                 # Admin panel
│   └── widgets/
│       └── common/                # Reusable UI components
└── main.dart                      # App entry point
```

## 🎨 Design System

### Color Palette
- **Primary Green**: `#4CAF50` - Represents agriculture and growth
- **Secondary Orange**: `#FF6B35` - IITA BBEST brand accent color
- **Background**: `#F8F9FA` - Clean, modern background
- **Text Colors**: Hierarchy-based grays for optimal readability

### Typography
- **Font Family**: Inter - Modern, readable sans-serif
- **Heading Styles**: Bold weights for emphasis
- **Body Text**: Regular weight for readability
- **Responsive sizing**: Adapts to different screen sizes

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.5.0 or higher)
- Dart SDK
- Firebase project setup
- IDE (VS Code, Android Studio, or IntelliJ)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd iita_bbest_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Login to Firebase
   firebase login
   
   # Configure Firebase for Flutter
   flutterfire configure --project=iita-bbest-app
   ```

4. **Run the app**
   ```bash
   # Debug mode
   flutter run
   
   # Web
   flutter run -d web-server --web-port=8080
   
   # Release build
   flutter run --release
   ```

## 📱 Screenshots & Demo

### Authentication Flow
- Beautiful login/signup screens with form validation
- Password reset functionality
- Smooth transitions between auth states

### Main Application
- Home screen with featured products and categories
- Product browsing with search and filters
- Shopping cart with quantity management
- User profile and order history

### Admin Panel
- Product management interface
- Order tracking and management
- Analytics dashboard

## 🔧 Configuration

### Firebase Configuration
Update `lib/core/firebase_options.dart` with your Firebase project credentials:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'your-web-api-key',
  appId: 'your-app-id',
  messagingSenderId: 'your-sender-id',
  projectId: 'iita-bbest-app',
  authDomain: 'iita-bbest-app.firebaseapp.com',
  storageBucket: 'iita-bbest-app.appspot.com',
);
```

### Environment Setup
1. Enable Authentication in Firebase Console
2. Set up Firestore Database with appropriate rules
3. Configure Firebase Storage for product images
4. Set up Firebase Hosting (optional)

## 🏪 E-commerce Features

### Product Categories
- **Animal Feed**: High-quality feed for livestock
- **Organic Fertilizer**: Natural fertilizers for sustainable farming
- **Seeds**: Various crop seeds for different climates
- **Tools**: Agricultural tools and equipment
- **Fertilizer**: Chemical fertilizers for crop enhancement
- **Pesticides**: Crop protection products
- **Equipment**: Heavy-duty farming equipment

### Payment Methods
- Mobile Money
- Bank Transfer
- Cash on Delivery
- Card Payments

### Order Management
- Order placement and confirmation
- Order tracking with status updates
- Order history and receipts
- Cancellation and refund system

## 🔐 Security Features

- Firebase Authentication for secure user management
- Data validation and sanitization
- Secure API calls with proper error handling
- User role-based access control (Admin/Customer)

## 📊 State Management

The app uses Riverpod for state management with the following providers:

- **AuthProvider**: Manages user authentication state
- **ProductProvider**: Handles product data and operations
- **CartProvider**: Manages shopping cart state
- **Various family providers**: For specific data queries

## 🎯 Target Audience

- **Primary**: Smallholder farmers in DRC, Ghana, Mali, and Niger
- **Secondary**: Agricultural businesses and cooperatives
- **Tertiary**: Agricultural input suppliers and distributors

## 🌍 Localization Support

Ready for internationalization with:
- Multi-language support structure
- Cultural adaptations for different regions
- Currency and number formatting
- Date and time localization

## 📈 Performance Optimizations

- Lazy loading of product images
- Efficient state management with Riverpod
- Optimized build configurations
- Caching strategies for improved performance
- Responsive design for various screen sizes

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

## 🚀 Deployment

### Web Deployment
```bash
flutter build web
firebase deploy --only hosting
```

### Mobile Deployment
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

