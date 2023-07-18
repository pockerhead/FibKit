//
//  SwipeStackView.swift
//  FormView
//
//  Created by Артём Балашов on 16.04.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import SwiftUI

struct SwipeStackView: View {
    
    var views: [SwipeView] = []
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(views, id: \.self) { view in
                view
            }
        }
        .ignoreSafeAreaIfNedded()
    }
}
