//
//  FunctionBuilders.swift
//  SmartStaff
//
//  Created by artem on 29.05.2020.
//  Copyright © 2020 DIT. All rights reserved.
//


import UIKit

public protocol AnyGridSection {}
extension Array: AnyGridSection where Element == SectionProtocol {}

/// Constructs sections in declarative style
/// eg:
///~~~
///@SectionBuilder var sections: [GridSection] {
///    GridSection {
///        FormViewSpacer(16)
///    }
///    GridSection {
///        FormViewSpacer(16)
///        SimpleLabelView.ViewModel(text: "SomeText")
///        FormViewSpacer(85)
///    }
///}
///~~~
@resultBuilder public struct SectionBuilder {
        
    public static func buildBlock(_ atrs: AnyGridSection...) -> [SectionProtocol] {
        if let arr = atrs as? [SectionProtocol] {
            return arr
        }
        var arr = [SectionProtocol]()
        fullFill(&arr, with: atrs)
        return arr
    }
    
    public static func buildOptional(_ atrs: AnyGridSection?...) -> [SectionProtocol] {
        if let arr = atrs as? [SectionProtocol] {
            return arr
        }
        var arr = [SectionProtocol]()
        fullFill(&arr, with: atrs)
        return arr
    }
    
    public static func buildArray(_ atrs: AnyGridSection?...) -> [SectionProtocol] {
        if let arr = atrs as? [SectionProtocol] {
            return arr
        }
        var arr = [SectionProtocol]()
        fullFill(&arr, with: atrs)
        return arr
    }
    
    public static func buildEither(first: AnyGridSection...) -> [SectionProtocol] {
        if let arr = first as? [SectionProtocol] {
            return arr
        }
        var arr = [SectionProtocol]()
        fullFill(&arr, with: first)
        return arr
    }
    
    public static func buildEither(second component: AnyGridSection...) -> [SectionProtocol] {
        if let arr = component as? [SectionProtocol] {
            return arr
        }
        var arr = [SectionProtocol]()
        fullFill(&arr, with: component)
        return arr
    }
    
    fileprivate static func fullFill(_ array: inout [SectionProtocol], with sections: [AnyGridSection?]) {
        for atr in sections {
            if let atr = atr as? SectionProtocol {
                array.append(atr)
            } else if let sectionArr = atr as? [SectionProtocol], !sectionArr.isEmpty {
                if sectionArr.allSatisfy({ $0.isGuard }) {
                    array = sectionArr
                    break
                } else if sectionArr.allSatisfy({ $0.isGuardAppend }) {
                    array.append(contentsOf: sectionArr)
                    break
                }
                array.append(contentsOf: sectionArr)
            }
        }
    }
    
    fileprivate static func fullFill(_ array: inout [SectionProtocol], with sections: AnyGridSection...) {
        for atr in sections {
            if let atr = atr as? SectionProtocol {
                array.append(atr)
            } else if let sectionArr = atr as? [SectionProtocol], !sectionArr.isEmpty {
                if sectionArr.allSatisfy({ $0.isGuard }) {
                    array = sectionArr
                    break
                } else if sectionArr.allSatisfy({ $0.isGuardAppend }) {
                    array.append(contentsOf: sectionArr)
                    break
                }
                array.append(contentsOf: sectionArr)
            }
        }
    }
    
    fileprivate static func fullFill(_ array: inout [SectionProtocol], with sections: [AnyGridSection]) {
        for atr in sections {
            if let atr = atr as? SectionProtocol {
                array.append(atr)
            } else if let sectionArr = atr as? [SectionProtocol], !sectionArr.isEmpty {
                if sectionArr.allSatisfy({ $0.isGuard }) {
                    array = sectionArr
                    break
                } else if sectionArr.allSatisfy({ $0.isGuardAppend }) {
                    array.append(contentsOf: sectionArr)
                    break
                }
                array.append(contentsOf: sectionArr)
            }
        }
    }
}
/// Constructs sections in declarative style
/// eg:
///~~~
///@ViewModelBuilder var items: [ViewModelWithViewClass] {
///    FormViewSpacer(16)
///    SimpleLabelView.ViewModel(text: "SomeText")
///    FormViewSpacer(85)
///}
///~~~
@resultBuilder public struct ViewModelBuilder {

    public static func buildBlock(_ atrs: AnyViewModelSection?...) -> [ViewModelWithViewClass?] {
        if let arr = atrs as? [ViewModelWithViewClass?] {
            return arr
        }
        var arr = [ViewModelWithViewClass?]()
        for atr in atrs {
            if let atr = atr as? ViewModelWithViewClass? {
                arr.append(atr)
            } else if let sectionArr = atr as? [ViewModelWithViewClass?] {
                arr.append(contentsOf: sectionArr)
            }
        }
        return arr
    }

    public static func buildBlock(_ atrs: [AnyViewModelSection?]) -> [ViewModelWithViewClass?] {
        if let arr = atrs as? [ViewModelWithViewClass?] {
            return arr
        }
        var arr = [ViewModelWithViewClass?]()
        atrs.forEach({ atr in
            if let atr = atr as? ViewModelWithViewClass? {
                arr.append(atr)
            } else if let sectionArr = atr as? [ViewModelWithViewClass?] {
                arr.append(contentsOf: sectionArr)
            }
        })
        return arr
    }
    
    public static func buildIf(_ atrs: AnyViewModelSection?...) -> [ViewModelWithViewClass?] {
        if let arr = atrs as? [ViewModelWithViewClass?] {
            return arr
        }
        var arr = [ViewModelWithViewClass?]()
        for atr in atrs {
            if let atr = atr as? ViewModelWithViewClass? {
                arr.append(atr)
            } else if let sectionArr = atr as? [ViewModelWithViewClass?] {
                arr.append(contentsOf: sectionArr)
            }
        }
        return arr
    }

    public static func buildIf(_ atrs: [AnyViewModelSection?]?) -> [ViewModelWithViewClass?] {
        if let arr = atrs as? [ViewModelWithViewClass?] {
            return arr
        }
        var arr = [ViewModelWithViewClass?]()
        (atrs ?? []).forEach({ atr in
            if let atr = atr as? ViewModelWithViewClass? {
                arr.append(atr)
            } else if let sectionArr = atr as? [ViewModelWithViewClass?] {
                arr.append(contentsOf: sectionArr)
            }
        })
        return arr
    }
    
    public static func buildEither(first: AnyViewModelSection?...) -> [ViewModelWithViewClass?] {
        if let arr = first as? [ViewModelWithViewClass?] {
            return arr
        }
        var arr = [ViewModelWithViewClass?]()
        for atr in first {
            if let atr = atr as? ViewModelWithViewClass? {
                arr.append(atr)
            } else if let sectionArr = atr as? [ViewModelWithViewClass?] {
                arr.append(contentsOf: sectionArr)
            }
        }
        return arr
    }

    public static func buildEither(first: [AnyViewModelSection?]) -> [ViewModelWithViewClass?] {
        if let arr = first as? [ViewModelWithViewClass?] {
            return arr
        }
        var arr = [ViewModelWithViewClass?]()
        first.forEach({ atr in
            if let atr = atr as? ViewModelWithViewClass? {
                arr.append(atr)
            } else if let sectionArr = atr as? [ViewModelWithViewClass?] {
                arr.append(contentsOf: sectionArr)
            }
        })
        return arr
    }
    
    public static func buildEither(second: AnyViewModelSection?...) -> [ViewModelWithViewClass?] {
        if let arr = second as? [ViewModelWithViewClass?] {
            return arr
        }
        var arr = [ViewModelWithViewClass?]()
        for atr in second {
            if let atr = atr as? ViewModelWithViewClass? {
                arr.append(atr)
            } else if let sectionArr = atr as? [ViewModelWithViewClass?] {
                arr.append(contentsOf: sectionArr)
            }
        }
        return arr
    }

    public static func buildEither(second: [AnyViewModelSection?]) -> [ViewModelWithViewClass?] {
        if let arr = second as? [ViewModelWithViewClass?] {
            return arr
        }
        var arr = [ViewModelWithViewClass?]()
        second.forEach({ atr in
            if let atr = atr as? ViewModelWithViewClass? {
                arr.append(atr)
            } else if let sectionArr = atr as? [ViewModelWithViewClass?] {
                arr.append(contentsOf: sectionArr)
            }
        })
        return arr
    }
}

/**
 Constructs any passed type as array in declarative style eg:
 ~~~
 @ArrayBuilder<Int> var numbers: [Int] {
    1
    2
    3
    4
 } // returns array of Integers [1,2,3,4]
 ~~~
 */
@resultBuilder public struct ArrayBuilder<T> {
    public static func buildBlock(_ atrs: T...) -> [T] {
        atrs
    }
    
    public static func buildBlock(_ atrs: [T]) -> [T] {
        atrs
    }
    
    public static func buildOptional(_ component: [T]?) -> [T] {
        if let component = component {
            return component
        } else {
            return []
        }
    }
    
    public static func buildEither(first component: [T]) -> [T] {
        return component
    }
    
    public static func buildEither(second component: [T]) -> [T] {
        return component
    }
}

