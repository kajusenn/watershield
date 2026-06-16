# Watermark App (Flutter) NOT FOR DOWNLOAD OR COPY
# made with AI

Aplikacja do nakładania watermarków (tekst, logo, tekst+logo) na obrazy i PDF.  
Przepisana z oryginalnego projektu Python/Kivy. Działa na **Windows** i **Android**.

## Pierwsze uruchomienie

Jeśli w folderze **nie ma** katalogów `android/` i `windows/`, wygeneruj je:

```bash
cd C:\Users\jasio\Desktop\watermark_app
flutter create . --project-name watermark_app --platforms=windows,android
```

Następnie:

```bash
flutter pub get
flutter run -d windows
```

## Android

W `android/app/src/main/AndroidManifest.xml` upewnij się, że masz uprawnienia do plików (dla Android 12+ `file_picker` zwykle wystarcza bez dodatkowych uprawnień).

Zbudowanie APK:

```bash
flutter build apk --release
```

Plik wynikowy: `build/app/outputs/flutter-apk/app-release.apk`

##debug

Czyszczenie
flutter clean

Pobieranie zależności
flutter pub get

Budowanie APK (DEBUG - do testów)
flutter build apk --debug

Budowanie APK (RELEASE - do instalacji)
flutter build apk --release

Uruchom na telefonie (debug)
flutter run

Uruchom na telefonie z konkretnym urządzeniem
flutter run -d RZCYA0K7FZP  # Twój telefon

## FOR ME

flutter clean
flutter pub get
flutter build apk --release

APK w: build/app/outputs/flutter-apk/app-release.apk


## Konfiguracja logo

Ścieżka do logo jest zapisywana w `config.json` w katalogu roboczym aplikacji (obok pliku wykonywalnego na Windows, w documents na Android).

## Struktura projektu

```
lib/
├── main.dart
├── models/
│   ├── settings_model.dart
│   └── app_model.dart
├── screens/
│   └── home_screen.dart
├── services/
│   ├── watermark_service.dart
│   ├── pdf_service.dart
│   ├── file_service.dart
│   └── app_controller.dart
├── theme/
│   └── app_theme.dart
└── widgets/
    ├── file_list.dart
    ├── settings_panel.dart
    ├── preview_panel.dart
    └── custom_widgets.dart
```

## Zależności

| Pakiet | Rola |
|--------|------|
| `image` | Manipulacja pikselami (watermark na obrazach) |
| `printing` | Renderowanie stron PDF do podglądu |
| `syncfusion_flutter_pdf` | Nakładanie watermarku na istniejące PDF |
| `pdf` | Tworzenie warstw PDF |
| `file_picker` | Wybór plików (Windows + Android) |
| `path_provider` | Ścieżki zapisu na mobile |
| `provider` | Stan aplikacji |

## Folder output

Na Windows: `output/` w katalogu, z którego uruchamiasz aplikację (np. `watermark_app/output/`).

## Oryginalny projekt Python

Pliki `*.py` pozostają w repozytorium jako referencja. Nowa aplikacja Flutter jest w `lib/`.
