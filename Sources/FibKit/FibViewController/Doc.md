# Примеры использования FibViewController

`FibViewController` позволяет строить интерфейс на основе декларативных секций. В этом файле приведены базовые шаблоны построения контроллеров и рекомендации по их применению.

## Базовая структура

```swift
class MyViewController: FibViewController {
    override var body: SectionProtocol? {
        SectionStack {
            // Секции интерфейса
        }
    }
}
```

`body` возвращает корневую секцию. Чаще всего используется `SectionStack`, позволяющая объединять несколько секций.

## Несколько статических секций

```swift
override var body: SectionProtocol? {
    SectionStack {
        ViewModelSection {
            MyFirstView.ViewModel(text: "Первая секция")
        }
        ViewModelSection {
            MySecondView.ViewModel(text: "Вторая секция")
        }
        .header(MyHeaderViewModel())
    }
}
```

Заголовок подключается через метод `.header` соответствующей секции.

## Динамический список с `ForEachSection`

```swift
@Reloadable var items = ["One", "Two", "Three"]

override var body: SectionProtocol? {
    SectionStack {
        ForEachSection(data: items) { item in
            MyItemView.ViewModel(text: item)
        }
    }
}
```

При изменении `items` контроллер автоматически перерисует содержимое за счёт `@Reloadable`.

## Сложная композиция секций

Секции можно вкладывать друг в друга:

```swift
override var body: SectionProtocol? {
    SectionStack {
        ViewModelSection {
            MyHeaderView.ViewModel()
        }
        SectionStack {
            ForEachSection(data: 0..<5) { index in
                MyRowView.ViewModel(number: index)
            }
        }
    }
}
```

Такой подход удобен для построения экранов со сложной иерархией.

## Полезные модификаторы секций

Секции (`ViewModelSection`, `SectionStack` и другие) поддерживают ряд
модификаторов, которые позволяют гибко настраивать отступы,
анимации и обработчики действий.

```swift
ViewModelSection {
    MyView.ViewModel()
}
// Отступы от краёв контейнера
.inset(by: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
// Изменение расположения элементов
.rowLayout(spacing: 12)
// Установка фонового ViewModel
.background(FibSectionBackgroundView.ViewModel(color: .secondarySystemBackground))
// Стабильный идентификатор секции
.id("main_section")
// Отключаем прилипающий заголовок
.isSticky(false)
// Обработчик нажатия на элемент
.tapHandler { context in
    print("tapped", context.indexPath)
}
// Вызывается после полной перезагрузки секции
.didReload {
    print("reload finished")
}
```

- `inset(by:)` задаёт внутренние отступы секции.
- `rowLayout(spacing:)` или `flowLayout(spacing:)` меняют способ расположения
  элементов.
- `background(_:)` позволяет добавить фон к секции.
- `id(_:)` нужен для корректной анимации при обновлениях.
- `isSticky(_:)` управляет прилипающим поведением заголовка.
- `tapHandler(_:)` и `didReload` дают возможность отслеживать действия
  пользователя и момент перезагрузки.

## Обновление данных вручную

В случаях, когда требуется полностью заменить набор секций, можно работать со свойством `storedBody`:

```swift
func reloadContent() {
    storedBody = SectionStack {
        ViewModelSection {
            MyLoadingView.ViewModel()
        }
    }
    reload(animated: true)
}
```

## Конфигурация контроллера

`FibViewController` поддерживает настройку через структуру `Configuration`. Она
содержит две группы параметров:

- `viewConfiguration` — отвечает за внешний вид корневого `FibControllerRootView`:
  цвета фона, тип шторки, работу клавиатуры и прочие свойства.
- `navigationConfiguration` — описывает содержимое навигационной панели,
  включая заголовок, крупный заголовок и параметры поиска.

`viewConfiguration` включает в себя следующие поля:

- `viewBackgroundColor` — основной цвет фона экрана.
- `shutterType` — тип шторки (`.default` или `.rounded`).
- `shutterBackground` — цвет шторки в режиме `.default`.
- `roundedShutterBackground` — цвет шторки для режима `.rounded`.
- `shutterTopInset` — дополнительный отступ шторки сверху.
- `backgroundView` — функция, возвращающая кастомный фон.
- `backgroundViewInsets` — отступы для фонового представления.
- `headerBackgroundViewColor` — цвет фона области заголовка.
- `headerBackgroundEffectView` — эффект, применяемый к области заголовка.
- `shutterShadowClosure` — настройка тени шторки.
- `topInsetStrategy` — стратегия вычисления верхнего отступа (`safeArea`, `statusBar`, `top`, `custom`).
- `needFooterKeyboardSticks` — нужно ли приклеивать футер к клавиатуре.
- `footerBackgroundViewColor` — цвет фона футера.

`navigationConfiguration` настраивает панель навигации и содержит:

- `titleViewModel` — view model заголовка.
- `largeTitleViewModel` — view model крупного заголовка.
- `searchContext` — параметры встроенного поиска с полями:
  - `isForceActive` — постоянно активное поле поиска.
  - `placeholder` — текст-заглушка.
  - `hideWhenScrolling` — скрывать строку поиска при прокрутке.
  - `onSearchResults` — обработчик вводимого текста.
  - `onSearchBegin` / `onSearchEnd` — колбэки начала и окончания поиска.
  - `onSearchButtonClicked` — нажатие кнопки поиска.
  - `searchBarAppearance` — внешний вид `UISearchBar` (шрифт, иконка, цвет текста).

По умолчанию используется `FibViewController.defaultConfiguration`. Его можно
изменить один раз при старте приложения или переопределить в отдельном
контроллере:

```swift
// Глобальная настройка
FibViewController.defaultConfiguration = .init(
    viewConfiguration: .init(shutterType: .rounded),
    navigationConfiguration: .init()
)

// Конфигурация конкретного контроллера
override var configuration: FibViewController.Configuration? {
    .init(
        viewConfiguration: .init(viewBackgroundColor: .white),
        navigationConfiguration: .init(titleViewModel: MyHeader.ViewModel())
    )
}
```

При необходимости конфигурацию можно изменить динамически через свойство
`storedConfiguration`, после чего вызвать `reload()` для применения параметров.

## Итоги

`FibViewController` предоставляет гибкую систему построения экранов из секций. Используйте `SectionStack` для объединения блоков, `ForEachSection` для динамических данных и `storedBody` когда необходимо переопределить содержимое целиком.
