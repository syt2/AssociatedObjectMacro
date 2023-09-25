import Foundation
import AssociatedObject

extension NSObject {
    // For optional types, the default value is `nil` by default.
    @AssociatedObject(policy: .OBJC_ASSOCIATION_COPY_NONATOMIC)
    var associatedValueA: String?
    
    // Assigning a default value to a variable.
    @AssociatedObject(policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC, defaultValue: Date())
    var associatedValueB: Date?
    
    // Adding willSet and didSet callbacks.
    @AssociatedObject(policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC, defaultValue: 100)
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
    
    @AssociatedObject(policy: .OBJC_ASSOCIATION_COPY, defaultValue: {
        print("associatedValueD")
    })
    var associatedValueD: (() -> Void)?
}

let A = NSObject()
debugPrint(A.associatedValueA as Any, A.associatedValueB as Any, A.associatedValueC)
A.associatedValueD?()
A.associatedValueA = "@AssociatedObject"
A.associatedValueB = nil
A.associatedValueC = 3
A.associatedValueC = 99
A.associatedValueD = {
    print("new associatedValueD")
}
debugPrint(A.associatedValueA as Any, A.associatedValueB as Any, A.associatedValueC)
A.associatedValueD?()

