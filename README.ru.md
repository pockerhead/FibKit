# FibKit

FibKit — это библиотека Swift, которая переносит декларативный стиль SwiftUI в UIKit. Она позволяет строить сложные асинхронные интерфейсы, сохраняя полный контроль над компонентами UIKit. Поддерживаются iOS 13 и выше, подключение осуществляется через Swift Package Manager.

## Возможности

- Описание интерфейса в духе SwiftUI с помощью function builders
- Все представления построены поверх UIKit
- Декларативные секции и view models для форм и списков
- Опциональные шаблоны генерации кода для представлений и контроллеров
- Пример iOS-приложения в папке FibExampleApp

## Начало работы

Добавьте зависимость в ваш `Package.swift`:

```swift
.package(url: "https://github.com/pockerhead/FibKit.git", from: "0.1.0")
```

Подключите `FibKit` к целям проекта:

```swift
.target(
    name: "YourApp",
    dependencies: ["FibKit"]
)
```

Откройте проект **FibExampleApp** в каталоге `FibExampleApp/`, чтобы увидеть рабочий пример.

## Структура репозитория

- `Sources/FibKit` — исходный код библиотеки
- `Sources/FibNavigation` — вспомогательная навигация
- `Tests/` — модульные тесты
- `FibExampleApp/` — пример приложения

## Документация

Подробный пример построения контроллеров с секциями расположен в файле [примеры FibViewController](Sources/FibKit/FibViewController/Doc.md). Документ охватывает статические секции, динамические списки и распространённые модификаторы.

О создании горизонтальных рядов с помощью EmbedCollection можно прочитать в [документации по EmbedCollection](Sources/FibKit/RootViews/EmbedCollection/Doc.md).

Документация по базовому представлению находится в файле
[FibCoreView](Sources/FibKit/RootViews/FibCore/FibCoreView/Doc.md).

## Сборка и тесты

Собрать пакет из командной строки можно так:

```bash
swift build
```

Запустить тесты:

```bash
swift test
```

## Вклад

Будем рады вашим предложениям и pull request. Если нашли проблему или хотите улучшить проект — создайте issue.
