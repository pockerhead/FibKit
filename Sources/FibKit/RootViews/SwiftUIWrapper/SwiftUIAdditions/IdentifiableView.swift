//
//  IdentifiableView.swift
//  FormView
//
//  Created by Артём Балашов on 16.04.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import SwiftUI

public struct IdentifiableView<Content: View>: View {
    
    var content: Content
    var id: String
    public var body: some View {
        content
            .id(id)
            .ignoreSafeAreaIfNedded()
            .edgesIgnoringSafeArea(.all)
    }
}
