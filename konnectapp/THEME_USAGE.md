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

## Использование Glass эффекта (iOS 26+):

### Встроенный модификатор `.glassEffect()`

В iOS 26 Apple представила встроенный модификатор `.glassEffect()` для создания эффекта "жидкого стекла" в стиле Apple Music.

#### Простое использование:
```swift
Text("App Designer2")
    .glassEffect()

Button("Tap Me") {
    // действие
}
.glassEffect()
```

#### С параметрами и формой:
```swift
Text("Sample Text")
    .padding()
    .glassEffect(.regular.interactive(), in: .circle)

// Для прямоугольных элементов:
HStack {
    // содержимое
}
.padding()
.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20))
```

#### Для мини-плеера (полная ширина, скругление только сверху):
```swift
HStack {
    // содержимое мини-плеера
}
.padding()
.glassEffect(.regular.interactive(), in: UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
```

### Важные моменты:

1. **Доступность**: `.glassEffect()` доступен только в iOS 26.0+
   ```swift
   if #available(iOS 26.0, *) {
       view.glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 20))
   } else {
       // fallback для старых версий
   }
   ```

2. **Стили**:
   - `.regular` - стандартный эффект стекла
   - `.regular.interactive()` - интерактивный эффект (реагирует на нажатия)

3. **Формы**:
   - `.circle` - круг
   - `RoundedRectangle(cornerRadius: X)` - прямоугольник со скруглением
   - `UnevenRoundedRectangle(...)` - прямоугольник с разными радиусами для углов
   - `Capsule()` - капсула

4. **Кнопки без фона**: Для кнопок внутри glass контейнера используйте `.buttonStyle(PlainButtonStyle())` чтобы убрать стандартный фон кнопки.

