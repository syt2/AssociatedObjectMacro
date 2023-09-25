# Associated Object Macro

--- 

Associated Object Macro wraps `objc_getAssociatedObject` and `objc_setAssociatedObject` methods, allowing convenient declaration of variables in class extensions.


## Installation

### Swift Package Manager
Simply add this repository to your project using SPM to use it.
- File > Swift Packages > Add Package Dependency
- Add `https://github.com/syt2/AssociatedObjectMacro` in SPM
- `import AssociatedObject` in files
- `Trust & Enable` `AssociatedObjectMacro` if need

## Usage
Example usage within your project
``` swift
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
    
    @AssociatedObject(policy: .OBJC_ASSOCIATION_COPY, defaultValue: {
        print("associatedValueD")
    })
    var associatedValueD: (() -> Void)?
}
```

---

After macro expansion, the above code becomes as follows.
```swift
import Foundation
import AssociatedObject

extension NSObject {
    var associatedValueA: String? {
        get {
            objc_getAssociatedObject(self, &Self.__associated_associatedValueA_Key) as? String ?? nil
        }
        set {
            objc_setAssociatedObject(self, &Self.__associated_associatedValueA_Key, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    fileprivate static var __associated_associatedValueA_Key: Void?
    
    var associatedValueB: Date? {
        get {
            objc_getAssociatedObject(self, &Self.__associated_associatedValueB_Key) as? Date ??
            (objc_getAssociatedObject(self, &Self.__associated_associatedValueB_setted_Key) as? Bool ?? false ? nil : Date())
        }
        set {
            objc_setAssociatedObject(self, &Self.__associated_associatedValueB_Key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(self, &Self.__associated_associatedValueB_setted_Key, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    fileprivate static var __associated_associatedValueB_Key: Void?
    fileprivate static var __associated_associatedValueB_setted_Key: Void?
    
    var associatedValueC: Int  {
        get {
            objc_getAssociatedObject(self, &Self.__associated_associatedValueC_Key) as? Int  ?? UserDefaults.standard.integer(forKey: "KeyC")
        }
        set {
            let oldValue = associatedValueC
            let newValueC = newValue
            ({
                print("set value C to \(newValueC)")
            }())
            objc_setAssociatedObject(self, &Self.__associated_associatedValueC_Key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            ({
                guard 0 ..< 10 ~= associatedValueC else {
                    self.associatedValueC = oldValue
                    return
                }
                UserDefaults.standard.setValue(associatedValueC, forKey: "KeyC")
            }())
        }
    }
    fileprivate static var __associated_associatedValueC_Key: Void?
    
    var associatedValueD: (() -> Void)? {
        get {
            objc_getAssociatedObject(self, &Self.__associated_associatedValueD_Key) as? (() -> Void) ??
            (objc_getAssociatedObject(self, &Self.__associated_associatedValueD_setted_Key) as? Bool ?? false ? nil : {
                print("associatedValueD")
            })
        }
        set {
            objc_setAssociatedObject(self, &Self.__associated_associatedValueD_Key, newValue, .OBJC_ASSOCIATION_COPY)
            objc_setAssociatedObject(self, &Self.__associated_associatedValueD_setted_Key, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    fileprivate static var __associated_associatedValueD_Key: Void?
    fileprivate static var __associated_associatedValueD_setted_Key: Void?
}
```

### Tips: 
- A property type must be explicitly specified.
- The default value must be specified in the macro's parameters, and cannot be assigned using `=`. 
- For optional types, If no explicit default value is specified, the default value is `nil`.
- Support for `willSet` and `didSet` methods to observe property changes.
