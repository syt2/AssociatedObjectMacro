import Foundation
import AssociatedObject

struct StructB {
    let randomValue = Int.random(in: Int.min ... Int.max)
}

extension NSObject {
    // For optional types, the default value is `nil` by default.
    @AssociatedObject(policy: .OBJC_ASSOCIATION_COPY_NONATOMIC)
    var associatedValueA: String?
    
    // Assigning a default value to a variable.
    @AssociatedObject(policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC, defaultValue: Date())
    var associatedValueB: Date?
    
    // Adding willSet and didSet callbacks.
    @AssociatedObject(policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC, defaultValue: UserDefaults.standard.integer(forKey: "KeyC"))
    var associatedValueC: Int {
        willSet(newValueC) {
            print("set value C to \(newValueC)")
        }
        didSet {
            guard 0..<10 ~= associatedValueC else {
                self.associatedValueC = oldValue
                return
            }
            UserDefaults.standard.setValue(associatedValueC, forKey: "KeyC")
        }
    }
    
    @AssociatedObject(policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC, defaultValue: {
        Date().timeIntervalSince1970
    }())
    var associatedValueD: Double?
}

let A = NSObject()
debugPrint(A.associatedValueA as Any, A.associatedValueB as Any, A.associatedValueC, A.associatedValueD as Any)
A.associatedValueA = "@AssociatedObject"
A.associatedValueB = nil
A.associatedValueC = 3
A.associatedValueC = 99
A.associatedValueD = Date().timeIntervalSince1970
debugPrint(A.associatedValueA as Any, A.associatedValueB as Any, A.associatedValueC, A.associatedValueD as Any)

