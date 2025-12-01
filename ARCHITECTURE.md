# ARFace Encrypter - Architecture Documentation

## 📁 Project Structure

```
arface-encrypter/
├── arface_encrypterApp.swift           # App entry point
├── ContentView.swift                    # Root tab view
│
├── Models/                              # Data models & enums
│   ├── AvatarType.swift                # Avatar enumeration (Bear, Fox)
│   ├── FaceExpression.swift            # Facial expression enumeration
│   ├── Message.swift                   # Database message model
│   └── UserSettings.swift              # User preferences (Observable)
│
├── ViewModels/                          # MVVM ViewModels
│   ├── EncodeViewModel.swift           # Encode flow state & logic
│   └── DecodeViewModel.swift           # Decode flow state & logic
│
├── Views/                               # SwiftUI Views
│   ├── EncodeView.swift                # Message encoding UI
│   ├── DecodeView.swift                # Message decoding UI
│   ├── ProfileView.swift               # User profile & settings
│   ├── FaceDetectionTestView.swift    # Development test view
│   ├── GIFTestView.swift               # Development test view
│   └── Components/                      # Reusable UI components
│       ├── ARFaceTrackingView.swift    # ARKit camera wrapper
│       ├── AnimatedGIFView.swift       # GIF display component
│       └── ExpressionEmojiView.swift   # Expression emoji display
│
├── Managers/                            # Business logic managers
│   ├── AuthManager.swift               # Supabase authentication
│   └── ExpressionRecorder.swift        # Expression sequence recording
│
├── Services/                            # Network & data services
│   └── MessageService.swift            # Supabase message operations
│
├── ARKit/                               # ARKit face tracking
│   └── ARFaceDetector.swift            # Face expression detection
│
├── Utilities/                           # Helper utilities
│   ├── GIFGenerator.swift              # Animated GIF creation
│   ├── HapticManager.swift             # Haptic feedback
│   ├── MessageIDExtractor.swift        # OCR from GIF
│   └── SpriteSheetExtractor.swift      # Sprite extraction
│
├── Config/                              # Configuration & constants
│   ├── FaceDetectionThresholds.swift  # ARKit detection thresholds
│   └── SupabaseConfig.swift            # Database configuration
│
└── Assets.xcassets/                     # Images, colors, etc.
    ├── bear-sprite.imageset/           # Bear avatar sprite sheet
    └── fox-sprite.imageset/            # Fox avatar sprite sheet
```

## 🏗️ Architecture Pattern: MVVM

### Models
- **Purpose**: Data structures and business entities
- **Examples**: `Message`, `FaceExpression`, `AvatarType`
- **Rules**:
  - Codable for JSON serialization
  - No UI logic
  - Immutable when possible
  - Use enums for fixed sets

### ViewModels
- **Purpose**: Presentation logic and state management
- **Pattern**: `@Observable` macro (Swift 5.9+)
- **Examples**: `EncodeViewModel`, `DecodeViewModel`
- **Rules**:
  - Marked with `@MainActor` when updating UI
  - Handle async operations
  - Coordinate between services and views
  - Contain no UIKit/SwiftUI types

### Views
- **Purpose**: UI presentation only
- **Pattern**: SwiftUI declarative views
- **Rules**:
  - Minimal logic (presentation only)
  - Use `@State` for local state
  - Reference ViewModels for shared state
  - Decompose into small, reusable components

## 🔄 Data Flow

### Encode Flow
```
User Input → EncodeViewModel → ExpressionRecorder → ARFaceDetector
                ↓
            GIFGenerator → MessageService → Supabase
                ↓
            Generated GIF + Message ID
```

### Decode Flow
```
GIF Import → MessageIDExtractor (OCR) → DecodeViewModel
                ↓
        ExpressionRecorder → ARFaceDetector
                ↓
        Expression Hash → MessageService → Supabase
                ↓
        Decrypted Message
```

## 🎯 Layer Responsibilities

### Presentation Layer (Views + ViewModels)
- User interaction
- Display state
- Navigation
- Form validation
- Error presentation

### Business Logic Layer (Managers + Utilities)
- Expression recording logic
- Authentication flow
- GIF generation
- Image processing
- Haptic feedback

### Data Layer (Services + Models)
- API communication
- Database operations
- Data transformation
- Caching (if needed)

### Platform Layer (ARKit)
- Face tracking
- Expression detection
- Camera access
- Hardware interaction

## 🔐 State Management

### Using @Observable (Swift 5.9+)
```swift
@Observable
class EncodeViewModel {
    var messageText: String = ""
    var currentStep: EncodingStep = .enterMessage
    // Properties automatically trigger UI updates
}
```

### Using @MainActor
```swift
@MainActor
class DecodeViewModel {
    // All methods run on main thread by default
    // Safe for UI updates
}
```

### State Ownership
- **@State**: View-local state (counters, toggles, etc.)
- **@Observable**: Shared state across views
- **@Environment**: Dependency injection

## 🌊 Async/Await Pattern

All async operations use Swift concurrency:

```swift
func generateAndUploadMessage() async {
    do {
        let message = try await MessageService.shared.createMessage(...)
        let gifURL = try await GIFGenerator.generateGIF(...)
        // Handle success
    } catch {
        // Handle error
    }
}
```

## 🔌 Dependency Injection

### Singleton Pattern (Services)
```swift
class MessageService {
    static let shared = MessageService()
    private init() {}
}
```

### Configuration Pattern (Constants)
```swift
struct FaceDetectionThresholds {
    static let winkEyeClosed: Float = 0.8
    static let tongueOut: Float = 0.3
}
```

## 🧪 Testing Strategy

### Unit Tests
- Models: Codable conformance, computed properties
- Utilities: GIF generation, sprite extraction
- Services: API request formation (mock responses)

### Integration Tests
- ViewModels: State transitions, error handling
- Managers: Expression recording logic

### UI Tests
- Full encode/decode flows
- Navigation
- Error states

## 📱 Platform Considerations

### ARKit Requirements
- iOS 14.0+
- Face ID capable device
- Camera permission
- Handle session interruptions

### Supabase Integration
- Network error handling
- Retry logic
- Offline mode (where applicable)
- Secure credential storage

## 🎨 Best Practices Applied

### Swift Conventions
✅ PascalCase for types, camelCase for properties  
✅ Explicit access control (private, fileprivate, public)  
✅ Extensions for protocol conformance  
✅ Guard statements for early returns  
✅ Optional chaining and nil coalescing  

### SwiftUI Conventions
✅ Extract subviews with computed properties  
✅ Use ViewBuilder for conditional views  
✅ Prefer composition over inheritance  
✅ Keep views under 300 lines  

### iOS Conventions
✅ Handle app lifecycle (appear/disappear)  
✅ Request permissions before use  
✅ Provide user feedback (haptics, animations)  
✅ Support Dark Mode  
✅ Respect safe areas  

## 🔮 Future Improvements

### Architecture Enhancements
- [ ] Add proper navigation coordinator
- [ ] Implement repository pattern for data layer
- [ ] Add dependency injection container
- [ ] Create protocol-based service abstractions
- [ ] Add analytics/logging layer

### Performance Optimizations
- [ ] Implement image caching
- [ ] Lazy load sprite sheets
- [ ] Reduce GIF file size
- [ ] Optimize ARKit tracking

### Testing
- [ ] Add unit test coverage
- [ ] Add snapshot tests for views
- [ ] Add integration tests for flows
- [ ] Add performance tests

## 📚 Key Design Decisions

### Why @Observable over @StateObject?
- Cleaner syntax
- Better performance
- Swift-native (not SwiftUI-specific)
- Forward-compatible

### Why Singleton Services?
- Simple dependency management
- Single source of truth
- Easy testing with protocols later
- Common iOS pattern

### Why Separate ViewModels?
- Clear separation of concerns
- Easier testing
- Reusable logic
- Better maintainability

### Why Utilities vs Managers?
- **Utilities**: Stateless, pure functions
- **Managers**: Stateful, coordinate multiple operations

## 🔗 Related Documentation
- [DEVELOPMENT_PLAN_PHASED.md](./DEVELOPMENT_PLAN_PHASED.md) - Implementation phases
- [Models/README.md](./arface-encrypter/Models/README.md) - Data model details
- [ARKit/README.md](./arface-encrypter/ARKit/README.md) - Face detection guide

---

*Last Updated: December 2025*

