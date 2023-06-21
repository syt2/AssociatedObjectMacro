import Foundation
import AssociatedObject

class ClassA: NSObject {
    
    var c = false
}

struct StructB {
    let randomValue = Int.random(in: Int.min ... Int.max)
}

extension ClassA {
    @AssociatedObject(policy: .OBJC_ASSOCIATION_COPY_NONATOMIC)
    var associatedValueA: String?
    
    @AssociatedObject(policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC, defaultValue: StructB())
    var associatedValueB: StructB?
    
    @AssociatedObject(policy: .OBJC_ASSOCIATION_ASSIGN, defaultValue: UserDefaults.standard.integer(forKey: "KeyC"))
    var associatedValueC: Int {
        willSet(newValueC) {
            print("set value C to \(newValueC)")
        }
        didSet {
            guard 0..<10 ~= associatedValueC else {
                associatedValueC = oldValue
                return
            }
            UserDefaults.standard.setValue(associatedValueC, forKey: "KeyC")
        }
    }
}

let A = ClassA()
debugPrint(A.associatedValueA, A.associatedValueB, A.associatedValueC)
A.associatedValueA = "@AssociatedObject"
A.associatedValueB = nil
A.associatedValueC = 3
A.associatedValueC = 99
debugPrint(A.associatedValueA, A.associatedValueB, A.associatedValueC)

