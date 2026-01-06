# Руководство по исправлению краша при запуске

## Проблема
Приложение крашится сразу при запуске с ошибкой `dyld` и `Unable to extract info plist from binary`.

## Причины
1. **Отсутствуют обязательные ключи в Info.plist** - iOS не может определить базовую информацию о приложении
2. **Неправильная подпись** - приложение не может запуститься без правильной подписи
3. **Неправильная архитектура** - собрано для симулятора вместо устройства

## Решение

### 1. Обновите Info.plist
Я уже обновил `Info.plist` с необходимыми ключами. Теперь нужно пересобрать приложение.

### 2. Пересоберите приложение

**В Xcode:**
1. Product → Clean Build Folder (⇧⌘K)
2. Выберите **"Any iOS Device"** (НЕ симулятор!)
3. Product → Build (⌘B)

**Или через командную строку:**
```bash
xcodebuild clean build \
  -project konnectapp.xcodeproj \
  -scheme konnectapp \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO
```

### 3. Создайте новый .ipa

```bash
# Найдите .app файл
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "konnectapp.app" -type d -path "*/Build/Products/Release-iphoneos/*" | head -1)

# Создайте .ipa
mkdir -p Payload
cp -R "$APP_PATH" Payload/
zip -r konnectapp.ipa Payload
```

### 4. Установите через Sideloadly

1. Откройте Sideloadly
2. Перетащите новый `konnectapp.ipa`
3. Подключите iPhone
4. Нажмите "Start"

## Проверка

После установки проверьте:
1. Приложение должно запуститься без краша
2. Если все еще крашится, проверьте логи через Xcode → Window → Devices → View Device Logs

## Дополнительные проверки

Если проблема сохраняется:

1. **Проверьте архитектуру:**
   ```bash
   lipo -info Payload/konnectapp.app/konnectapp
   ```
   Должно быть: `arm64` (НЕ `x86_64` или `arm64-simulator`)

2. **Проверьте Info.plist в .app:**
   ```bash
   plutil -p Payload/konnectapp.app/Info.plist
   ```
   Должны быть все ключи, особенно `CFBundleExecutable` и `CFBundleIdentifier`

3. **Проверьте подпись:**
   ```bash
   codesign -dvv Payload/konnectapp.app
   ```
   Sideloadly подпишет автоматически, но проверьте, что нет ошибок

