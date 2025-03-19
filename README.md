# Playground Browser

A versatile mobile web browser built with Flutter. Playground Browser allows you to browse the web with the ability to switch between mobile and desktop viewing modes.

## Features

- **Clean, modern UI** - A beautiful and intuitive interface for browsing the web
- **Desktop/Mobile Mode** - Switch between desktop and mobile user agent modes with a single tap
- **Bookmark Management** - Save and organize your favorite websites
- **Fast Navigation** - Quick controls for back, forward, refresh, and home
- **Search Integration** - Search the web directly from the address bar

## Screenshots

(Add screenshots here when ready for publishing)

## Getting Started

### Prerequisites

- Flutter SDK (3.7.2 or higher)
- Android Studio or VS Code with Flutter extensions

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/playground_browser.git
```

2. Navigate to the project directory:
```bash
cd playground_browser
```

3. Install dependencies:
```bash
flutter pub get
```

4. Run the app:
```bash
flutter run
```

## Build for Release

### Android

```bash
flutter build appbundle
```

### iOS

```bash
flutter build ipa
```

## Dependencies

- [webview_flutter](https://pub.dev/packages/webview_flutter) - For rendering web content
- [shared_preferences](https://pub.dev/packages/shared_preferences) - For storing bookmarks and settings
- [url_launcher](https://pub.dev/packages/url_launcher) - For handling external URLs

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Contributors and users of the app

---

Developed with ❤️ using Flutter