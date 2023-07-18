//
//  FibViewHeaderViewModel.swift
//  SmartStaff
//
//  Created by artem on 03.04.2020.
//  Copyright © 2020 DIT. All rights reserved.
//


import UIKit

/// ViewModel for header of FibRootView that allows scrollview to stretch it
public protocol FibViewHeaderViewModel: ViewModelWithViewClass {

    /// allowed stretch directions of header, default is empty
    var allowedStretchDirections: Set<StretchDirection> { get }

    /// initial height of FibHeader, default is nil, that means header height will be calculated by autolayout engine
    var initialHeight: CGFloat? { get }

    /// minimum allowed height of header, default is nil
    var minHeight: CGFloat? { get }

    /// maximum allowed stretch of header, default is nil
    var maxHeight: CGFloat? { get }

    /// flag that make header must be at top of FibRootView view hierarchy, default is true
    var atTop: Bool { get }

    var preventFromReload: Bool { get }

}

public extension FibViewHeaderViewModel {
    var allowedStretchDirections: Set<StretchDirection> { [] }
    var initialHeight: CGFloat? { nil }
    var minHeight: CGFloat? { nil }
    var maxHeight: CGFloat? { nil }
    var atTop: Bool { true }
    var preventFromReload: Bool { false }
}

/// Stretch direction for FibViewHeaderViewModel
public enum StretchDirection {
    case up
    case down
}

/// Protocol for view that represents  FibViewHeaderViewModel, take changes when scroll view stretches it
public protocol FibViewHeader: ViewModelConfigurable, StickyHeaderView {

    /// Calls when didScroll function of formView is called, optional
    /// - Parameters:
    ///   - size: changed size of header
    ///   - initialHeight: initial height of header
    func sizeChanged(size: CGSize, initialHeight: CGFloat, maxHeight: CGFloat?, minHeight: CGFloat?)
}

public extension FibViewHeader {
    func sizeChanged(size: CGSize, initialHeight: CGFloat, maxHeight: CGFloat?, minHeight: CGFloat?) {}
}
