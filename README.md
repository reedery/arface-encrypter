# Face Encrypter AR

Share hidden messages with friends in AI generated animations!
Unlock with a secret combination of facial expressions.

## Quick Start (Demo this project on your iPhone or iPad)

### Requirements

- Mac with Xcode 16+
- iPhone or iPad (with Face ID depth camera)
- iOS 14.0+
- For AI Generated GIFs: Apple Intelligence capable device with Image Playground App installed. App will still work with "AI Enhanced Images" disabled.

### Steps

1. **Clone and open**

   ```bash
   git clone https://github.com/yourusername/arface-encrypter.git
   cd arface-encrypter
   open arface-encrypter.xcodeproj
   ```

2. **Install dependencies**

   - Xcode will automatically fetch the Supabase Swift package with dependencies
   - If not, go to File → Packages → Resolve Package Versions

3. **Configure Backend (optional)**

   The app works in **Offline Mode** by default with no backend setup needed.

   To enable cloud sync, add your Supabase credentials to `Info.plist`:

   ```xml
   <key>SUPABASE_URL</key>
   <string>https://your-project.supabase.co</string>
   <key>SUPABASE_ANON_KEY</key>
   <string>your-anon-key</string>
   ```

   And run this SQL in your Supabase dashboard:

   ```sql
   CREATE TABLE messages (
      id SERIAL PRIMARY KEY,
      created_at TIMESTAMP DEFAULT NOW(),
      expression_hash TEXT UNIQUE,
      message TEXT,
      expression_list TEXT
   );
   ```

> **Note:** Without Supabase configured, the app runs in offline-only mode. Messages are stored locally on your device. This is perfect for demos and testing. Local Messages can be cleared with "Clear Offline Messages" button in Profile view.

## How It Works

**Encode:** Type message → Perform 5 expressions → Share generated GIF

**Decode:** Import GIF → Perform same expressions → Message unlocked

## Expressions

| Expression    | Detection                   |
| ------------- | --------------------------- |
| Left Wink 😉  | Left eye closed, right open |
| Right Wink    | Right eye closed, left open |
| Tongue Out 😛 | Tongue visible              |
| Surprise 😮   | Eyebrows raised + jaw open  |
| Smile 😁      | Big grin                    |
| Smooch 😘     | Pucker lips                 |

## Settings (in Profile View)

- **Avatar:** Choose Bear 🐻 or Fox 🦊
- **AI Images:** Use Apple Image Playground for artistic frames (iOS 18.2+ with Apple Intelligence and Image Playground App installed)
- **Offline Mode:** Store messages locally (default ON)

## Architecture

```
Models/          Data structures
ViewModels/      Business logic
Views/           SwiftUI UI
Services/        Supabase + offline storage
ARKit/           Face detection
```

## License

MIT
