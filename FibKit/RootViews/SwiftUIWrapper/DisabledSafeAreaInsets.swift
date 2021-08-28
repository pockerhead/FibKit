//
//  DisabledSafeAreaInsets.swift
//  FormView
//
//  Created by Артём Балашов on 16.04.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import Foundation

public struct DisabledSafeAreaInsets: OptionSet {
    
    public static let top = DisabledSafeAreaInsets(rawValue: 1 << 0)
    public static let bottom = DisabledSafeAreaInsets(rawValue: 1 << 1)
    public static let left = DisabledSafeAreaInsets(rawValue: 1 << 2)
    public static let right = DisabledSafeAreaInsets(rawValue: 1 << 3)
    public static let all: DisabledSafeAreaInsets = [.top, .bottom, .left, .right]
    public static let never: DisabledSafeAreaInsets = []

    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
