import Foundation

internal extension Array where Element: Comparable {
	func insertionIndex(of element: Element) -> Int {
		var lower = 0
		var upper = count - 1
		while lower <= upper {
			let middle = (lower + upper) / 2
			if self[middle] < element {
				lower = middle + 1
			} else if element < self[middle] {
				upper = middle - 1
			} else {
				return middle
			}
		}
		return lower
	}
}

internal extension Array {

	/// Return immutable element of array or nil
	/// - Parameter index: index
	func get(_ index: Int) -> Element? {
		if have(index) {
			return self[index]
		}
		return nil
	}

	func have(_ index: Int) -> Bool {
		return (index >= 0 && count > index)
	}

}

internal extension Array where Element : Equatable {

	mutating func mergeElements<C : Collection>(newElements: C) where C.Iterator.Element == Element{
		let filteredList = newElements.filter({!self.contains($0)})
		self.append(contentsOf: filteredList)
	}
	
	func mergingElements<C : Collection>(newElements: C) -> Array<Element> where C.Iterator.Element == Element {
		let filteredList = newElements.filter({!self.contains($0)})
		var mutSelf = self
		mutSelf.append(contentsOf: filteredList)
		return mutSelf
	}

}
