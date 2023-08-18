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
    
    private var task: DispatchWorkItem?

    public var data: [ViewModelWithViewClass?] {
        didSet {
            task?.cancel()
            task = nil
            let blockTask = DispatchWorkItem.init(block: {[weak self] in
                guard let self = self else { return }
                self.setNeedsReload()
            })
            self.task = blockTask
            DispatchQueue.main.async {[weak blockTask] in
                blockTask?.perform()
            }
        }
    }

    public var identifierMapper: FormViewIdentifierMapperFn {
        didSet {
            setNeedsReload()
        }
    }

    public init(data: [ViewModelWithViewClass?] = [], identifierMapper: @escaping FormViewIdentifierMapperFn = { index, data in "\(data?.id ?? String(index))" }) {
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

public final class FibGridForEachDataSource<T>: FibGridDataSource {
    
    private var task: DispatchWorkItem?

    private var needDidSet = false
    private var dataMapper: ((T) -> ViewModelWithViewClass?)
    private var _data: [T]
    public override var data: [ViewModelWithViewClass?] {
        didSet {
            guard needDidSet else { return }
            task?.cancel()
            task = nil
            let blockTask = DispatchWorkItem.init(block: {[weak self] in
                guard let self = self else { return }
                self.setNeedsReload()
            })
            self.task = blockTask
            DispatchQueue.main.async {
                blockTask.perform()
            }
        }
    }

    public init(data: [T], mapper: @escaping ((T) -> ViewModelWithViewClass?), identifierMapper: @escaping FormViewIdentifierMapperFn = { index, data in "\(data?.id ?? String(index))" }) {
        self.dataMapper = mapper
        self._data = data
        super.init()
    }

    public override var numberOfItems: Int {
        _data.count
    }

    public override func identifier(at: Int) -> String {
        if let data = _data[safe: at] {
            let vm = dataMapper(data)
            return identifierMapper(at, vm)
        } else {
            return ""
        }
    }

    public override func data(at: Int) -> ViewModelWithViewClass? {
        if let data = _data[safe: at] {
            let vm = dataMapper(data)
            return vm
        } else {
            return nil
        }
    }
}
