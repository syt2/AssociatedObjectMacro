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
            return "`@AssociatedObject` macro must be followed by the declaration of a property."
        case .requireTypePolicy:
            return "`@AssociatedObject` macro must specify `objc_AssociationPolicy` explicitly."
        case .requireValueType:
            return "`@AssociatedObject` macro must specify property type explicitly."
        case .requireNonNilDefaultValue:
            return "`@AssociatedObject` macro must specify non-nil default value for non-optional type."
        case .setActionBlocksInvalidate:
            return "`@AssociatedObject` macro receives invalidate didSet/willSet closures."
        case .onlySupportSetActionInClosure:
            return "`@AssociatedObject` macro olny supports willSet/didSet in closures."
        case .defaultValueAssignmentError:
            return "`@AssociatedObject` macro only supports specifying the default value in the macro parameters. Move your default value to @AssociatedObject(policy:defaultValue:)."
        }
    }

    public var severity: DiagnosticSeverity { .error }

    public var diagnosticID: MessageID {
        MessageID(domain: "Swift", id: "AssociatedObject.\(self)")
    }
}
