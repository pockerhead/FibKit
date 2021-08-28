//
//  ViewModelProtocols.swift
//  FibKit
//
//  Created by Артём Балашов on 28.08.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import Foundation
import FibKit

/// View that configures with any ViewModelWithViewClass conformant, and optionaly, depends on it, can calculate self size
public protocol ViewModelConfigurable: UIView {

    /// Configures view
    /// - Parameter data: any ViewModelWithViewClass conformant
    func configure(with data: ViewModelWithViewClass?)

    /// returns size dependent on data and target size of superview
    /// - Parameters:
    ///   - targetSize: target size of superview
    ///   - data: any ViewModelWithViewClass conformant
    func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?) -> CGSize?
    
    /// returns size dependent on data and target size of superview
    /// - Parameters:
    ///   - targetSize: target size of superview
    ///   - data: any ViewModelWithViewClass conformant
    func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?,
                  horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize?

    /// Highlights the view
    /// - Parameter highlighted: isHighlighted
    func setHighlighted(highlighted: Bool)
}

public extension ViewModelConfigurable where Self: UICollectionViewCell {}

public protocol AnyViewModelSection {}
extension Array: AnyViewModelSection where Element == ViewModelWithViewClass? {}

/// ViewModel protocol that holds class of View that can configures with it
public protocol ViewModelWithViewClass: AnyViewModelSection {

    /// Unique id
    var id: String? { get }

    /// Unique id, stored property
    var storedId: String? { get set }

    /// Size hash if id of item is equal, but size need get changes
    var sizeHash: String? { get }

    /// should show view with skeleton shimmers
    var showDummyView: Bool { get set }
    
    /// user-defined additional info
    var userInfo: [AnyHashable: Any]? { get set }
    
    /// user-defined additional info
    var separator: ViewModelWithViewClass? { get }

    /// class of view, that can configures with current viewModel
    func viewClass() -> ViewModelConfigurable.Type

}

public protocol ViewModelWithAction: ViewModelWithViewClass {
    var action: (() -> Void)? { get }
}

public extension ViewModelConfigurable {

    func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?) -> CGSize? {
        nil
    }
    
    func sizeWith(_ targetSize: CGSize, data: ViewModelWithViewClass?,
                  horizontal: UILayoutPriority, vertical: UILayoutPriority) -> CGSize? {
        nil
    }
    func setHighlighted(highlighted: Bool) {}
}

// swiftlint:disable all
public extension ViewModelWithViewClass {
    
    /// user-defined additional info
    var separator: ViewModelWithViewClass? { nil }

    var id: String? {
        storedId
    }

    var storedId: String? {
        get { nil }
        set { () }
    }

    var showDummyView: Bool {
        get { false }
        set { () }
    }

    var sizeHash: String? {
        nil
    }
    
    var userInfo: [AnyHashable: Any]? {
        get { [:] }
        set { () }
    }
}

extension ViewModelConfigurable where Self: UIView {
    func configure(with data: ViewModelWithViewClass?) {}
}

public extension ViewModelConfigurable {

    static var bundle: Bundle {
        Bundle(for: self)
    }
}
