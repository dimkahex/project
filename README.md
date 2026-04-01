## Pixel Neon Drone Dash (Flutter / Android)

Бесконечный раннер с пиксельным неоновым дроном (не птичка).

### Требования

- Flutter **3.19+** (у вас на Ubuntu уже ок)
- Android SDK (через `flutter doctor -v`)

### Быстрый старт (Ubuntu VM)

```bash
git clone <ВАШ_GITHUB_REPO_URL> pixel-neon-drone-dash
cd pixel-neon-drone-dash
chmod +x bootstrap.sh
./bootstrap.sh
cd build/pixel_neon_drone_dash
flutter pub get
flutter run
```

Сборка APK:

```bash
cd build/pixel_neon_drone_dash
flutter build apk --release
```

APK будет в:

`build/app/outputs/flutter-apk/app-release.apk`

### AdMob (Interstitial)

В проекте по умолчанию стоит **тестовый** interstitial id:

- Android test interstitial: `ca-app-pub-3940256099942544/1033173712`

Чтобы заменить на свой:

1. Открой `lib/main.dart`
2. Найди `adUnitId:` и замени на свой AdMob unit id.

Также проверь `android/app/src/main/AndroidManifest.xml` и добавь meta-data:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
```

### Leaderboard (Google Play Games Services)

В этом проекте leaderboards подключены **через платформенный канал-заглушку** (`MethodChannel`).
Чтобы сделать реальные Google Play Games leaderboard:

- добавь Play Games Services в Play Console
- подключи `play-services-games-v2` (или нужный стек) и реализуй методы в `MainActivity.kt`

### IAP Remove Ads (99₽)

Без внешних пакетов IAP реализован как **заглушка** через платформенный канал.
Для настоящих покупок потребуется Billing Client в Android и реализация в `MainActivity.kt`.

### Про структуру

- `template/` — исходники игры (Dart + Kotlin канал)
- `build/pixel_neon_drone_dash/` — генерируется скриптом `bootstrap.sh` (полный Flutter-проект)

