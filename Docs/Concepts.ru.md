# Основные концепции

В этом документе рассматриваются ключевые идеи **FibKit**. Понимание этих принципов поможет эффективнее использовать библиотеку и строить декларативные интерфейсы.

## ViewModelWithViewClass

`ViewModelWithViewClass` — протокол, связывающий view model с классом представления, способного её отобразить. Модель предоставляет метод `viewClass()`, возвращающий тип `ViewModelConfigurable`, а также идентификаторы для диффинга.

Главные свойства из `ViewModel.swift`:

```swift
public protocol ViewModelWithViewClass: AnyViewModelSection {
    var id: String? { get }
    var storedId: String? { get set }
    var sizeHash: String? { get }
    var showDummyView: Bool { get set }
    var userInfo: [AnyHashable: Any]? { get set }
    var separator: ViewModelWithViewClass? { get }
    func viewClass() -> ViewModelConfigurable.Type
}
```

Конкретная view model реализует этот протокол и указывает, какой класс `UIView` использовать для отображения.

## ViewModelConfigurable

Представления, которые настраиваются через view model, реализуют протокол `ViewModelConfigurable`. Он определяет методы обновления состояния и вычисления размера на основе входных данных.

Упрощённое определение:

```swift
public protocol ViewModelConfigurable: UIView {
    func configure(with data: ViewModelWithViewClass?)
    func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?) -> CGSize?
    func sizeWith(_ targetSize: CGSize,
                  data: ViewModelWithViewClass?,
                  horizontal: UILayoutPriority,
                  vertical: UILayoutPriority) -> CGSize?
    func backgroundSizeWith(_ targetSize: CGSize,
                            data: ViewModelWithViewClass?,
                            horizontal: UILayoutPriority,
                            vertical: UILayoutPriority) -> CGSize?
    func setHighlighted(highlighted: Bool)
}
```

Разделение модели и представления позволяет сохранять декларативность и удобство тестирования.

## Провайдеры

Работу коллекций в FibKit обеспечивают *провайдеры*. Провайдер объединяет источник данных, источник представлений, источник размеров и объект лэйаута. Провайдеры можно составлять, формируя сложные структуры, — они служат основой для `FibGrid`.

Так, `BasicProvider` хранит источники данных и представлений и предоставляет обработчик `tapHandler`:

```swift
open class BasicProvider<Data, View: UIView>: ItemProvider, LayoutableProvider, CollectionReloadable {
    open var dataSource: DataSource<Data> { didSet { setNeedsReload() } }
    open var viewSource: ViewSource<Data, View> { didSet { setNeedsReload() } }
    open var sizeSource: SizeSource<Data> { didSet { setNeedsInvalidateLayout() } }
    open var layout: Layout { didSet { setNeedsInvalidateLayout() } }
    open var animator: Animator? { didSet { setNeedsReload() } }
    open var tapHandler: TapHandler?
    // ...
}
```

Провайдер сообщает количество элементов, создаёт и обновляет view и инициирует перерасчёт лэйаута.

## Диффинг

При вызове `reloadData()` `FibGrid` автоматически сравнивает идентификаторы текущих и новых элементов и анимированно вставляет или удаляет ячейки. В `FibGrid.swift` есть соответствующий комментарий:

```swift
// reload all frames. will automatically diff insertion & deletion
public func reloadData(contentOffsetAdjustFn: ((CGSize) -> CGPoint)? = nil) { ... }
```

Благодаря этому обновления можно описывать декларативно, не отслеживая индексы вручную.

## Декларативность

FibKit использует стиль, напоминающий SwiftUI. Контроллер возвращает дерево секций и view model из свойства `body`:

```swift
class MyViewController: FibViewController {
    override var body: SectionProtocol? {
        SectionStack {
            ViewModelSection { MyView.ViewModel(text: "Пример") }
        }
    }
}
```

Function builders помогают создавать вложенные структуры, а каждая view model описывает состояние соответствующего представления. Такой подход делает код компактным и понятным.
