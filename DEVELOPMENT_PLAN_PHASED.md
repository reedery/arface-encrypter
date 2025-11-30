# ARFace Encrypter - Phased Development Plan

## Project Overview
Build a face-expression based message encryption iOS app where users encode messages by performing 5 facial expressions, which generates an animated GIF. Recipients decode by performing the same sequence.

## Tech Stack
- **iOS:** Swift + SwiftUI
- **Backend:** Supabase (PostgreSQL)
- **Face Tracking:** ARKit with ARFaceTrackingConfiguration
- **GIF Generation:** ImageIO (native, no external dependencies)
- **Avatar Sprites:** Bear & Fox sprite sheets (768×512px, 6 expressions each)

## Current State
✅ Basic app structure with 3 tabs (Encode, Decode, Profile)  
✅ Supabase integration configured  
✅ Messages table schema defined  
✅ DecodeView fetching messages from DB  
✅ Avatar sprite sheets (Bear & Fox)  

## Expression Set (6 Total)
From sprite sheets (L→R, top to bottom):
1. **wink_l** - Left wink
2. **tongue_out** - Tongue sticking out  
3. **surprise** - Eyebrows up, mouth open
4. **wink_r** - Right wink
5. **smile** - Big smile/grin
6. **smooch** - Pucker/kiss face

---

# Development Phases

## 🔵 PHASE 1: Foundation & Models
**Branch:** `feature/foundation-models`  
**Time Estimate:** 1-2 hours  
**Dependencies:** None  
**Test Before Merge:** Unit tests + Profile view preview  

### Objectives
- Create all core data models and enums
- Set up sprite sheet extraction system
- Add avatar selection to Profile view
- NO ARKit or database work yet - just models and utilities

### File Checklist

#### ✅ Create `Models/FaceExpression.swift`
```swift
enum FaceExpression: String, CaseIterable, Codable {
    case winkLeft = "wink_l"
    case winkRight = "wink_r"
    case tongueOut = "tongue_out"
    case surprise = "surprise"
    case smile = "smile"
    case smooch = "smooch"
    
    var displayName: String { /* ... */ }
    var emoji: String { /* ... */ }
}
```

#### ✅ Create `Models/AvatarType.swift`
```swift
enum AvatarType: String, CaseIterable, Codable {
    case bear = "bear"
    case fox = "fox"
    
    var displayName: String { rawValue.capitalized }
    var spriteSheetName: String { "\(rawValue)-sprite" }
}
```

#### ✅ Create `Models/UserSettings.swift`
```swift
@Observable
class UserSettings {
    var selectedAvatar: AvatarType // Persisted to UserDefaults
}
```

#### ✅ Create `Config/FaceDetectionThresholds.swift`
```swift
struct FaceDetectionThresholds {
    static let winkLeftEyeClosed: Float = 0.8
    static let winkLeftEyeOpen: Float = 0.3
    // ... all other thresholds
    static let expressionHoldDuration: TimeInterval = 0.4
}
```

#### ✅ Create `Utilities/SpriteSheetExtractor.swift`
```swift
class SpriteSheetExtractor {
    // Sprite sheet: 768×512px, grid 3×2, each sprite 256×256
    static func extractSprite(from spriteSheet: UIImage, expression: FaceExpression) -> UIImage?
    static func extractAllSprites(from avatar: AvatarType) -> [FaceExpression: UIImage]
}
```

#### ✅ Update `Models/Message.swift`
Add computed property:
```swift
var expressions: [FaceExpression]? {
    guard let expressionList = expressionList else { return nil }
    return expressionList.split(separator: ",")
        .compactMap { FaceExpression(rawValue: String($0)) }
}
```

#### ✅ Update `Views/ProfileView.swift`
Add:
- Avatar picker (Bear vs Fox)
- Preview grid showing all 6 extracted sprites
- User stats section (placeholder for now)

### Testing Checklist
- [ ] All models compile without errors
- [ ] `SpriteSheetExtractor` successfully extracts all 6 sprites from both bear and fox sheets
- [ ] Profile view displays avatar picker
- [ ] Switching avatar updates preview grid
- [ ] UserSettings persists avatar selection across app restarts

### Success Criteria
✅ Can switch between Bear and Fox in Profile  
✅ Preview grid shows 6 correct extracted expressions  
✅ No crashes, all types well-defined  

### Demo for This Phase
**Video (~30sec):**
1. Open Profile tab
2. Switch from Bear to Fox
3. Show preview grid updates with Fox sprites
4. Close app, reopen → Fox still selected

---

## 🟢 PHASE 2: ARKit Face Detection
**Branch:** `feature/arkit-detection`  
**Time Estimate:** 2-3 hours  
**Dependencies:** Phase 1 merged  
**Test Before Merge:** Face detection in isolation (test view)

### Objectives
- Implement ARKit face tracking
- Detect all 6 expressions reliably
- Create standalone test view to verify detection
- NO encoding/decoding flow yet - just detection

### File Checklist

#### ✅ Create `ARKit/ARFaceDetector.swift`
```swift
class ARFaceDetector: NSObject, ObservableObject, ARSessionDelegate {
    @Published var currentExpression: FaceExpression?
    @Published var isNeutral: Bool = true
    @Published var detectionActive: Bool = false
    @Published var debugBlendshapes: [String: Float] = [:]
    
    private let session = ARSession()
    private var expressionStartTime: Date?
    private var lastDetectedExpression: FaceExpression?
    
    func startTracking()
    func stopTracking()
    func detectExpression(from blendshapes: [...]) -> FaceExpression?
    func isNeutralFace(blendshapes: [...]) -> Bool
}
```

**Detection Logic:**
```swift
// Priority order (check most specific first):
1. tongueOut > 0.3 → .tongueOut
2. eyeBlinkLeft > 0.8 && eyeBlinkRight < 0.3 → .winkLeft
3. eyeBlinkRight > 0.8 && eyeBlinkLeft < 0.3 → .winkRight
4. cheekPuff or mouthPucker > 0.5 → .smooch
5. jawOpen > 0.5 && browUp > 0.5 → .surprise
6. mouthSmileLeft > 0.6 && mouthSmileRight > 0.6 → .smile
```

**Debouncing:**
- Must hold expression for 0.4s before triggering
- Must return to neutral (all values < 0.3) between expressions

#### ✅ Create `Views/Components/ARFaceTrackingView.swift`
```swift
struct ARFaceTrackingView: UIViewRepresentable {
    @Binding var detectedExpression: FaceExpression?
    let showDebugOverlay: Bool
    
    // Wraps ARSCNView
    // Shows live camera feed
    // Optional: face mesh overlay
    // Optional: debug blendshape values
}
```

#### ✅ Create `Views/FaceDetectionTestView.swift` (Temporary)
```swift
struct FaceDetectionTestView: View {
    @StateObject var detector = ARFaceDetector()
    
    var body: some View {
        VStack {
            ARFaceTrackingView(
                detectedExpression: $detector.currentExpression,
                showDebugOverlay: true
            )
            
            // Show detected expression
            if let expr = detector.currentExpression {
                Text("Detected: \(expr.displayName) \(expr.emoji)")
                    .font(.largeTitle)
            }
            
            // Show raw blendshape values for tuning
            List {
                ForEach(detector.debugBlendshapes.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text(key)
                        Spacer()
                        Text(String(format: "%.2f", value))
                            .foregroundColor(value > 0.5 ? .green : .gray)
                    }
                }
            }
        }
        .onAppear { detector.startTracking() }
        .onDisappear { detector.stopTracking() }
    }
}
```

#### ✅ Add Test Tab to ContentView (Temporarily)
```swift
TabView {
    // ... existing tabs
    FaceDetectionTestView()
        .tabItem { Label("Test", systemImage: "face.smiling") }
}
```

### Testing Checklist
- [ ] Camera permission requested correctly
- [ ] ARKit session starts without errors
- [ ] Can detect all 6 expressions:
  - [ ] wink_l (left eye closed, right open)
  - [ ] wink_r (right eye closed, left open)
  - [ ] tongue_out (tongue visible)
  - [ ] surprise (eyebrows + mouth)
  - [ ] smile (big grin)
  - [ ] smooch (pucker lips)
- [ ] Expressions require 0.4s hold time
- [ ] Must return to neutral between expressions
- [ ] Debug overlay shows blendshape values updating in real-time
- [ ] No false positives during normal talking/movement

### Threshold Tuning
Use `FaceDetectionTestView` to:
1. Perform each expression
2. Check debug blendshape values
3. Adjust thresholds in `FaceDetectionThresholds.swift`
4. Test again until reliable

### Success Criteria
✅ Can reliably detect all 6 expressions  
✅ Minimal false positives  
✅ Smooth tracking at 30+ fps  

### Demo for This Phase
**Video (~1min):**
1. Open Test tab
2. Perform each of 6 expressions slowly
3. Show detection triggering (with haptic feedback)
4. Show debug overlay with live blendshape values
5. Demonstrate debouncing (quick expression doesn't trigger)

---

## 🟡 PHASE 3: Expression Recording & GIF Generation
**Branch:** `feature/gif-generation`  
**Time Estimate:** 2-3 hours  
**Dependencies:** Phase 1 & 2 merged  
**Test Before Merge:** Can record 5 expressions and generate GIF

### Objectives
- Build expression sequence recorder
- Generate animated GIF from sequence
- Test in isolation (no database yet)
- Verify GIF plays correctly and has message ID

### File Checklist

#### ✅ Create `Managers/ExpressionRecorder.swift`
```swift
@Observable
class ExpressionRecorder {
    var recordedExpressions: [FaceExpression] = []
    var isRecording: Bool = false
    
    var currentStep: Int { recordedExpressions.count }
    var isComplete: Bool { recordedExpressions.count >= 5 }
    
    func startRecording()
    func recordExpression(_ expression: FaceExpression) -> Bool // Returns true if recorded
    func reset()
    
    func getExpressionHash() -> String {
        // Returns: "wink_l,tongue_out,surprise,smile,smooch"
        recordedExpressions.map(\.rawValue).joined(separator: ",")
    }
}
```

#### ✅ Create `Utilities/GIFGenerator.swift`
```swift
class GIFGenerator {
    static func generateGIF(
        expressions: [FaceExpression],
        avatar: AvatarType,
        messageID: String
    ) async throws -> URL {
        // 1. Extract sprites from sprite sheet
        let sprites = SpriteSheetExtractor.extractAllSprites(from: avatar)
        
        // 2. Build frame sequence
        var frames: [UIImage] = []
        
        // Use wink_l as "neutral" between expressions
        let neutralSprite = sprites[.winkLeft]!
        
        frames.append(neutralSprite) // Start neutral (0.5s)
        
        for expression in expressions {
            frames.append(sprites[expression]!) // Expression (0.5s)
            frames.append(neutralSprite)         // Back to neutral (0.3s)
        }
        
        // 3. Add message ID overlay to last frame
        let lastFrameWithID = addTextOverlay(to: frames.last!, text: "ID:\(messageID)")
        frames[frames.count - 1] = lastFrameWithID
        
        // 4. Generate GIF using ImageIO
        return try await createGIF(from: frames, frameDurations: [...])
    }
    
    private static func createGIF(from images: [UIImage], frameDurations: [TimeInterval]) async throws -> URL {
        // Use CGImageDestination to create GIF
        // Save to temp directory
        // Return file URL
    }
    
    private static func addTextOverlay(to image: UIImage, text: String) -> UIImage {
        // Draw text in top-left corner (small, white with black stroke)
    }
}
```

**Frame timing:**
```swift
let frameDurations: [TimeInterval] = [
    0.5,  // neutral start
    0.5, 0.3,  // expr1 + neutral
    0.5, 0.3,  // expr2 + neutral
    0.5, 0.3,  // expr3 + neutral
    0.5, 0.3,  // expr4 + neutral
    0.5, 0.5   // expr5 + neutral with ID
]
```

#### ✅ Create `Utilities/MessageIDExtractor.swift`
```swift
class MessageIDExtractor {
    static func extractMessageID(from gifURL: URL) async -> String? {
        // Option 1: Load last frame → use Vision OCR to read "ID:12345"
        // Option 2: Check GIF metadata comments
        // Return extracted ID or nil
    }
    
    private static func extractTextFromImage(_ image: UIImage) async -> String? {
        // Use VNRecognizeTextRequest from Vision framework
    }
}
```

#### ✅ Create `Views/GIFTestView.swift` (Temporary)
```swift
struct GIFTestView: View {
    @StateObject var detector = ARFaceDetector()
    @State var recorder = ExpressionRecorder()
    @State var generatedGIFURL: URL?
    @State var isGenerating = false
    @State var userSettings = UserSettings()
    
    var body: some View {
        VStack {
            if recorder.isComplete {
                // Show recorded expressions
                Text("Recorded: \(recorder.getExpressionHash())")
                
                if let gifURL = generatedGIFURL {
                    // Show generated GIF
                    AnimatedGIFView(url: gifURL)
                        .frame(height: 300)
                    
                    ShareLink(item: gifURL) {
                        Label("Share GIF", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Button("Generate GIF") {
                        Task {
                            isGenerating = true
                            do {
                                generatedGIFURL = try await GIFGenerator.generateGIF(
                                    expressions: recorder.recordedExpressions,
                                    avatar: userSettings.selectedAvatar,
                                    messageID: "TEST123"
                                )
                            } catch {
                                print("Error: \(error)")
                            }
                            isGenerating = false
                        }
                    }
                    .disabled(isGenerating)
                }
                
                Button("Reset") {
                    recorder.reset()
                    generatedGIFURL = nil
                }
            } else {
                ARFaceTrackingView(
                    detectedExpression: $detector.currentExpression,
                    showDebugOverlay: false
                )
                
                Text("Record expression \(recorder.currentStep + 1) of 5")
                    .font(.headline)
                
                // Show recorded so far
                HStack {
                    ForEach(recorder.recordedExpressions, id: \.self) { expr in
                        Text(expr.emoji).font(.largeTitle)
                    }
                }
            }
        }
        .onChange(of: detector.currentExpression) { old, new in
            if let expr = new, recorder.isRecording {
                if recorder.recordExpression(expr) {
                    // Haptic feedback
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        }
        .onAppear {
            detector.startTracking()
            recorder.startRecording()
        }
    }
}
```

#### ✅ Create `Views/Components/AnimatedGIFView.swift`
```swift
struct AnimatedGIFView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        
        if let data = try? Data(contentsOf: url),
           let source = CGImageSourceCreateWithData(data as CFData, nil) {
            // Animate GIF frames
        }
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIImageView, context: Context) {}
}
```

### Testing Checklist
- [ ] Can record 5 expressions in sequence
- [ ] Expression recorder prevents duplicates in a row
- [ ] Expression hash format correct: "expr1,expr2,expr3,expr4,expr5"
- [ ] GIF generates successfully
- [ ] GIF file size reasonable (<2MB)
- [ ] GIF has 11 frames with correct timing
- [ ] Message ID visible in last frame (small text overlay)
- [ ] Can extract message ID back from GIF using OCR
- [ ] GIF loops smoothly
- [ ] Can share GIF via share sheet

### Success Criteria
✅ Record 5 expressions → Generate GIF → Share  
✅ GIF plays correctly in Photos app  
✅ Message ID readable in last frame  

### Demo for This Phase
**Video (~1min):**
1. Open GIF Test view
2. Perform 5 expressions (smile, wink_l, tongue_out, surprise, smooch)
3. Show checkmarks as each recorded
4. Tap "Generate GIF"
5. Show generated GIF playing (looping animation)
6. Point out message ID in corner of last frame
7. Share via Messages/iCloud to verify it works outside app

---

## 🟠 PHASE 4: Encode Flow
**Branch:** `feature/encode-flow`  
**Time Estimate:** 2-3 hours  
**Dependencies:** Phases 1-3 merged  
**Test Before Merge:** Full encode flow with database

### Objectives
- Build complete encoding UI flow
- Integrate with Supabase database
- Generate and save messages
- Share GIF with message ID

### File Checklist

#### ✅ Create `Services/MessageService.swift`
```swift
class MessageService {
    static let shared = MessageService()
    private let client = SupabaseConfig.shared.client
    
    func createMessage(
        expressionHash: String,
        message: String,
        expressionList: String
    ) async throws -> Message {
        let newMessage: Message = try await client
            .from("messages")
            .insert([
                "expression_hash": expressionHash,
                "message": message,
                "expression_list": expressionList
            ])
            .select()
            .single()
            .execute()
            .value
        
        return newMessage
    }
    
    func fetchMessage(byHash hash: String) async throws -> Message? {
        try await client
            .from("messages")
            .select()
            .eq("expression_hash", value: hash)
            .maybeSingle()
            .execute()
            .value
    }
    
    func fetchAllMessages() async throws -> [Message] {
        try await client
            .from("messages")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }
}
```

#### ✅ Create `ViewModels/EncodeViewModel.swift`
```swift
@Observable
class EncodeViewModel {
    var messageText: String = ""
    var expressionRecorder = ExpressionRecorder()
    var faceDetector = ARFaceDetector()
    var generatedGIFURL: URL?
    var isGenerating = false
    var errorMessage: String?
    var createdMessage: Message?
    
    enum EncodingStep {
        case enterMessage
        case recordExpressions
        case generatingGIF
        case shareGIF
    }
    var currentStep: EncodingStep = .enterMessage
    
    func startExpressionRecording() {
        currentStep = .recordExpressions
        faceDetector.startTracking()
        expressionRecorder.startRecording()
    }
    
    func handleDetectedExpression(_ expression: FaceExpression) {
        guard currentStep == .recordExpressions else { return }
        
        if expressionRecorder.recordExpression(expression) {
            HapticManager.expressionDetected()
            
            if expressionRecorder.isComplete {
                Task {
                    await generateAndUploadMessage()
                }
            }
        }
    }
    
    func generateAndUploadMessage() async {
        currentStep = .generatingGIF
        isGenerating = true
        faceDetector.stopTracking()
        
        do {
            // 1. Create message in database
            let hash = expressionRecorder.getExpressionHash()
            createdMessage = try await MessageService.shared.createMessage(
                expressionHash: hash,
                message: messageText,
                expressionList: hash
            )
            
            // 2. Generate GIF with message ID
            let gifURL = try await GIFGenerator.generateGIF(
                expressions: expressionRecorder.recordedExpressions,
                avatar: UserSettings().selectedAvatar,
                messageID: "\(createdMessage!.id)"
            )
            
            generatedGIFURL = gifURL
            currentStep = .shareGIF
            HapticManager.sequenceComplete()
            
        } catch {
            errorMessage = error.localizedDescription
            currentStep = .enterMessage
        }
        
        isGenerating = false
    }
    
    func reset() {
        messageText = ""
        expressionRecorder.reset()
        generatedGIFURL = nil
        errorMessage = nil
        createdMessage = nil
        currentStep = .enterMessage
        faceDetector.stopTracking()
    }
}
```

#### ✅ Create `Utilities/HapticManager.swift`
```swift
class HapticManager {
    static func expressionDetected() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    static func sequenceComplete() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
```

#### ✅ Update `Views/EncodeView.swift`
```swift
struct EncodeView: View {
    @State private var viewModel = EncodeViewModel()
    @State private var userSettings = UserSettings()
    
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.currentStep {
                case .enterMessage:
                    messageInputView
                case .recordExpressions:
                    expressionRecordingView
                case .generatingGIF:
                    generatingView
                case .shareGIF:
                    shareGIFView
                }
            }
            .navigationTitle("Encode Message")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private var messageInputView: some View {
        VStack(spacing: 20) {
            Text("Write a Secret Message ✏️")
                .font(.title2)
                .fontWeight(.semibold)
            
            TextField("Type your message", text: $viewModel.messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
                .padding()
            
            Text("\(viewModel.messageText.count)/100")
                .font(.caption)
                .foregroundStyle(viewModel.messageText.count > 100 ? .red : .secondary)
            
            Button("Lock Message with Facial Expressions 🔒") {
                viewModel.startExpressionRecording()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.messageText.isEmpty || viewModel.messageText.count > 100)
        }
        .padding()
    }
    
    private var expressionRecordingView: some View {
        VStack {
            ARFaceTrackingView(
                detectedExpression: $viewModel.faceDetector.currentExpression,
                showDebugOverlay: false
            )
            .overlay(alignment: .top) {
                VStack {
                    Text("Expression \(viewModel.expressionRecorder.currentStep + 1) of 5")
                        .font(.headline)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                }
                .padding()
            }
            
            // Progress indicator
            HStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { index in
                    if index < viewModel.expressionRecorder.recordedExpressions.count {
                        Text(viewModel.expressionRecorder.recordedExpressions[index].emoji)
                            .font(.title)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                    }
                }
            }
            .padding()
        }
        .onChange(of: viewModel.faceDetector.currentExpression) { old, new in
            if let expr = new {
                viewModel.handleDetectedExpression(expr)
            }
        }
    }
    
    private var generatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Creating your encrypted message...")
                .font(.headline)
        }
    }
    
    private var shareGIFView: some View {
        VStack(spacing: 20) {
            Text("Message Locked! 🎉")
                .font(.title)
                .fontWeight(.bold)
            
            if let gifURL = viewModel.generatedGIFURL {
                AnimatedGIFView(url: gifURL)
                    .frame(height: 300)
                    .cornerRadius(12)
                
                if let message = viewModel.createdMessage {
                    Text("Message ID: \(message.id)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                ShareLink(item: gifURL, preview: SharePreview("Secret Message", image: Image(systemName: "lock.fill"))) {
                    Label("Share GIF", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Create Another") {
                    viewModel.reset()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}
```

### Testing Checklist
- [ ] Can enter message text
- [ ] Character counter works (max 100)
- [ ] Can't proceed with empty message
- [ ] Camera starts when "Lock Message" tapped
- [ ] Can record all 5 expressions
- [ ] Progress shows recorded expressions
- [ ] GIF generates after 5th expression
- [ ] Message saved to Supabase with:
  - [ ] expression_hash (comma-separated)
  - [ ] message text
  - [ ] expression_list (same as hash)
- [ ] Message ID matches database row ID
- [ ] Can share GIF via Messages/AirDrop
- [ ] "Create Another" resets flow correctly
- [ ] Error handling for:
  - [ ] Network failure
  - [ ] Duplicate expression hash (unique constraint)
  - [ ] GIF generation failure

### Success Criteria
✅ Complete encode flow works end-to-end  
✅ Message saved to database  
✅ GIF shareable outside app  

### Demo for This Phase
**Video (~1.5min):**
1. Open Encode tab
2. Type message: "Hey wanna play roblox later? im eating pizza rn 🍕"
3. Tap "Lock Message"
4. Perform 5 expressions (show camera + progress)
5. Wait for GIF generation
6. Show generated GIF playing
7. Tap share → send via Messages
8. Open Messages to verify GIF received

---

## 🔴 PHASE 5: Decode Flow
**Branch:** `feature/decode-flow`  
**Time Estimate:** 2-3 hours  
**Dependencies:** Phases 1-4 merged  
**Test Before Merge:** Full decode flow with correct/incorrect sequences

### Objectives
- Build complete decoding UI flow
- Import GIF and extract message ID
- Perform expression sequence to unlock
- Validate against database
- Show decrypted message with animation

### File Checklist

#### ✅ Update `ViewModels/DecodeViewModel.swift`
```swift
@Observable
class DecodeViewModel {
    // Existing: message list
    var messages: [Message] = []
    var isLoading = false
    var errorMessage: String?
    
    // New: decoding flow
    var isDecoding = false
    var decodingRecorder = ExpressionRecorder()
    var decodingDetector = ARFaceDetector()
    var selectedGIFURL: URL?
    var extractedMessageID: String?
    var decodedMessage: Message?
    var attemptError: String?
    
    enum DecodingStep {
        case selectGIF
        case performExpressions
        case validating
        case messageRevealed
        case incorrectSequence
    }
    var currentDecodingStep: DecodingStep = .selectGIF
    
    func fetchMessages() async { /* existing */ }
    
    func selectGIF(url: URL) async {
        selectedGIFURL = url
        extractedMessageID = await MessageIDExtractor.extractMessageID(from: url)
        
        if extractedMessageID != nil {
            currentDecodingStep = .performExpressions
            decodingDetector.startTracking()
            decodingRecorder.startRecording()
        } else {
            attemptError = "Could not read message ID from GIF"
        }
    }
    
    func handleDecodingExpression(_ expression: FaceExpression) {
        guard currentDecodingStep == .performExpressions else { return }
        
        if decodingRecorder.recordExpression(expression) {
            HapticManager.expressionDetected()
            
            if decodingRecorder.isComplete {
                Task {
                    await validateSequence()
                }
            }
        }
    }
    
    func validateSequence() async {
        currentDecodingStep = .validating
        decodingDetector.stopTracking()
        
        do {
            let attemptedHash = decodingRecorder.getExpressionHash()
            
            if let message = try await MessageService.shared.fetchMessage(byHash: attemptedHash) {
                // Success!
                decodedMessage = message
                currentDecodingStep = .messageRevealed
                HapticManager.sequenceComplete()
            } else {
                // Wrong sequence
                attemptError = "No message found with this sequence.\nYou performed: \(attemptedHash)"
                currentDecodingStep = .incorrectSequence
                HapticManager.error()
            }
        } catch {
            attemptError = error.localizedDescription
            currentDecodingStep = .incorrectSequence
            HapticManager.error()
        }
    }
    
    func resetDecoding() {
        isDecoding = false
        decodingRecorder.reset()
        selectedGIFURL = nil
        extractedMessageID = nil
        decodedMessage = nil
        attemptError = nil
        currentDecodingStep = .selectGIF
        decodingDetector.stopTracking()
    }
}
```

#### ✅ Update `Views/DecodeView.swift`
```swift
struct DecodeView: View {
    @State private var viewModel = DecodeViewModel()
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationStack {
            if viewModel.isDecoding {
                decodingFlowView
            } else {
                messageListView
            }
        }
    }
    
    private var messageListView: some View {
        VStack {
            Button {
                showingImagePicker = true
            } label: {
                Label("Decode a New GIF", systemImage: "lock.open.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            // Existing message list
            if viewModel.isLoading {
                ProgressView("Loading messages...")
            } else if viewModel.messages.isEmpty {
                ContentUnavailableView(
                    "No Messages",
                    systemImage: "tray.fill",
                    description: Text("No messages in database.")
                )
            } else {
                List(viewModel.messages) { message in
                    MessageRowView(message: message)
                }
                .refreshable {
                    await viewModel.fetchMessages()
                }
            }
        }
        .navigationTitle("Decode")
        .task {
            await viewModel.fetchMessages()
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker { url in
                viewModel.isDecoding = true
                Task {
                    await viewModel.selectGIF(url: url)
                }
            }
        }
    }
    
    private var decodingFlowView: some View {
        Group {
            switch viewModel.currentDecodingStep {
            case .selectGIF:
                Text("Select GIF...")
            case .performExpressions:
                performExpressionsView
            case .validating:
                validatingView
            case .messageRevealed:
                messageRevealedView
            case .incorrectSequence:
                incorrectSequenceView
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewModel.resetDecoding()
                }
            }
        }
    }
    
    private var performExpressionsView: some View {
        VStack {
            // Show GIF playing (as hint)
            if let gifURL = viewModel.selectedGIFURL {
                VStack {
                    Text("Watch the GIF to learn the sequence")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    AnimatedGIFView(url: gifURL)
                        .frame(height: 150)
                        .cornerRadius(8)
                }
                .padding()
            }
            
            Divider()
            
            // Camera for performing sequence
            ARFaceTrackingView(
                detectedExpression: $viewModel.decodingDetector.currentExpression,
                showDebugOverlay: false
            )
            .overlay(alignment: .top) {
                Text("Perform expression \(viewModel.decodingRecorder.currentStep + 1) of 5")
                    .font(.headline)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding()
            }
            
            // Progress
            HStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { index in
                    if index < viewModel.decodingRecorder.recordedExpressions.count {
                        Text(viewModel.decodingRecorder.recordedExpressions[index].emoji)
                            .font(.title)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 40, height: 40)
                    }
                }
            }
            .padding()
        }
        .onChange(of: viewModel.decodingDetector.currentExpression) { old, new in
            if let expr = new {
                viewModel.handleDecodingExpression(expr)
            }
        }
    }
    
    private var validatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Validating sequence...")
                .font(.headline)
        }
    }
    
    private var messageRevealedView: some View {
        VStack(spacing: 20) {
            Text("🎉 Message Unlocked!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let message = viewModel.decodedMessage {
                Text(message.message ?? "")
                    .font(.title3)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .transition(.scale.combined(with: .opacity))
            }
            
            Button("Done") {
                viewModel.resetDecoding()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var incorrectSequenceView: some View {
        VStack(spacing: 20) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            
            Text("Incorrect Sequence")
                .font(.title2)
                .fontWeight(.bold)
            
            if let error = viewModel.attemptError {
                Text(error)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 16) {
                Button("Try Again") {
                    viewModel.decodingRecorder.reset()
                    viewModel.currentDecodingStep = .performExpressions
                    viewModel.decodingDetector.startTracking()
                    viewModel.decodingRecorder.startRecording()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Cancel") {
                    viewModel.resetDecoding()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}
```

#### ✅ Create `Views/Components/ImagePicker.swift`
```swift
import PhotosUI
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    let onSelect: (URL) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onSelect: (URL) -> Void
        
        init(onSelect: @escaping (URL) -> Void) {
            self.onSelect = onSelect
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.hasItemConformingToTypeIdentifier(UTType.gif.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.gif.identifier) { url, error in
                    if let url = url {
                        // Copy to temp location
                        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".gif")
                        try? FileManager.default.copyItem(at: url, to: tempURL)
                        
                        DispatchQueue.main.async {
                            self.onSelect(tempURL)
                        }
                    }
                }
            }
        }
    }
}
```

### Testing Checklist
- [ ] Can tap "Decode a New GIF"
- [ ] Photo picker opens
- [ ] Can select a GIF from library
- [ ] Message ID extracted successfully
- [ ] GIF plays as hint in top half
- [ ] Camera starts for expression sequence
- [ ] Can perform 5 expressions
- [ ] Correct sequence → message reveals with animation
- [ ] Incorrect sequence → error shown with:
  - [ ] What sequence was attempted
  - [ ] "Try Again" button
  - [ ] "Cancel" button
- [ ] "Try Again" resets and allows new attempt
- [ ] "Done" returns to message list
- [ ] Message list still works (existing functionality)
- [ ] Refresh still works

### Edge Cases
- [ ] GIF without message ID → error message
- [ ] Network offline during validation → error
- [ ] Camera permission denied → show settings alert

### Success Criteria
✅ Complete decode flow works end-to-end  
✅ Correct sequence unlocks message  
✅ Wrong sequence shows helpful error  

### Demo for This Phase
**Video (~2min):**
1. Open Decode tab
2. Tap "Decode a New GIF"
3. Select the GIF from Phase 4 demo
4. Show GIF playing as hint
5. Perform correct 5-expression sequence
6. Show validation spinner
7. **SUCCESS:** Message reveals with animation
8. Tap "Done"
9. Repeat but perform WRONG sequence
10. **FAILURE:** Error shown with attempted sequence
11. Tap "Try Again" → perform correct sequence → success

---

## 🟣 PHASE 6: Polish & Final Integration
**Branch:** `feature/polish`  
**Time Estimate:** 1-2 hours  
**Dependencies:** Phases 1-5 merged  
**Test Before Merge:** Full app testing, all flows

### Objectives
- Remove test views
- Add animations and polish
- Improve error handling
- Add loading states
- Final bug fixes
- Prepare demo video

### File Checklist

#### ✅ Remove Temporary Views
- [ ] Delete `Views/FaceDetectionTestView.swift`
- [ ] Delete `Views/GIFTestView.swift`
- [ ] Remove test tab from `ContentView.swift`

#### ✅ Add Visual Polish

**EncodeView:**
- [ ] Add confetti animation when GIF generated (using SwiftUI)
- [ ] Smooth transitions between steps
- [ ] Better progress visualization
- [ ] Loading shimmer during GIF generation

**DecodeView:**
- [ ] Add particle burst animation on message reveal
- [ ] Smooth entrance animation for revealed message
- [ ] Better error state visuals

**ProfileView:**
- [ ] Add subtle animation when switching avatars
- [ ] Polish sprite preview grid

#### ✅ Improve Error Handling
```swift
// Add to EncodeViewModel & DecodeViewModel
private func handleError(_ error: Error) {
    if let urlError = error as? URLError {
        switch urlError.code {
        case .notConnectedToInternet:
            errorMessage = "No internet connection. Please check your network."
        case .timedOut:
            errorMessage = "Request timed out. Please try again."
        default:
            errorMessage = "Network error: \(urlError.localizedDescription)"
        }
    } else {
        errorMessage = error.localizedDescription
    }
    
    HapticManager.error()
}
```

#### ✅ Add Loading States
- [ ] Skeleton screens while fetching messages
- [ ] Better progress indicators with estimated time
- [ ] Disable buttons during async operations

#### ✅ Add Permission Handling
```swift
// Create Utilities/PermissionManager.swift
class PermissionManager {
    static func checkCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
    
    static func showSettingsAlert() {
        // Show alert with button to open Settings
    }
}
```

#### ✅ Add Onboarding (Optional)
- [ ] First-time user tutorial
- [ ] Show how to perform each expression
- [ ] Explain encode/decode flow

#### ✅ Code Cleanup
- [ ] Remove debug print statements
- [ ] Add proper logging
- [ ] Document complex functions
- [ ] Ensure consistent code style

### Testing Checklist

#### Full Flow Tests
- [ ] **Encode Flow:**
  1. Enter message
  2. Record 5 expressions
  3. GIF generates
  4. Message saved to DB
  5. Share works
  6. Reset works

- [ ] **Decode Flow:**
  1. Import GIF
  2. Message ID extracted
  3. Perform correct sequence
  4. Message reveals
  5. Can decode multiple messages
  6. Wrong sequence handled gracefully

- [ ] **Profile:**
  1. Switch avatars
  2. Selection persists
  3. Encoded GIFs use selected avatar

#### Edge Cases
- [ ] App works offline (except DB operations)
- [ ] Camera permission denied → helpful message
- [ ] Photos permission denied → helpful message
- [ ] Network errors handled gracefully
- [ ] Invalid GIF format handled
- [ ] Duplicate expression hash (unique constraint violation)
- [ ] Empty message text blocked
- [ ] Message too long (>100 chars) blocked

#### Performance
- [ ] App launches quickly
- [ ] ARKit tracking smooth (30+ fps)
- [ ] GIF generation <5 seconds
- [ ] Database queries <2 seconds
- [ ] No memory leaks
- [ ] No crashes during normal usage

#### UI/UX
- [ ] All text readable
- [ ] Buttons have appropriate sizes
- [ ] Safe area respected
- [ ] Dark mode works correctly
- [ ] Animations smooth
- [ ] Haptic feedback appropriate
- [ ] Loading indicators clear

### Success Criteria
✅ App feels polished and professional  
✅ All flows work smoothly  
✅ No critical bugs  
✅ Ready for demo video  

### Final Demo Video Script
**Total: 3 minutes**

**Intro (15s):**
- "ARFace Encrypter - Secure messages with facial expressions"
- Show app icon and opening screen

**Encode Flow (1min):**
1. Open Encode tab
2. Type: "Hey wanna play roblox later? im eating pizza rn 🍕"
3. Show character counter
4. Tap "Lock Message with Facial Expressions"
5. Perform 5 expressions (show camera + progress)
6. Show GIF generation
7. Preview generated GIF
8. Share via Messages

**Decode Flow (1min):**
1. Open Decode tab
2. Tap "Decode a New GIF"
3. Select the shared GIF
4. Show GIF playing as hint
5. Perform correct sequence
6. Show message reveal animation
7. Read decrypted message

**Wrong Sequence (30s):**
1. Import another GIF
2. Perform WRONG sequence
3. Show error message
4. Tap "Try Again"
5. Perform correct sequence → success

**Profile & Features (30s):**
1. Show Profile tab
2. Switch from Bear to Fox
3. Show sprite preview grid
4. Encode new message → show Fox avatar in GIF
5. Close with key features summary

---

## Branch Merge Strategy

```
main
 │
 ├─ feature/foundation-models (Phase 1)
 │   └─ merge to main → tag v0.1
 │
 ├─ feature/arkit-detection (Phase 2)
 │   └─ merge to main → tag v0.2
 │
 ├─ feature/gif-generation (Phase 3)
 │   └─ merge to main → tag v0.3
 │
 ├─ feature/encode-flow (Phase 4)
 │   └─ merge to main → tag v0.4
 │
 ├─ feature/decode-flow (Phase 5)
 │   └─ merge to main → tag v0.5
 │
 └─ feature/polish (Phase 6)
     └─ merge to main → tag v1.0 (FINAL)
```

### Merge Checklist (for each phase)
- [ ] All tests passing
- [ ] Code reviewed
- [ ] No console errors
- [ ] Feature works as expected
- [ ] Documentation updated
- [ ] Tag created after merge

---

## Time Breakdown

| Phase | Time Estimate | Critical Path |
|-------|---------------|---------------|
| Phase 1: Foundation | 1-2 hours | ✅ Must have |
| Phase 2: ARKit | 2-3 hours | ✅ Must have |
| Phase 3: GIF Gen | 2-3 hours | ✅ Must have |
| Phase 4: Encode | 2-3 hours | ✅ Must have |
| Phase 5: Decode | 2-3 hours | ✅ Must have |
| Phase 6: Polish | 1-2 hours | ⚠️ Nice to have |
| **TOTAL** | **10-16 hours** | **Core: 9-14 hours** |

### Minimum Viable Demo (4 hours)
If time is very limited:
1. **Phase 1** (1 hour)
2. **Phase 2** (1.5 hours)
3. **Phase 3** (1 hour)
4. **Phase 4** (30 min - basic encode)

This gives you: models + face detection + GIF generation + basic encoding flow.

### Full Feature Set (8-10 hours)
Phases 1-5 complete. Skip Phase 6 polish if time-constrained.

### Production Ready (14-16 hours)
All 6 phases complete with polish and thorough testing.

---

## Success Metrics

### Technical
- ✅ All 6 expressions detected reliably
- ✅ GIF generation <5 seconds
- ✅ Database operations successful
- ✅ No crashes during normal usage
- ✅ ARKit tracking smooth (30+ fps)

### UX
- ✅ Expression detection feels responsive
- ✅ Visual feedback is clear
- ✅ Error messages are helpful
- ✅ Flows are intuitive
- ✅ App feels polished

### Demo Quality
- ✅ 3-minute video shows all features
- ✅ Encode → Share → Decode works perfectly
- ✅ Wrong sequence error handled well
- ✅ Avatar switching demonstrated
- ✅ Professional presentation

---

## Risk Mitigation

### High Risk Items
1. **ARKit face detection accuracy**
   - Mitigation: Phase 2 dedicated to tuning thresholds
   - Test view for isolated testing
   - Adjustable thresholds in config file

2. **GIF generation complexity**
   - Mitigation: Use native ImageIO (no external deps)
   - Test in Phase 3 before integration
   - Fallback: simpler frame timing if needed

3. **Message ID extraction from GIF**
   - Mitigation: Text overlay is simple, high-contrast
   - Vision OCR is reliable for printed text
   - Fallback: GIF metadata if OCR fails

4. **Time constraints**
   - Mitigation: Clear phase priorities
   - MVP path defined (Phases 1-3 + basic 4)
   - Each phase independently testable

### Medium Risk Items
1. Sprite sheet extraction
2. Database unique constraint violations
3. Camera permissions on real device
4. GIF file size for sharing

---

## Next Steps

1. **Choose your timeline:**
   - 4 hours → Phases 1-3 + basic encode
   - 8 hours → Phases 1-5 (full features, minimal polish)
   - 14 hours → All 6 phases (production ready)

2. **Start with Phase 1:**
   ```bash
   git checkout -b feature/foundation-models
   ```

3. **Follow phase checklist:**
   - Complete all files in checklist
   - Test locally
   - Create demo video for phase
   - Merge when all tests pass

4. **Proceed sequentially:**
   - Each phase builds on the previous
   - Don't skip ahead
   - Test thoroughly before merging

Ready to start with Phase 1?
