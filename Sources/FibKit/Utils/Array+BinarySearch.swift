import Foundation


internal extension Collection {
  /// Finds such index N that predicate is true for all elements up to
  /// but not including the index N, and is false for all elements
  /// starting with index N.
  /// Behavior is undefined if there is no such N.
  func binarySearch(predicate: (Iterator.Element) -> Bool) -> Index {
	var low = startIndex
	var high = endIndex
	while low != high {
	  let mid = index(low, offsetBy: distance(from: low, to: high)/2)
	  if predicate(self[mid]) {
		low = index(after: mid)
	  } else {
		high = mid
	  }
	}
	return low
  }
	
	func optBinarySearch(predicate: (Iterator.Element) -> Bool) -> Index? {
	  var low = startIndex
	  var isFinded = false
	  var high = endIndex
	  while low != high {
		let mid = index(low, offsetBy: distance(from: low, to: high)/2)
		if predicate(self[mid]) {
		  low = index(after: mid)
		  isFinded = true
		} else {
		  high = mid
		}
	  }
	  guard isFinded else { return nil }
	  return low
	}
	
	/// Returns the element at the specified index if it is within bounds, otherwise nil.
	subscript(safe index: Index) -> Element? {
		return indices.contains(index) ? self[index] : nil
	}
	
	/// Return collection mapped with keypath
	func map<T>(_ keyPath: KeyPath<Element, T>) -> [T] {
		return map { $0[keyPath: keyPath] }
	}
	
	/// Return collection compact mapped with keypath
	func compactMap<T>(_ keyPath: KeyPath<Element, T?>) -> [T] {
		return compactMap { $0[keyPath: keyPath] }
	}
	
	/// Return collection sorted by keypath
	func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>, isDescend: Bool = false) -> [Element] {
		return sorted { a, b in
			if isDescend {
				return a[keyPath: keyPath] > b[keyPath: keyPath]
			}
			return a[keyPath: keyPath] < b[keyPath: keyPath]
		}
	}
	
	/// Return maximum element in collection by keypath
	func max<T: Comparable>(by keyPath: KeyPath<Element, T>) -> Element? {
		return self.max { a, b in
			return a[keyPath: keyPath] < b[keyPath: keyPath]
		}
	}
	
	/// Return minimum element in collection by keypath
	func min<T: Comparable>(by keyPath: KeyPath<Element, T>) -> Element? {
		return self.min { a, b in
			return a[keyPath: keyPath] < b[keyPath: keyPath]
		}
	}
}
