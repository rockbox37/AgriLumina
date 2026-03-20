# my_first_flutter_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# my_first_flutter_app

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
