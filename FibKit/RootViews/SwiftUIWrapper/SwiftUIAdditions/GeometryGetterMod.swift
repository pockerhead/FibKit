//
//  GeometryGetterMod.swift
//  FormView
//
//  Created by Артём Балашов on 16.04.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import SwiftUI

struct GeometryGetterMod: ViewModifier {

    var getFrame: ((CGRect) -> Void)?
    
    func body(content: Content) -> some View {
        GeometryReader { g -> Color in
            self.getFrame?(g.frame(in: .global))
            return Color.clear // return content - doesn't work
        }
    }
}

extension View {
    
    func getFrame(_ frameGetter: ((CGRect) -> Void)?) -> some View {
        self.overlay(
            Color.clear
                .modifier(GeometryGetterMod(getFrame: frameGetter))
        )
    }
}
