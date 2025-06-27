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

## Итоги

`FibViewController` предоставляет гибкую систему построения экранов из секций. Используйте `SectionStack` для объединения блоков, `ForEachSection` для динамических данных и `storedBody` когда необходимо переопределить содержимое целиком.
