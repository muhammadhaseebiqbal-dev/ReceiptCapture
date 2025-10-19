# Receipt Capture App

A comprehensive Flutter mobile application for capturing, managing, and organizing receipts with advanced features like OCR processing, data encryption, and cloud synchronization.

## 🚀 Features

### Core Functionality

#### 📱 Receipt Management
- **Receipt Capture**: Take photos of receipts using the device camera
- **Gallery Import**: Import receipt images from device gallery
- **Smart Cropping**: Advanced image cropping with manual adjustment capabilities
- **Receipt Storage**: Secure local storage with SQLite database
- **Receipt Listing**: View all captured receipts in an organized list
- **Search Functionality**: Search receipts by merchant name, category, or notes
- **Delete Receipts**: Remove receipts with soft-delete functionality for synced items

#### 🎨 User Interface
- **Modern Dark Theme**: Consistent dark theme throughout the app
- **Responsive Design**: Optimized for various screen sizes
- **Material Design 3**: Latest Material Design components and styling
- **Smooth Animations**: Fluid transitions and loading indicators
- **Bottom Navigation**: Easy navigation between main sections (Receipts, Camera, Settings)

#### 📸 Camera Features
- **Real-time Preview**: Live camera preview with receipt overlay guide
- **Flash Control**: Toggle flash on/off for better image quality
- **Auto-focus**: Automatic camera focusing for sharp images
- **Receipt Guidelines**: Visual guides to help align receipts properly
- **Multiple Sources**: Capture from camera or import from gallery

#### 🔒 Security & Privacy
- **Data Encryption**: Receipt data encryption using AES encryption
- **Secure Storage**: Encrypted local database storage
- **Privacy Controls**: No unauthorized data access

#### ☁️ Synchronization (Implemented Framework)
- **Sync Queue**: Background synchronization queue system
- **Offline Support**: Full functionality without internet connection
- **Sync Status**: Visual indicators for sync status (Local/Synced)
- **Conflict Resolution**: Framework for handling sync conflicts
- **Retry Logic**: Automatic retry for failed sync operations

### Technical Architecture

#### 🏗️ Architecture Pattern
- **BLoC Pattern**: State management using flutter_bloc
- **Repository Pattern**: Data layer abstraction
- **Clean Architecture**: Separation of concerns across layers
- **Dependency Injection**: Service locator pattern

#### 🗄️ Data Layer
- **SQLite Database**: Local data persistence
- **Repository Classes**: Data access abstraction
- **Model Classes**: Strongly typed data models
- **Database Migrations**: Version control for database schema

#### 🎯 State Management
- **BLoC/Cubit**: Reactive state management
- **Event-driven**: Action-based state updates
- **Immutable State**: Predictable state transitions
- **Error Handling**: Comprehensive error state management

## 📁 Project Structure

```
lib/
├── main.dart                     # App entry point
├── core/                         # Core functionality
│   ├── database/                 # Database layer
│   │   ├── database_helper.dart  # SQLite database setup
│   │   ├── models.dart           # Data models
│   │   └── receipt_repository.dart # Data access layer
│   └── services/                 # Core services
│       ├── camera_service.dart   # Camera functionality
│       └── encryption_service.dart # Data encryption
├── features/                     # Feature modules
│   └── receipt/                  # Receipt management
│       └── bloc/                 # State management
│           ├── receipt_bloc.dart # Main bloc logic
│           ├── receipt_event.dart # Events
│           └── receipt_state.dart # States
├── screens/                      # UI screens
│   ├── home_screen.dart          # Main navigation
│   ├── receipt_list_screen.dart  # Receipt listing
│   ├── camera_screen.dart        # Camera interface
│   ├── settings_screen.dart      # App settings
│   ├── advanced_crop_screen.dart # Image cropping
│   ├── receipt_form_screen.dart  # Receipt details form
│   └── receipt_details_screen.dart # Receipt viewer
└── shared/                       # Shared components
    ├── theme/                    # App theming
    │   └── app_theme.dart        # Theme configuration
    └── widgets/                  # Reusable widgets
        ├── receipt_card.dart     # Receipt list item
        ├── empty_state.dart      # Empty state widget
        ├── loading_indicator.dart # Loading animations
        └── floating_navigation.dart # Bottom navigation
```

## 🛠️ Technical Implementation

### Database Schema

```sql
-- Receipts table
CREATE TABLE receipts (
  id TEXT PRIMARY KEY,
  image_path TEXT NOT NULL,
  cropped_image_path TEXT,
  merchant_name TEXT,
  date TEXT,
  category TEXT,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  is_synced INTEGER NOT NULL DEFAULT 0,
  upload_status TEXT NOT NULL DEFAULT 'queued',
  encrypted_data TEXT,
  deleted_at TEXT
);

-- Sync queue table
CREATE TABLE sync_queue (
  queue_id TEXT PRIMARY KEY,
  receipt_id TEXT NOT NULL,
  operation TEXT NOT NULL,
  retry_count INTEGER NOT NULL DEFAULT 0,
  last_attempt TEXT,
  status TEXT NOT NULL DEFAULT 'PENDING'
);
```

### Key Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  flutter_bloc: ^8.1.3          # State management
  camera: ^0.10.5+5              # Camera functionality
  sqflite: ^2.3.0                # Local database
  image_picker: ^1.0.4           # Gallery access
  image_cropper: ^5.0.1          # Image cropping
  path_provider: ^2.1.1          # File system access
  uuid: ^4.1.0                   # Unique ID generation
  intl: ^0.18.1                  # Internationalization
  equatable: ^2.0.5              # Value equality
```

## 🎯 Current Features Status

### ✅ Completed Features
- [x] Receipt capture via camera
- [x] Gallery image import
- [x] Advanced image cropping
- [x] Receipt data storage
- [x] Receipt listing with search
- [x] Dark theme UI
- [x] Data encryption
- [x] Offline functionality
- [x] Delete receipts
- [x] Sync framework
- [x] Error handling
- [x] Loading states

### 🔄 Recently Updated
- [x] Amount system removed (as requested)
- [x] Edit functionality removed (as requested)
- [x] Consistent dark theme implementation
- [x] Fixed text visibility issues
- [x] Fixed camera capture functionality
- [x] Fixed delete functionality with soft-delete support

### 📋 Next Phase: Authentication & User Management
- [ ] User registration and login system
- [ ] Employee authentication
- [ ] Super user web portal integration
- [ ] Role-based access control
- [ ] Subscription management

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1+)
- Dart SDK
- Android Studio / VS Code
- Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/muhammadhaseebiqbal-dev/ReceiptCapture.git
   cd ReceiptCapture/receipt_capture
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Usage

### Capturing Receipts
1. Open the app and navigate to the Camera tab
2. Align the receipt within the camera viewfinder
3. Tap the capture button to take a photo
4. Crop the image using the advanced cropping tool
5. Add merchant details, category, and notes
6. Save the receipt

### Managing Receipts
1. View all receipts in the Receipts tab
2. Search receipts using the search bar
3. Tap on a receipt to view details
4. Use the menu to delete receipts

### Settings
- Configure sync settings
- Manage data encryption
- Set app preferences
- View app information

## 🔧 Configuration

### Camera Permissions
Add the following permissions to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS Permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to capture receipt images</string>
```

## 🏗️ Architecture Decisions

### State Management
- **BLoC Pattern**: Chosen for predictable state management and separation of business logic
- **Event-Driven**: Actions trigger events that modify state
- **Reactive UI**: UI rebuilds automatically based on state changes

### Data Storage
- **SQLite**: Local database for offline functionality
- **Encryption**: AES encryption for sensitive receipt data
- **Repository Pattern**: Abstraction layer for data access

### Image Handling
- **Camera Integration**: Native camera access with custom overlay
- **Image Cropping**: Advanced cropping with manual adjustments
- **File Management**: Secure local file storage

## 🔒 Security Considerations

- All receipt data is encrypted before storage
- Images are stored in app-specific directories
- No sensitive data is logged or transmitted without encryption
- Soft delete for synced items to maintain data integrity

## 📈 Performance Optimizations

- Lazy loading of receipt images
- Efficient database queries with proper indexing
- Image compression for storage optimization
- Background sync operations
- Memory-efficient image handling

## 🗺️ Roadmap

### Phase 2: Authentication & User Management (Next)
- User registration and login
- Employee authentication with role-based access
- Super user web portal integration
- Subscription management system
- Multi-tenant architecture

### Phase 3: Cloud Integration
- Cloud storage synchronization
- Multi-device support
- Backup and restore functionality
- Real-time collaboration

### Phase 4: Advanced Features
- OCR text extraction
- Automatic categorization
- Expense reporting
- Analytics and insights

### Phase 5: Enterprise Features
- Team management
- Approval workflows
- Integration with accounting systems
- Advanced reporting

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is proprietary software. All rights reserved.

## 📞 Support

For support and questions, please contact the development team.
