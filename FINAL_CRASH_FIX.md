# Финальное исправление краша приложения

## Проблема
Приложение крашится при запуске с ошибкой:
- `domain: dyld; code: 1` - ошибка загрузки динамических библиотек
- `Unable to extract info plist from binary` - Info.plist не может быть извлечен

## Причина
Конфликт настроек в Xcode:
- `GENERATE_INFOPLIST_FILE = YES` - Xcode генерирует Info.plist автоматически
- `INFOPLIST_FILE = konnectapp/Info.plist` - также указан файл Info.plist
- В Info.plist использовались переменные `$(EXECUTABLE_NAME)`, которые не заменялись правильно

## Решение

### 1. Отключена автоматическая генерация Info.plist
Изменено `GENERATE_INFOPLIST_FILE = NO` в проекте.

### 2. Обновлен Info.plist с реальными значениями
Все переменные заменены на реальные значения:
- `$(EXECUTABLE_NAME)` → `konnectapp`
- `$(PRODUCT_BUNDLE_IDENTIFIER)` → `klabs.konnectapp`
- `$(PRODUCT_NAME)` → `konnectapp`
- И т.д.

### 3. Теперь нужно пересобрать

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

### 4. Создайте новый .ipa

```bash
# Найдите .app файл
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "konnectapp.app" -type d -path "*/Build/Products/Release-iphoneos/*" | head -1)

# Проверьте, что Info.plist есть в .app
ls -la "$APP_PATH/Info.plist"

# Создайте .ipa
mkdir -p Payload
cp -R "$APP_PATH" Payload/
zip -r konnectapp.ipa Payload
```

### 5. Установите через Sideloadly

1. Откройте Sideloadly
2. Перетащите новый `konnectapp.ipa`
3. Подключите iPhone
4. Нажмите "Start"

## Проверка

После установки проверьте:
1. Приложение должно запуститься без краша
2. Если все еще крашится, проверьте логи через Xcode → Window → Devices → View Device Logs

## Дополнительная диагностика

Если проблема сохраняется, проверьте:

1. **Info.plist в .app:**
   ```bash
   plutil -p Payload/konnectapp.app/Info.plist | head -20
   ```
   Должны быть все ключи с реальными значениями (не переменными)

2. **Архитектура:**
   ```bash
   lipo -info Payload/konnectapp.app/konnectapp
   ```
   Должно быть: `arm64` (НЕ `x86_64` или `arm64-simulator`)

3. **Подпись:**
   ```bash
   codesign -dvv Payload/konnectapp.app
   ```
   Sideloadly подпишет автоматически

