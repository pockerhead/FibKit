//
//  ViewBuilder.swift
//  FibKit
//
//  Created by Артём Балашов on 06.09.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import Foundation

@resultBuilder
public struct FibViewBuilder {
    
    public static func buildBlock(_ components: FibLayoutElement...) -> [FibLayoutElement] {
        return components
    }
    
    public static func buildOptional(_ component: [FibLayoutElement]?) -> [FibLayoutElement] {
        component ?? []
    }
    
    public static func buildEither(first component: [FibLayoutElement]) -> [FibLayoutElement] {
        component
    }
    
    public static func buildEither(second component: [FibLayoutElement]) -> [FibLayoutElement] {
        component
    }
    
    public static func buildArray(_ components: [[FibLayoutElement]]) -> [FibLayoutElement] {
        components.flatMap({ $0 })
    }
}
