# Использование системы тем

## Доступные цвета темы:

- `Color.appAccent` - акцентный цвет
- `Color.themeBackgroundStart` - начало градиента фона
- `Color.themeBackgroundEnd` - конец градиента фона
- `Color.themeBlockBackground` - фон блоков
- `Color.themeBlockBackgroundSecondary` - вторичный фон блоков
- `Color.themeTextPrimary` - основной текст
- `Color.themeTextSecondary` - вторичный текст
- `Color.themeBorder` - цвет границ

## Замена цветов:

Вместо:
```swift
Color(red: 0.13, green: 0.13, blue: 0.13) // фон блоков
Color(red: 0.1, green: 0.1, blue: 0.1) // фон
```

Используйте:
```swift
Color.themeBlockBackground
Color.themeBackgroundStart
```

