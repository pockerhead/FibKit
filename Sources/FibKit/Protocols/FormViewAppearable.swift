//
//  FormViewAppearable.swift
//  FormView
//
//  Created by Артём Балашов on 19.03.2021.
//  Copyright © 2021 DIT Moscow. All rights reserved.
//

import Foundation

public protocol FormViewAppearable: UIView {
    
    func onAppear(with formView: FibGrid?)
    
    func onDissappear(with formView: FibGrid?)
}
