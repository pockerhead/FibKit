//
//  FibGrid + Cells.swift
//  
//
//  Created by Денис Садаков on 17.08.2023.
//

import Foundation


extension FibGrid {
	public func indexForCell(at point: CGPoint) -> Int? {
		for (index, cell) in zip(visibleIndexes, visibleCells) {
			if cell.point(inside: cell.convert(point, from: self), with: nil) {
				return index
			}
		}
		return nil
	}
	
	public func index(for cell: UIView) -> Int? {
		if let position = visibleCells.firstIndex(of: cell) {
			return visibleIndexes[position]
		}
		return nil
	}
	
	public func cell(at index: Int) -> UIView? {
		if let position = visibleIndexes.firstIndex(of: index) {
			return visibleCells[position]
		}
		return nil
	}
}
