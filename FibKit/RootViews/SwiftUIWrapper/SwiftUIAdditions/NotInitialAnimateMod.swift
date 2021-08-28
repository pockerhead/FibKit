//
//  NotInitialAnimateMod.swift
//  FormView
//
//  Created by Артём Балашов on 16.04.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import SwiftUI

struct NotInitialAnimateMod: ViewModifier {

    var animation: Animation
    @State private var _animation: Animation? = nil
    
    func body(content: Content) -> some View {
        content
            .animation(_animation)
            .onAppear {
                delay(0.32) {
                    _animation = animation
                }
            }
    }
}

public extension View {
    
    func afterAppearAnimation(_ animation: Animation) -> some View {
        self.modifier(NotInitialAnimateMod(animation: animation))
    }
}
