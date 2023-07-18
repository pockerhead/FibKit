import Foundation

@propertyWrapper
internal struct Equated<Value>: Equatable {
  internal init<T>(compare comparator: Comparator) where Value == T? {
	self.init(.none, compare: comparator)
  }
  
  internal init(_ wrappedValue: Value, compare comparator: Comparator) {
	self.init(wrappedValue: wrappedValue, compare: comparator)
  }

  internal init(wrappedValue: Value, compare comparator: Comparator) {
	self.wrappedValue = wrappedValue
	self.comparator = comparator
  }

  internal var wrappedValue: Value
  internal var comparator: Comparator

  internal static func == (lhs: Equated<Value>, rhs: Equated<Value>) -> Bool {
	lhs.comparator.compare(lhs.wrappedValue, rhs.wrappedValue)
	  && rhs.comparator.compare(rhs.wrappedValue, lhs.wrappedValue)
  }
}

extension Equated where Value: Equatable {
  internal init<T>() where Value == T? {
	self.init(wrappedValue: .none)
  }
  
  internal init(wrappedValue: Value) {
	self.init(wrappedValue: wrappedValue, compare: .custom(==))
  }
}

extension Equated: Error where Value: Error {
  internal init(_ wrappedValue: Value) {
	self.init(wrappedValue: wrappedValue)
  }
  
  internal init(wrappedValue: Value) {
	self.init(
	  wrappedValue: wrappedValue,
	  compare: .localizedDescription
	)
  }
  
  internal var localizedDescription: String { wrappedValue.localizedDescription }
}

extension Equated: Hashable where Value: Hashable {
  internal func hash(into hasher: inout Hasher) {
	wrappedValue.hash(into: &hasher)
  }
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
extension Equated: Identifiable where Value: Identifiable {
  internal var id: Value.ID { wrappedValue.id }
}

extension Equated {
  internal struct Comparator {
	internal let compare: (Value, Value) -> Bool
  }
}

extension Equated.Comparator {
  internal static func custom(_ compare: @escaping (Value, Value) -> Bool) -> Self {
	return .init(compare: compare)
  }
  
  internal static func property<Property: Equatable>(
	_ scope: @escaping (Value) -> Property
  ) -> Self {
	return .init { scope($0) == scope($1) }
  }
  
  internal static func wrappedProperty<Wrapped, Property: Equatable>(
	_ scope: @escaping (Wrapped) -> Property
  ) -> Self where Value == Optional<Wrapped> {
	return .init { $0.map(scope) == $1.map(scope) }
  }
  
  internal static var dump: Self {
	.init { lhs, rhs in
	  var (lhsDump, rhsDump) = ("", "")
	  Swift.dump(lhs, to: &lhsDump)
	  Swift.dump(rhs, to: &rhsDump)
	  return lhsDump == rhsDump
	}
  }
  
  internal static var typedDump: Self {
	.init { lhs, rhs in
	  var (lhsDump, rhsDump) = ("\(type(of: lhs))", "\(type(of: rhs))")
	  Swift.dump(lhs, to: &lhsDump)
	  Swift.dump(rhs, to: &rhsDump)
	  return lhsDump == rhsDump
	}
  }
}
  
extension Equated.Comparator where Value: Error {
  internal static var localizedDescription: Self {
	.property(\.localizedDescription)
  }
}
