//
//  Protocols.swift
//  FormView
//
//  Created by Артём Балашов on 16.04.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import UIKit

public protocol SwipeControlledView: UIView {
    
    var haveSwipeAction: Bool { get }
    var isSwipeOpen: Bool { get }
    func animateSwipe(direction: SwipeType, isOpen: Bool, swipeWidth: CGFloat?, initialVel: CGFloat?, completion: (() -> Void)?)
}

public enum SwipeType {
    case left
    case right
}
