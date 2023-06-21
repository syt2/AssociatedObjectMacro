//
//  File.swift
//  
//
//  Created by syt on 2023/6/20.
//

import SwiftSyntax
import SwiftDiagnostics

public enum AssociatedObjectMacroDiagnostic {
    case requireVariableDeclaration
    case requireTypePolicy
    case requireValueType
    case requireNonNilDefaultValue
    case setActionBlocksInvalidate
    case onlySupportSetActionInClosure
    case defaultValueAssignmentError
}

extension AssociatedObjectMacroDiagnostic: DiagnosticMessage {
    func diagnose(at node: some SyntaxProtocol) -> Diagnostic {
        Diagnostic(node: Syntax(node), message: self)
    }

    public var message: String {
        switch self {
        case .requireVariableDeclaration:
            return "`@AssociatedObject` macro must be appended to the property declaration."
        case .requireTypePolicy:
            return "`@AssociatedObject` macro must specify `objc_AssociationPolicy` explicitly."
        case .requireValueType:
            return "`@AssociatedObject` macro must specify value type explicitly."
        case .requireNonNilDefaultValue:
            return "`@AssociatedObject` macro must specify non-nil default value for non-nil value type."
        case .setActionBlocksInvalidate:
            return "`@AssociatedObject` macro receive invalidate didSet/willSet closures."
        case .onlySupportSetActionInClosure:
            return "`@AssociatedObject` macro olny support willSet/didSet in closures."
        case .defaultValueAssignmentError:
            return "`@AssociatedObject` macro must provide default value in params. Move your default value to @AssociatedObject(policy:defaultValue:)."
        }
    }

    public var severity: DiagnosticSeverity { .error }

    public var diagnosticID: MessageID {
        MessageID(domain: "Swift", id: "AssociatedObject.\(self)")
    }
}
