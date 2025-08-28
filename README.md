# D&D Adventure Companion ⚔️

A simple Flutter chat app with an AI Dungeon Master for D&D-style roleplay adventures.

## What it does 🤖

- 💬 Chat with an AI that acts as your D&D Dungeon Master
- 🧠 Powered by Google's Gemini AI with custom D&D instructions
- 💾 All messages stored locally on your device using Hive database
- 💙 Built with Flutter for cross-platform development

## Setup ⚙️

### Prerequisites 📋

- 🔧 Flutter SDK
- 🔥 Firebase account (for the AI)

### Installation 🚀

1. Clone and install dependencies:

   ```bash
   git clone <repository-url>
   cd simple_dnd_chat_app_flutter
   flutter pub get
   ```

2. Firebase setup:

   - Create a Firebase project
   - Enable Firebase AI (Gemini API)
   - Add your config files:
     - Update `lib/config/firebase_options.dart` for web

3. Run it:
   ```bash
   flutter run
   ```

## How to use 🎮

Just start typing! Tell the AI what kind of adventure you want:

- "I want to play a fantasy adventure as a wizard"
- "Create a sci-fi campaign"
- "I'm new to D&D, help me get started"

The AI will guide you through creating characters, rolling dice, and telling stories.

## Project structure 📁

```
lib/
├── app/           # App setup and theming
├── constants/     # AI instructions
├── data/          # Models and services
├── features/chat/ # Chat UI and logic
├── localizations/ # Text strings
└── main.dart      # Entry point
```

## Key files 📄

- `lib/constants/ai_system_instructions.dart` - The AI's D&D personality
- `lib/data/` - Data layer (models, repositories, services)
- `lib/features/chat/` - All the chat functionality
- `lib/localizations/app_en.arb` - UI text

## Customization 🎨

Want to change how the AI behaves? Edit the system instructions in `lib/constants/ai_system_instructions.dart`.

That's it! Have fun adventuring! 🎲

## Tech Stack 🛠️

- **Flutter** - Cross-platform UI framework
- **BLoC** - State management pattern for predictable app architecture
- **Hive** - Lightweight, fast NoSQL database (messages stored locally on device)
- **Firebase AI (Gemini)** - Google's advanced AI model (conversations sent for processing but not stored or linked to identity)
- **Markdown** - Rich text formatting for enhanced message display
- **i18n** - Internationalization support for multiple languages
- **Analytics** - Basic usage data collection (no personal data or user identification)

## License 📜

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
