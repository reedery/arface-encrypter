# 🔐 ARFace Encrypter

> Secure your messages with facial expressions. No keys, no passwords—just your face.

An innovative iOS app that encrypts messages using a sequence of 5 facial expressions, generating an animated GIF that can only be decoded by performing the exact same sequence.

## ✨ Features

- 🎭 **Expression-Based Encryption**: Lock messages with 6 unique facial expressions
- 🎨 **Animated GIF Generation**: Share beautiful animated avatars (Bear & Fox)
- 🤖 **AI-Enhanced Images**: Use Apple Image Playground to generate artistic GIF frames (iOS 18.2+)
- 🔒 **Secure & Fun**: No traditional passwords needed
- 📱 **Native iOS**: Built with SwiftUI + ARKit
- ☁️ **Cloud-Backed**: Powered by Supabase

## 🎯 How It Works

### Encoding
1. Type your secret message
2. Perform 5 facial expressions in sequence
3. App generates an animated GIF with embedded message ID
4. Share the GIF with your recipient

### Decoding
1. Import the received GIF
2. Perform the same 5 expressions from the GIF
3. Message unlocks if sequence matches!

## 🎭 Expressions

The app detects 6 facial expressions:

| Expression | Emoji | Detection |
|------------|-------|-----------|
| Left Wink | 😉 | Left eye closed, right open |
| Right Wink | 😉 (flipped) | Right eye closed, left open |
| Tongue Out | 😛 | Tongue visible |
| Surprise | 😮 | Eyebrows raised + jaw open |
| Smile | 😁 | Big grin |
| Smooch | 😘 | Pucker lips |

## 🏗️ Architecture

```
MVVM + Clean Architecture
├── Models          (Data structures)
├── ViewModels      (Business logic)
├── Views           (UI)
├── Services        (API layer)
├── Managers        (State management)
├── Utilities       (Helpers)
└── ARKit          (Face detection)
```

See [ARCHITECTURE.md](./ARCHITECTURE.md) for detailed documentation.

## 🚀 Tech Stack

- **Language**: Swift 5.9+
- **UI**: SwiftUI
- **Face Tracking**: ARKit (ARFaceTrackingConfiguration)
- **AI Image Generation**: Image Playground (iOS 18.2+)
- **Backend**: Supabase (PostgreSQL)
- **GIF Generation**: ImageIO (native)
- **State Management**: @Observable (Swift Observation)

## 📋 Requirements

### Base Requirements
- iOS 14.0+
- Xcode 15.0+
- Face ID capable device (iPhone X or later)
- Camera permission
- Network connection (for message sync)

### AI-Enhanced Images (Optional)
- iOS 18.2+ for Image Playground support
- Apple Silicon device (A17 Pro / M-series recommended)
- Falls back to original sprites if unavailable

See [IMAGE_PLAYGROUND_INTEGRATION.md](./IMAGE_PLAYGROUND_INTEGRATION.md) for details.

## 🛠️ Setup

### 1. Clone the repository
```bash
git clone https://github.com/yourusername/arface-encrypter.git
cd arface-encrypter
```

### 2. Configure Supabase
Add these keys to `Info.plist`:
```xml
<key>SUPABASE_URL</key>
<string>your-project-url.supabase.co</string>
<key>SUPABASE_ANON_KEY</key>
<string>your-anon-key</string>
```

### 3. Database Setup
Run this SQL in your Supabase dashboard:
```sql
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT NOW(),
    expression_hash TEXT UNIQUE,
    message TEXT,
    expression_list TEXT
);
```

### 4. Open in Xcode
```bash
open arface-encrypter.xcodeproj
```

### 5. Run
Select a Face ID capable device or simulator and run (⌘R)

## 📱 Usage

### First Time Setup
1. Open app → Navigate to Profile tab
2. Select your avatar (Bear or Fox)
3. Toggle AI-Enhanced Images (requires iOS 18.2+)
4. Grant camera permissions when prompted

### Creating an Encrypted Message
1. **Encode Tab** → Type your secret message (max 100 chars)
2. Tap **"Lock Message with Facial Expressions"**
3. Perform 5 unique expressions when prompted
4. Wait for GIF generation (~2-3 seconds)
5. Share the GIF via Messages, AirDrop, etc.

### Decoding a Message
1. **Decode Tab** → Tap **"Decode a New GIF"**
2. Select the GIF from your Photos
3. Watch the GIF to learn the sequence
4. Perform the same 5 expressions
5. Message reveals if sequence is correct!

## 🎨 Avatars

### Bear 🐻
Friendly and classic bear character with 6 expressions.

### Fox 🦊
Clever fox character with matching expressions.

Both use 768×512px sprite sheets (3×2 grid, 256×256px per sprite).

## 📁 Project Structure

```
arface-encrypter/
├── arface_encrypterApp.swift
├── ContentView.swift
├── Models/
│   ├── AvatarType.swift
│   ├── FaceExpression.swift
│   ├── Message.swift
│   └── UserSettings.swift
├── ViewModels/
│   ├── EncodeViewModel.swift
│   └── DecodeViewModel.swift
├── Views/
│   ├── EncodeView.swift
│   ├── DecodeView.swift
│   ├── ProfileView.swift
│   └── Components/
│       ├── ARFaceTrackingView.swift
│       ├── AnimatedGIFView.swift
│       └── ExpressionEmojiView.swift
├── Managers/
│   ├── AuthManager.swift
│   └── ExpressionRecorder.swift
├── Services/
│   ├── MessageService.swift
│   └── ImagePlaygroundService.swift
├── ARKit/
│   └── ARFaceDetector.swift
├── Utilities/
│   ├── GIFGenerator.swift
│   ├── HapticManager.swift
│   ├── MessageIDExtractor.swift
│   └── SpriteSheetExtractor.swift
├── Config/
│   ├── FaceDetectionThresholds.swift
│   └── SupabaseConfig.swift
└── Assets.xcassets/
```

## 🧪 Testing

### Manual Testing Checklist
- [ ] All 6 expressions detected correctly
- [ ] GIF generates with message ID
- [ ] Message saves to database
- [ ] Correct sequence unlocks message
- [ ] Wrong sequence shows error
- [ ] Avatar switching works
- [ ] Share sheet functions properly

### Known Limitations
- Requires good lighting for face detection
- Expression hold time: 0.4 seconds
- Max message length: 100 characters
- GIF file size: ~500KB-2MB

## 🔒 Security Notes

**This is a proof-of-concept app for educational purposes.**

Security considerations:
- Expression sequences have ~720 possible combinations (6^5 = 7776 with repeats)
- Message IDs are sequential integers (easily guessable)
- GIFs include visible expression hints
- No rate limiting on decode attempts

**For production use**, consider:
- Hashing expression sequences
- Random message IDs (UUIDs)
- Rate limiting
- Biometric validation
- End-to-end encryption

## 📈 Future Enhancements

- [ ] Custom avatars from photos
- [ ] Video recording instead of GIF
- [ ] Multi-user authentication
- [ ] Message expiration
- [ ] Private/public message modes
- [ ] Expression difficulty levels
- [ ] Social features (friends, groups)
- [ ] Analytics dashboard

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Follow Swift style guide
4. Add tests if applicable
5. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 👏 Acknowledgments

- ARKit for face tracking
- Supabase for backend
- Bear & Fox sprites by [Artist Name]
- Inspired by expression-based authentication research

## 📞 Contact

- **Author**: Ryan Reede
- **GitHub**: [@yourusername](https://github.com/yourusername)
- **Project**: [ARFace Encrypter](https://github.com/yourusername/arface-encrypter)

---

**Built with ❤️ using Swift & SwiftUI**

*This app was created as part of a learning project to explore ARKit face tracking and creative authentication methods.*

