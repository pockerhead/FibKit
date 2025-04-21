# Документация для FibCoreView

## Обзор

`FibCoreView` — это универсальный подкласс UIView, который служит базовым классом для повторно используемых представлений в рамках FibKit. Он предоставляет расширенную функциональность:

- Конфигурация через view model
- Свайп-действия
- Эффекты выделения
- Поддержка drag-and-drop
- Настройка внешнего вида
- Трекинг аналитики
- Отображение подсказок
- Контекстные меню
- Управление повторным использованием

## Основная функциональность

### Инициализация

```swift
public override init(frame: CGRect)
public required init?(coder: NSCoder)
```

### Основные свойства

| Свойство | Тип | Описание |
|----------|------|-------------|
| `contentView` | `UIView` | Основной контейнер для контента |
| `data` | `FibCoreViewModel?` | Текущая view model |
| `isSwipeOpen` | `Bool` | Открыты ли свайп-действия |
| `haveSwipeAction` | `Bool` | Есть ли настроенные свайп-действия |
| `isHighlighted` | `Bool` | Текущее состояние выделения |
| `canBeReordered` | `Bool` | Можно ли переупорядочивать view в коллекции |

### Настройка внешнего вида

```swift
public struct Appearance {
    public var coloredBackgroundDefaultColor: UIColor
}

public static var defaultAppearance = Appearance()
public var appearance: Appearance?
```

### Управление повторным использованием

```swift
public static let sharedReuseManager: CollectionReuseViewManager
public func prepareForReuse()
```

## Ключевые методы

### Конфигурация view

```swift
open func configureUI()
open func configureAppearance()
open func configure(with data: ViewModelWithViewClass?)
open func configure(with data: ViewModelWithViewClass?, isFromSizeWith: Bool)
```

### Расчет размеров

```swift
open func sizeWith(_ targetSize: CGSize, 
                  data: ViewModelWithViewClass?, 
                  horizontal: UILayoutPriority, 
                  vertical: UILayoutPriority) -> CGSize?
open func backgroundSizeWith(_ targetSize: CGSize, 
                           data: ViewModelWithViewClass?, 
                           horizontal: UILayoutPriority, 
                           vertical: UILayoutPriority) -> CGSize?
```

### Эффекты выделения

```swift
public func setHighlighted(highlighted: Bool)
public func highlightSqueeze(highlighted: Bool)
public func highlightColoredBackground(highlighted: Bool, color: UIColor? = nil)
```

### Свайп-действия

```swift
public func animateSwipe(direction: SwipeType, 
                        isOpen: Bool, 
                        swipeWidth: CGFloat?, 
                        initialVel: CGFloat?, 
                        completion: (() -> Void)?)
```

### События жизненного цикла

```swift
public func onAppear(with formView: FibGrid?)
public func onDissappear(with formView: FibGrid?)
```

### Drag-and-drop

```swift
open func onDragBegin()
open func onDragEnd()
open var canStartDragSession: Bool
```

## Рекомендации по наследованию

При создании подклассов `FibCoreView` следует:

1. Переопределять `configureUI()` для настройки иерархии view
2. Вызывать `super` при переопределении ключевых методов
3. Использовать предоставленный `contentView` как основной контейнер
4. Реализовывать `getAnalyticsMolecule(for:)` для трекинга аналитики
5. Учитывать доступные эффекты выделения

## FibSectionBackgroundView

Специализированный подкласс для фона секций с дополнительными возможностями стилизации.

### Ключевые особенности

- Стилизация фона с тенями и границами
- Поддержка скругления углов
- Настройка отступов
- Опции маскирования

### Пример использования

```swift
let backgroundModel = FibSectionBackgroundView.ViewModel()
    .backgroundColor(.systemBackground)
    .cornerRadius(12)
    .shadowColor(.black.withAlphaComponent(0.1))
    .shadowOpacity(0.5)
    .shadowRadius(8)
    .insets(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
```

## Лучшие практики

1. Используйте паттерн view model для конфигурации
2. Используйте встроенный менеджер повторного использования для производительности
3. Применяйте эффекты выделения для обратной связи при взаимодействии
4. Реализуйте трекинг аналитики через `getAnalyticsMolecule(for:)`
5. Рассмотрите свайп-действия для дополнительных действий пользователя

## Примечания

- View автоматически обрабатывает большинство touch-взаимодействий
- Свайп-действия управляются внутренним `FibCoreSwipeCoordinator`
- Эффекты выделения можно кастомизировать через view model
- View поддерживает как программную инициализацию, так и через Interface Builder

# Документация для FibCoreViewModel

## Обзор

`FibCoreViewModel` - это базовая ViewModel для работы с `FibCoreView` в рамках FibKit. Она предоставляет гибкую систему конфигурации представлений с поддержкой:

- Управления размерами и layout-стратегиями
- Настройки свайп-действий
- Обработки пользовательских взаимодействий
- Drag-and-drop функциональности
- Контекстных меню и подсказок
- Анимаций и эффектов

## Основные свойства

| Свойство | Тип | Описание |
|----------|------|-------------|
| `id` | `String?` | Уникальный идентификатор ViewModel |
| `size` | `Size?` | Стратегия расчета размеров |
| `interactive` | `Bool` | Флаг интерактивности view |
| `highlight` | `HighLight` | Эффект выделения при взаимодействии |
| `canBeReordered` | `Bool` | Возможность переупорядочивания |
| `canStartDragSession` | `Bool` | Возможность начала drag-сессии |
| `corneredOnSwipe` | `Bool` | Скругление углов при свайпе |

## Конфигурационные методы

### Базовые настройки

```swift
func id(_ id: String) -> Self
func sizeHash(_ sizeHash: String) -> Self
func userInfo(_ userInfo: [AnyHashable: Any]) -> Self
```

### Размеры и позиционирование

```swift
func minHeight(_ height: CGFloat) -> Self
func maxHeight(_ height: CGFloat) -> Self
func allowedStretchDirections(_ directions: Set<StretchDirection>) -> Self
func sizeStrategy(_ size: Size) -> Self
func transform(_ transform: CGAffineTransform) -> Self
```

### Свайп-действия

```swift
func rightSwipeViews(mainSwipeView: FibSwipeViewModel, ...) -> Self
func leftSwipeViews(mainSwipeView: FibSwipeViewModel, ...) -> Self
```

### Обработка взаимодействий

```swift
func highlight(_ highlight: HighLight) -> Self
func interactive(_ int: Bool) -> Self
func onTap(_ onTap: ((UIView) -> Void)?) -> Self
func onLongTap(_ context: LongTapContext) -> Self
func onAnalyticsTap(_ onAnalyticsTap: ((String) -> Void)?) -> Self
```

### Drag-and-drop

```swift
func onDrag(_ itemsProvider: (() -> [UIDragItem])?) -> Self
func onDrop(with delegate: UIDropInteractionDelegate?) -> Self
func canBeReordered(_ can: Bool) -> Self
func canStartDragSession(_ can: Bool) -> Self
```

### Вспомогательные элементы

```swift
func contextMenu(_ menu: FibContextMenu) -> Self
func fibContextMenu(_ menu: ContextMenu?, isSecure: Bool = false) -> Self
func tooltip(_ tooltip: Tooltip) -> Self
func separator(_ separator: ViewModelWithViewClass?) -> Self
```

### Жизненный цикл

```swift
func onAppear(_ onAppear: ((UIView) -> Void)?) -> Self
func onDissappear(_ onDissappear: ((UIView) -> Void)?) -> Self
```

## Вложенные типы

### Tooltip

Конфигурация всплывающих подсказок:

```swift
public struct Tooltip {
    public enum TooltipType {
        case text(text: String)
        case custom(view: FibCoreViewModel, marker: TooltipMarkerViewModel?)
    }
    
    var needShow: Bool
    var tooltipType: TooltipType
    var completion: (() -> Void)?
}
```

### LongTapContext

Контекст долгого нажатия:

```swift
public struct LongTapContext {
    public var longTapDuration: TimeInterval = 0.6
    public var longTapStarted: ((UIGestureRecognizer, FibCoreView) -> Void?
    public var longTapEnded: ((UIGestureRecognizer, FibCoreView) -> Void?
    public var allowSqueeze: Bool = true
}
```

### HighLight

Варианты эффектов выделения:

```swift
public enum HighLight {
    case squeeze // сжатие
    case coloredBackground // изменение фона
    case coloredCustomBackground(color: UIColor) // кастомный цвет фона
    case custom(closure: (FibCoreView, Bool) -> Void) // полностью кастомный эффект
    
    public static var card: HighLight // предустановленный карточный стиль
}
```

### Size

Стратегии расчета размеров:

```swift
public struct Size {
    public var width: Strategy = .inherit
    public var height: Strategy = .inherit
    
    public enum Strategy: Equatable, ExpressibleByIntegerLiteral {
        case inherit // наследовать размер
        case selfSized // авторазмер
        case absolute(CGFloat) // фиксированное значение
        case lessThan(CGFloat) // не больше значения
        case greaterThan(CGFloat) // не меньше значения
    }
}
```

## Примеры использования

### Базовый пример

```swift
let viewModel = FibCoreViewModel()
    .id("user_cell")
    .sizeStrategy(.width(.absolute(300), height: .selfSized))
    .interactive(true)
    .highlight(.squeeze)
    .onTap { view in
        print("Cell tapped")
    }
```

### Пример со свайп-действиями

```swift
let deleteAction = FibSwipeViewModel(...)
let archiveAction = FibSwipeViewModel(...)

let viewModel = FibCoreViewModel()
    .rightSwipeViews(
        mainSwipeView: deleteAction,
        secondSwipeView: archiveAction
    )
    .leftSwipeViews(
        mainSwipeView: FibSwipeViewModel(...)
    )
```

### Пример с контекстным меню

```swift
let menu = FibContextMenu(...)
let viewModel = FibCoreViewModel()
    .contextMenu(menu)
    // Или через SwiftUI-like API:
    .fibContextMenu(
        ContextMenu(actions: [...]),
        isSecure: true
    )
```

## Особенности работы

1. **Fluent Interface**: Все методы конфигурации возвращают `Self`, что позволяет использовать цепочки вызовов.

2. **Стратегии размеров**: Гибкая система расчета размеров через `Size.Strategy`.

3. **Композиция**: Возможность комбинировать различные аспекты поведения (свайпы, меню, drag-and-drop).

4. **Типобезопасность**: Система типов Swift минимизирует ошибки конфигурации.

5. **Расширяемость**: Легко добавлять новые виды поведения через extension.
