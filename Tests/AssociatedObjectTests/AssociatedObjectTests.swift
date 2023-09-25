import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosTestSupport
import XCTest
import AssociatedObjectMacros
import AssociatedObject



let testMacros: [String: Macro.Type] = [
    "AssociatedObject": AssociatedObjectMacro.self,
]

class TestClass: NSObject {
    
}

extension TestClass {
    @AssociatedObject(policy: .OBJC_ASSOCIATION_COPY_NONATOMIC)
    var string: String?
    
    @AssociatedObject(policy: .OBJC_ASSOCIATION_COPY_NONATOMIC, defaultValue: "anotherString")
    var anotherString: String?
    
    @AssociatedObject(policy: .OBJC_ASSOCIATION_COPY_NONATOMIC, defaultValue: "notNilString")
    var notNilString: String
    
    @AssociatedObject(policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC, defaultValue: 10)
    var int: Int {
        didSet {
            print("int set from \(oldValue) to \(int)")
        }
    }
    
    @AssociatedObject(policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC, defaultValue: 95)
    var point: Int? {
        willSet {
            print("point will set from \(String(describing: point)) to \(String(describing: newValue))")
        }
        didSet {
            guard let newPoint = point else { return }
            if 0...100 ~= newPoint {
                print("point set to \(newPoint)")
            } else {
                self.point = nil
                print("point \(String(describing: oldValue)) exceed limit, set to nil")
            }
        }
    }
}



import SwiftBasicFormat
import SwiftDiagnostics
import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacros
import _SwiftSyntaxTestSupport

final class AssociatedObjectTests: XCTestCase {
    func testMacro() {
        let testClass = TestClass()
        assert(testClass.string == nil)
        assert(testClass.anotherString == "anotherString")
        assert(testClass.notNilString == "notNilString")
        assert(testClass.int == 10)
        assert(testClass.point == 95)
        
        testClass.string = "string"
        assert(testClass.string == "string")
        
        testClass.anotherString = nil
        assert(testClass.anotherString == nil)
        
        testClass.notNilString = "notNilString2"
        assert(testClass.notNilString == "notNilString2")
        
        testClass.int = Int.min
        assert(testClass.int == Int.min)
        
        testClass.point = 88
        assert(testClass.point == 88)
        
        testClass.point = Int.min
        assert(testClass.point == nil)
        
        testClass.point = 90
        assert(testClass.point == 90)
        
        testClass.point = nil
        assert(testClass.point == nil)
    }
    
//    func testMacroExpansion() {
//        // due to format diff
////        assertMacroExpansion("", expandedSource: "", macros: testMacros)
//        
//        let originSources = [
//            #"""
//            @AssociatedObject(policy: .OBJC_ASSOCIATION_COPY_NONATOMIC)
//            var associatedValueA: String?ååå
//            """#,
//            #"""
//            @AssociatedObject(policy: .OBJC_ASSOCIATION_COPY_NONATOMIC, defaultValue: "anotherString")
//            var anotherString: String?
//            """#,
//            #"""
//            @AssociatedObject(policy: .OBJC_ASSOCIATION_RETAIN_NONATOMIC, defaultValue: 95)
//            var point: Int? {
//                willSet {
//                    print("point will set from \(point) to \(newValue)")
//                }
//                didSet {
//                    guard let newPoint = point else { return }
//                    if 0...100 ~= newPoint {
//                        print("point set to \(newPoint)")
//                    } else {
//                        point = nil
//                        print("point exceed limit, set to nil")
//                    }
//                }
//            }
//            """#,
//        ]
//        
//        let expectOutputs = [
//            #"""
//            var associatedValueA: String? {
//                get {
//                    objc_getAssociatedObject(self, &Self.__associated_associatedValueA_Key) as? String ?? nil
//                }
//                set {
//                    objc_setAssociatedObject(self, &Self.__associated_associatedValueA_Key, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
//                }
//            }
//            fileprivate static var __associated_associatedValueA_Key: Void?
//            """#,
//            #"""
//            var anotherString: String? {
//                get {
//                    objc_getAssociatedObject(self, &Self.__associated_anotherString_Key) as? String ??
//                    (objc_getAssociatedObject(self, &Self.__associated_anotherString_setted_Key) as? Bool ?? false ? nil : "anotherString")
//                }
//                set {
//                    objc_setAssociatedObject(self, &Self.__associated_anotherString_Key, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
//                    objc_setAssociatedObject(self, &Self.__associated_anotherString_setted_Key, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//                }
//            }
//            fileprivate static var __associated_anotherString_Key: Void?
//            fileprivate static var __associated_anotherString_setted_Key: Void?
//            """#,
//            #"""
//            var point: Int? {
//                get {
//                    objc_getAssociatedObject(self, &Self.__associated_point_Key) as? Int ??
//                    (objc_getAssociatedObject(self, &Self.__associated_point_setted_Key) as? Bool ?? false ? nil : 95)
//                }
//                set {
//                    let oldValue = point
//                    let newValue = newValue
//                    ({
//                        print("point will set from \(point) to \(newValue)")
//                    }())
//                    objc_setAssociatedObject(self, &Self.__associated_point_Key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//                    objc_setAssociatedObject(self, &Self.__associated_point_setted_Key, true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
//                    ({
//                        guard let newPoint = point else { return }
//                        if 0 ... 100 ~= newPoint {
//                            print("point set to \(newPoint)")
//                        } else {
//                            point = nil
//                            print("point exceed limit, set to nil")
//                        }
//                    }())
//                }
//            }
//            fileprivate static var __associated_point_Key: Void?
//            fileprivate static var __associated_point_setted_Key: Void?
//            """#,
//        ]
//        
//        for (originSource, expectOutput) in zip(originSources, expectOutputs) {
//            let origSourceFile = Parser.parse(source: originSource)
//
//            // Expand all macros in the source.
//            let context = BasicMacroExpansionContext(
//                sourceFiles: [origSourceFile: .init(moduleName: "AssociatedObject", fullFilePath: #filePath)]
//            )
//            let expandedSourceFile = origSourceFile.expand(macros: testMacros, in: context).formatted()
//            
//            print(expandedSourceFile)
////            assertStringsEqualWithDiff(
////                expandedSourceFile.description.trimmingTrailingWhitespace(),
////                expectOutput
////            )
//            
//        }
//    }
}

extension AssociatedObjectTests {
    func trimedString(_ string: String) -> String {
        string.split(separator: "\n").compactMap {
            $0.replacingOccurrences(of: " ", with: "")
        }.joined(separator: "")
    }
}


