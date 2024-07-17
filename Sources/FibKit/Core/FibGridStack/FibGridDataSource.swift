//
//  FormViewDataSource.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//


import Foundation

public typealias FormViewIdentifierMapperFn = (Int, ViewModelWithViewClass?) -> String

open class FibGridDataSource: CollectionReloadable {
    
	private var reloadDebouncer = TaskDebouncer(delayType: .cyclesCount(6))

	var needReloadAfterDataChange = true
    public var data: [ViewModelWithViewClass?] {
		didSet {
			guard needReloadAfterDataChange else { return }
			reloadDebouncer.runDebouncedTask {[weak self] in
				guard let self = self else { return }
				self.setNeedsReload()
			}
		}
    }
	
	public func mutateDataWithoutReload(_ closure: (FibGridDataSource) -> Void) {
		needReloadAfterDataChange = false
		closure(self)
		needReloadAfterDataChange = true
	}

    public var identifierMapper: FormViewIdentifierMapperFn {
        didSet {
            setNeedsReload()
        }
    }

	public init(data: [ViewModelWithViewClass?] = [], identifierMapper: @escaping FormViewIdentifierMapperFn = { index, data in "\(data?.id ?? String(index))_\(String(describing: data?.viewClass()))" }) {
        self.data = data
        self.identifierMapper = identifierMapper
    }

    public var numberOfItems: Int {
        data.count
    }

    public func identifier(at: Int) -> String {
        if let data = data[safe: at] {
            return identifierMapper(at, data)
        } else {
            return ""
        }
        
    }

    public func data(at: Int) -> ViewModelWithViewClass? {
        data[safe: at] as? ViewModelWithViewClass
    }

}

public final class FibGridForEachDataSource<T, U>: FibGridDataSource where U: RandomAccessCollection<T>, U.Index == Int {
    private var dataMapper: ((T) -> ViewModelWithViewClass?)
    private var _data: U

    public init(data: U, mapper: @escaping ((T) -> ViewModelWithViewClass?), identifierMapper: @escaping FormViewIdentifierMapperFn = { index, data in "\(data?.id ?? String(index))" }) {
        self.dataMapper = mapper
        self._data = data
        super.init()
		self.data = .init(repeating: nil, count: data.count)
    }

    public override var numberOfItems: Int {
        _data.count
    }

	public override func identifier(at: Int) -> String {
		if let cached = data[safe: at], cached != nil {
			return identifierMapper(at, cached)
		} else if let data = _data[safe: at] {
			let vm = dataMapper(data)
			self.data[at] = vm
			return identifierMapper(at, vm)
		} else {
			return ""
		}
    }

    public override func data(at: Int) -> ViewModelWithViewClass? {
		if let cached = data[safe: at], cached != nil {
			return cached
		} else if let data = _data[safe: at] {
            let vm = dataMapper(data)
			self.data[at] = vm
            return vm
        } else {
            return nil
        }
    }
}
