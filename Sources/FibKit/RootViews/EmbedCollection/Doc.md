# Использование EmbedCollection

`EmbedCollection` — это ячейка UICollectionView со встроенным `FibGrid`. С её помощью можно поместить горизонтальный или вертикальный список внутрь основного экрана. Чаще всего компонент используют для создания горизонтальных рядов в экране с вертикальным `FlowLayout`.

## Row-секции во Flow-layout

1. Определите провайдер для внутреннего ряда и примените `rowLayout(spacing:)`, чтобы разместить элементы по горизонтали.

```swift
let rowProvider = ViewModelSection {
    (0..<10).map { index in
        MyRowView.ViewModel(text: "\(index)")
    }
}
.rowLayout(spacing: 8)
```

2. Передайте провайдер в `EmbedCollection.ViewModel` и задайте желаемую высоту ряда.

```swift
let row = EmbedCollection.ViewModel(provider: rowProvider)
    .height(100)
```

3. Используйте ряд внутри `SectionStack` вашего контроллера, настроенного через `flowLayout`.

```swift
override var body: SectionProtocol? {
    SectionStack {
        ViewModelSection { row }
        // другие секции …
    }
    .flowLayout(spacing: 16)
}
```

`EmbedCollection` можно подключать и как заголовок или футер, поскольку его view model реализует `FibViewHeaderViewModel`.

## Модификаторы ViewModel

`EmbedCollection.ViewModel` поддерживает набор методов для настройки поведения и внешнего вида коллекции.

```swift
EmbedCollection.ViewModel(provider: rowProvider)
    // Направление прокрутки (.horizontal по умолчанию)
    .scrollDirection(.vertical)
    // Высота строки для горизонтального режима
    .height(120)
    // Пользовательский размер для вертикальных списков
    .size(CGSize(width: 200, height: 300))
    // Включаем пагинацию и задаём стартовую страницу
    .paging(true, selectedPage: 0)
    // Своё отображение индикаторов страниц
    .pagerView(myPager)
    .pageControlView(myPageControl)
    // Отключение bounce и прокрутки
    .bounces(false)
    .scrollEnabled(false)
    // Внешний вид
    .backgroundColor(.systemBackground)
    .clipsToBounds(true)
```

Полезные дополнительные модификаторы:

- `id(_:)` — стабильный идентификатор элемента
- `offset(_:)` — дополнительный отступ
- `selectedPage(_:)` — переход на конкретную страницу
- `onAppear(_:)` / `onDissappear(_:)` — вызовы при появлении и скрытии
- `scrollDidScroll(_:)` / `scrollDidEnd(_:)` — отслеживание прокрутки
- `needAnimation(_:)` — включить или выключить анимацию прокрутки
- `allowedStretchDirections(_:)` и `atTop(_:)` — настройка растяжения при использовании в заголовке

Эти методы помогут тонко настроить EmbedCollection под нужды экрана.
