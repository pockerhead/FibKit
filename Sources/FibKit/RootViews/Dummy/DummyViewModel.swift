//
//  DummyViewModel.swift
//  SmartStaff
//
//  Created by Danil Pestov on 25.06.2022.
//  Copyright © 2022 DIT. All rights reserved.
//

public protocol DummyViewModelProtocol {
    
}

/// Класс для упрощения выставления ``ViewModelWithViewClass/showDummyView-1zmo2`` во ``ViewModelWithViewClass`` и работы с шиммерами
public class DummyViewModel: FibCoreViewModel, DummyViewModelProtocol {
    
    /// Класс view, который будет использоваться для отрисовки как dummy view
    private var _viewClass: ViewModelConfigurable.Type
    
    /// Класс view, который будет использоваться для отрисовки как dummy view
    public override func viewClass() -> ViewModelConfigurable.Type {
        _viewClass
    }
    
    /// - parameter viewClass: Класс view, который будет использоваться для отрисовки как dummy view
    public init(viewClass: ViewModelConfigurable.Type) {
        self._viewClass = viewClass
    }
}

extension ViewModelWithViewClass where Self: DummyViewModelProtocol {
    /// should show view with skeleton shimmers
    public var showDummyView: Bool {
        true
    }
}
