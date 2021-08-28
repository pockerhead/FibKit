//
//  FormViewDataSource.swift
//  SmartStaff
//
//  Created by artem on 28.03.2020.
//  Copyright © 2020 DIT. All rights reserved.
//


import Foundation

public typealias FormViewIdentifierMapperFn = (Int, ViewModelWithViewClass?) -> String

public final class FibGridDataSource: CollectionReloadable {
    
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
            DispatchQueue.main.async {
                blockTask.perform()
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
        identifierMapper(at, data[at])
    }

    public func data(at: Int) -> ViewModelWithViewClass? {
        data[at]
    }

}
