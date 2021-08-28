//
//  SwiftUI+Extension.swift
//  FormView
//
//  Created by Артём Балашов on 16.04.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import SwiftUI

extension View {
    
    /// Wrap SwiftUIView into UIKit wrapper, you may use it in any UIKit view or class
    /// - Parameter id: String identity of your data, must by uniq on any viewModel, default it get line and file from code, but if you maps any list of data into SwiftUIWrapper you must provide uniq id for each entity
    /// - Returns: SwiftUIWrapper with IdentifiableView\<Your SwiftUI view\> as Content
    public func asViewModel(id: String,
                            sizeHash: String? = nil) -> SwiftUIWrapper<IdentifiableView<Self>> {
        SwiftUIWrapper(content: { IdentifiableView(content: self, id: id) }, id: id)
            .sizeHash(sizeHash)
    }
    
    /// Wrap SwiftUIView into UIKit wrapper, you may use it in any UIKit view or class
    /// - Parameter id: String identity of your data, must by uniq on any viewModel, default it get line and file from code, but if you maps any list of data into SwiftUIWrapper you must provide uniq id for each entity
    /// - Returns: SwiftUIWrapper with IdentifiableView\<Your SwiftUI view\> as Content
    public func asViewModel(line: Int = #line,
                            file: String = #file) -> SwiftUIWrapper<IdentifiableView<Self>> {
        SwiftUIWrapper(content: { IdentifiableView(content: self,
                                                   id: "ViewModel_at_\(line)_in_\(file)") },
                       id: "ViewModel_at_\(line)_in_\(file)")
    }
}

extension View {
    
    @ViewBuilder
    func ignoreSafeAreaIfNedded() -> some View {
        if #available(iOS 14.0, *) {
            self.ignoresSafeArea()
        } else {
            self
        }
    }
}
