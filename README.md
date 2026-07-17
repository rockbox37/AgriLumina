# Agrilumina

Flutter MVP for a phone-first agri marketplace: discover nearby buyers/sellers, spend credits to unlock contact, request an intro.

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
