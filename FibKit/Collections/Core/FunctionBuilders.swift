//
//  FunctionBuilders.swift
//  SmartStaff
//
//  Created by artem on 29.05.2020.
//  Copyright © 2020 DIT. All rights reserved.
//


import UIKit

public protocol AnyGridSection {}
extension GridSection: AnyGridSection {}
extension Array: AnyGridSection where Element == GridSection {}

/// Constructs sections in declarative style
/// eg:
///~~~
///@SectionBuilder var sections: [FormSection] {
///    FormSection.single {
///        FormViewSpacer(16)
///    }
///    FormSection {
///        FormViewSpacer(16)
///        SimpleLabelView.ViewModel(text: "SomeText")
///        FormViewSpacer(85)
///    }
///}
///~~~
@_functionBuilder public struct SectionBuilder {
    public static func buildBlock(_ atrs: AnyGridSection...) -> [GridSection] {
        if let arr = atrs as? [GridSection] {
            return arr
        }
        var arr = [GridSection]()
        for atr in atrs {
            if let atr = atr as? GridSection {
                arr.append(atr)
            } else if let sectionArr = atr as? [GridSection], !sectionArr.isEmpty {
                if sectionArr.allSatisfy({ $0.isGuard }) {
                    arr = sectionArr
                    break
                } else if sectionArr.allSatisfy({ $0.isGuardAppend }) {
                    arr.append(contentsOf: sectionArr)
                    break
                }
                arr.append(contentsOf: sectionArr)
            }
        }
        return arr
    }

    public static func buildBlock(_ atrs: [AnyGridSection]) -> [GridSection] {
        if let arr = atrs as? [GridSection] {
            return arr
        }
        var arr = [GridSection]()
        for atr in atrs {
            if let atr = atr as? GridSection {
                arr.append(atr)
            } else if let sectionArr = atr as? [GridSection], !sectionArr.isEmpty {
                if sectionArr.allSatisfy({ $0.isGuard }) {
                    arr = sectionArr
                    break
                } else if sectionArr.allSatisfy({ $0.isGuardAppend }) {
                    arr.append(contentsOf: sectionArr)
                    break
                }
                arr.append(contentsOf: sectionArr)
            }
        }
        return arr
    }
    
    public static func buildIf(_ atrs: AnyGridSection?...) -> [GridSection] {
        if let arr = atrs as? [GridSection] {
            return arr
        }
        var arr = [GridSection]()
        for atr in atrs {
            if let atr = atr as? GridSection {
                arr.append(atr)
            } else if let sectionArr = atr as? [GridSection], !sectionArr.isEmpty {
                if sectionArr.allSatisfy({ $0.isGuard }) {
                    arr = sectionArr
                    break
                } else if sectionArr.allSatisfy({ $0.isGuardAppend }) {
                    arr.append(contentsOf: sectionArr)
                    break
                }
                arr.append(contentsOf: sectionArr)
            }
        }
        return arr
    }
    
    public static func buildIf(_ atrs: [AnyGridSection]?) -> [GridSection] {
        if let arr = atrs as? [GridSection] {
            return arr
        }
        var arr = [GridSection]()
        for atr in atrs ?? [] {
            if let atr = atr as? GridSection {
                arr.append(atr)
            } else if let sectionArr = atr as? [GridSection], !sectionArr.isEmpty {
                if sectionArr.allSatisfy({ $0.isGuard }) {
                    arr = sectionArr
                    break
                } else if sectionArr.allSatisfy({ $0.isGuardAppend }) {
                    arr.append(contentsOf: sectionArr)
                    break
                }
                arr.append(contentsOf: sectionArr)
            }
        }
        return arr
    }
    
    public static func buildEither(first: AnyGridSection...) -> [GridSection] {
        if let arr = first as? [GridSection] {
            return arr
        }
        var arr = [GridSection]()
        for atr in first {
            if let atr = atr as? GridSection {
                arr.append(atr)
            } else if let sectionArr = atr as? [GridSection], !sectionArr.isEmpty {
                if sectionArr.allSatisfy({ $0.isGuard }) {
                    arr = sectionArr
                    break
                } else if sectionArr.allSatisfy({ $0.isGuardAppend }) {
                    arr.append(contentsOf: sectionArr)
                    break
                }
                arr.append(contentsOf: sectionArr)
            }
        }
        return arr
    }
    
    public static func buildEither(first: [AnyGridSection]) -> [GridSection] {
        if let arr = first as? [GridSection] {
            return arr
        }
        var arr = [GridSection]()
        for atr in first {
            if let atr = atr as? GridSection {
                arr.append(atr)
            } else if let sectionArr = atr as? [GridSection], !sectionArr.isEmpty {
                if sectionArr.allSatisfy({ $0.isGuard }) {
                    arr = sectionArr
                    break
                } else if sectionArr.allSatisfy({ $0.isGuardAppend }) {
                    arr.append(contentsOf: sectionArr)
                    break
                }
                arr.append(contentsOf: sectionArr)
            }
        }
        return arr
    }
    
    public static func buildEither(second: AnyGridSection...) -> [GridSection] {
        if let arr = second as? [GridSection] {
            return arr
        }
        var arr = [GridSection]()
        for atr in second {
            if let atr = atr as? GridSection {
                arr.append(atr)
            } else if let sectionArr = atr as? [GridSection], !sectionArr.isEmpty {
                if sectionArr.allSatisfy({ $0.isGuard }) {
                    arr = sectionArr
                    break
                } else if sectionArr.allSatisfy({ $0.isGuardAppend }) {
                    arr.append(contentsOf: sectionArr)
                    break
                }
                arr.append(contentsOf: sectionArr)
            }
        }
        return arr
    }
    
    public static func buildEither(second: [AnyGridSection]) -> [GridSection] {
        if let arr = second as? [GridSection] {
            return arr
        }
        var arr = [GridSection]()
        for atr in second {
            if let atr = atr as? GridSection {
                arr.append(atr)
            } else if let sectionArr = atr as? [GridSection], !sectionArr.isEmpty {
                if sectionArr.allSatisfy({ $0.isGuard }) {
                    arr = sectionArr
                    break
                } else if sectionArr.allSatisfy({ $0.isGuardAppend }) {
                    arr.append(contentsOf: sectionArr)
                    break
                }
                arr.append(contentsOf: sectionArr)
            }
        }
        return arr
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
@_functionBuilder public struct ViewModelBuilder {

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
@_functionBuilder public struct ArrayBuilder<T> {
    public static func buildBlock(_ atrs: T...) -> [T] {
        atrs
    }
}


