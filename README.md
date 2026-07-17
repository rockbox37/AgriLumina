# Agrilumina

**Find a nearby buyer for this week’s crop — unlock their number, call or WhatsApp, done.**

Agrilumina is a phone-first marketplace for crop sellers and local buyers — usable anywhere, designed for rural farmers on poor or intermittent phone networks. Pick a role, find counterparts by distance (GPS when you have it; sample seed listings with precomputed distances when you don’t), open a listing, and spend a credit to unlock a phone number. Built for low bandwidth and word-of-mouth trade — not a chat-heavy app that assumes always-on data.

Flutter app. Core tabs: Home · Discover · Credits · Profile.

## Getting Started

- [Flutter docs](https://docs.flutter.dev/)
- [Cookbook](https://docs.flutter.dev/cookbook)

```bash
flutter pub get
flutter run
flutter analyze
flutter test
```

## Using the Workspace Agent

**Summary:** This repository includes a workspace-scoped agent configured as a concise Flutter pair-programmer. Its configuration is stored in `.agent.md` at the project root.

- **What it does:** Implements features, fixes bugs, refactors, writes tests, and makes small, focused patches.
- **Permissions:** May run `flutter` commands and apply automatic formatting; will ask per action before creating files or running non-flutter commands.
- **How to invoke:** Ask the agent in your editor's Copilot Chat or run your preferred workflow that loads workspace agents.
- **Example prompts:**
	- "Refactor `profilePage.dart` to extract a `ProfileHeader` widget and add tests."
	- "Implement login form with validation and unit tests."
	- "Run `flutter analyze` and fix reported Dart lints."

See `.agent.md` for full configuration and preferences.
