import Foundation

@propertyWrapper
public struct Equated<Value>: Equatable {
  public init<T>(compare comparator: Comparator) where Value == T? {
	self.init(.none, compare: comparator)
  }
  
  public init(_ wrappedValue: Value, compare comparator: Comparator) {
	self.init(wrappedValue: wrappedValue, compare: comparator)
  }

  public init(wrappedValue: Value, compare comparator: Comparator) {
	self.wrappedValue = wrappedValue
	self.comparator = comparator
  }

  public var wrappedValue: Value
  public var comparator: Comparator

  public static func == (lhs: Equated<Value>, rhs: Equated<Value>) -> Bool {
	lhs.comparator.compare(lhs.wrappedValue, rhs.wrappedValue)
	  && rhs.comparator.compare(rhs.wrappedValue, lhs.wrappedValue)
  }
}

extension Equated where Value: Equatable {
  public init<T>() where Value == T? {
	self.init(wrappedValue: .none)
  }
  
  public init(wrappedValue: Value) {
	self.init(wrappedValue: wrappedValue, compare: .custom(==))
  }
}

extension Equated: Error where Value: Error {
  public init(_ wrappedValue: Value) {
	self.init(wrappedValue: wrappedValue)
  }
  
  public init(wrappedValue: Value) {
	self.init(
	  wrappedValue: wrappedValue,
	  compare: .localizedDescription
	)
  }
  
  public var localizedDescription: String { wrappedValue.localizedDescription }
}

extension Equated: Hashable where Value: Hashable {
  public func hash(into hasher: inout Hasher) {
	wrappedValue.hash(into: &hasher)
  }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Equated: Identifiable where Value: Identifiable {
  public var id: Value.ID { wrappedValue.id }
}

extension Equated {
  public struct Comparator {
	public let compare: (Value, Value) -> Bool
  }
}

extension Equated.Comparator {
  public static func custom(_ compare: @escaping (Value, Value) -> Bool) -> Self {
	return .init(compare: compare)
  }
  
  public static func property<Property: Equatable>(
	_ scope: @escaping (Value) -> Property
  ) -> Self {
	return .init { scope($0) == scope($1) }
  }
  
  public static func wrappedProperty<Wrapped, Property: Equatable>(
	_ scope: @escaping (Wrapped) -> Property
  ) -> Self where Value == Optional<Wrapped> {
	return .init { $0.map(scope) == $1.map(scope) }
  }
  
  public static var dump: Self {
	.init { lhs, rhs in
	  var (lhsDump, rhsDump) = ("", "")
	  Swift.dump(lhs, to: &lhsDump)
	  Swift.dump(rhs, to: &rhsDump)
	  return lhsDump == rhsDump
	}
  }
  
  public static var typedDump: Self {
	.init { lhs, rhs in
	  var (lhsDump, rhsDump) = ("\(type(of: lhs))", "\(type(of: rhs))")
	  Swift.dump(lhs, to: &lhsDump)
	  Swift.dump(rhs, to: &rhsDump)
	  return lhsDump == rhsDump
	}
  }
}
  
extension Equated.Comparator where Value: Error {
  public static var localizedDescription: Self {
	.property(\.localizedDescription)
  }
}
