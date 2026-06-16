# Watermark App (Flutter)

Aplikacja do nakładania watermarków (tekst, logo, tekst+logo) na obrazy i PDF.  
Przepisana z oryginalnego projektu Python/Kivy. Działa na **Windows** i **Android**.

## Wymagania

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.22+
- Windows: Visual Studio 2022 z „Desktop development with C++”
- Android: Android Studio + SDK

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

## Użycie

1. **FILES** — dodaj pliki (JPG, PNG, WEBP, BMP, TIFF, PDF). Kliknij miniaturę, aby powiększyć i załadować podgląd.
2. **SETTINGS** — typ watermarku, tryb (corner/tile), suwaki, kolor, logo.
3. **PREVIEW** — podgląd na żywo (opóźnienie ~0,35 s). Dla PDF: nawigacja ◀ ▶.
4. **Generate / Export** — zapis do folderu `output/` z sufiksem `_watermarked`.

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
