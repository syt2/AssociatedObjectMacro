import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros


public struct AssociatedObjectMacro { }

extension AssociatedObjectMacro: PeerMacro {
    public static func expansion<Context, Declaration>(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: Declaration,
        in context: Context) throws -> [SwiftSyntax.DeclSyntax]
    where Context: SwiftSyntaxMacros.MacroExpansionContext, Declaration: SwiftSyntax.DeclSyntaxProtocol {
        guard let varDeclaration = declaration.as(VariableDeclSyntax.self),
              let binding = varDeclaration.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier else {
            context.diagnose(AssociatedObjectMacroDiagnostic.requireVariableDeclaration.diagnose(at: declaration))
            return []
        }
        
        // associated object key
        // fileprivate static var __associated_{identifier}_Key: Void?
        let keyDeclaration = VariableDeclSyntax(
            modifiers: ModifierListSyntax {
                DeclModifierSyntax(name: .keyword(.fileprivate))
                DeclModifierSyntax(name: .keyword(.static))
            },
            bindingKeyword: .keyword(.var),
            bindings: PatternBindingListSyntax {
                PatternBindingSyntax(
                    pattern: IdentifierPatternSyntax(identifier: associateKeySyntax(of: identifier)),
                    typeAnnotation: .init(type: OptionalTypeSyntax(wrappedType: SimpleTypeIdentifierSyntax(name: "Void")))
                )
            }
        )
        
        var result = [DeclSyntax(keyDeclaration)]
        
        if needSetFlag(binding: binding, node: node) {
            // associated object setted flag key, only for non-optional type which default value != nil
            // fileprivate static var __associated_{identifier}_setted_Key: Void?
            let valueSettedDeclaration = VariableDeclSyntax(
                modifiers: ModifierListSyntax {
                    DeclModifierSyntax(name: .keyword(.fileprivate))
                    DeclModifierSyntax(name: .keyword(.static))
                },
                bindingKeyword: .keyword(.var),
                bindings: PatternBindingListSyntax {
                    PatternBindingSyntax(
                        pattern: IdentifierPatternSyntax(identifier: associateKeySetFlagSyntax(of: identifier)),
                        typeAnnotation: .init(type: OptionalTypeSyntax(wrappedType: SimpleTypeIdentifierSyntax(name: "Void")))
                    )
                }
            )
            result.append(DeclSyntax(valueSettedDeclaration))
        }
        
        return result
    }
}

extension AssociatedObjectMacro: AccessorMacro {
    public static func expansion<Context, Declaration>(
        of node: SwiftSyntax.AttributeSyntax,
        providingAccessorsOf declaration: Declaration,
        in context: Context) throws -> [SwiftSyntax.AccessorDeclSyntax]
    where Context: SwiftSyntaxMacros.MacroExpansionContext, Declaration: SwiftSyntax.DeclSyntaxProtocol {
        guard let varDeclaration = declaration.as(VariableDeclSyntax.self),
              let binding = varDeclaration.bindings.first,
              let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier
        else {
            context.diagnose(AssociatedObjectMacroDiagnostic.requireVariableDeclaration.diagnose(at: declaration))
            return []
        }
        
        // associated object policy type
        guard case let .argumentList(arguments) = node.argument,
              let policy = arguments.first(where: {
                  $0.label?.tokenKind == .identifier("policy")
              })?.expression.as(MemberAccessExprSyntax.self)
        else {
            context.diagnose(AssociatedObjectMacroDiagnostic.requireTypePolicy.diagnose(at: declaration))
            return []
        }
        
        guard binding.initializer == nil else {
            context.diagnose(AssociatedObjectMacroDiagnostic.defaultValueAssignmentError.diagnose(at: declaration))
            return []
        }
        
        // default value
        let defaultValue: ExprSyntaxProtocol = arguments.first(where: {
            $0.label?.tokenKind == .identifier("defaultValue")
        })?.expression ?? NilLiteralExprSyntax()
        
        // value type
        let originalType = binding.typeAnnotation?.type
        let type: TypeSyntax
        if let wrappedType = originalType?.as(OptionalTypeSyntax.self)?.wrappedType {
            type = wrappedType
        } else if let originalType {
            type = originalType
            guard !defaultValue.is(NilLiteralExprSyntax.self) else {            context.diagnose(AssociatedObjectMacroDiagnostic.requireNonNilDefaultValue.diagnose(at: declaration))
                return []
            }
        } else {
            context.diagnose(AssociatedObjectMacroDiagnostic.requireValueType.diagnose(at: declaration))
            return []
        }
        
        // willSet/didSet closure
        var willSetBlock: SetActionBlockComponent? = nil
        var didSetBlock: SetActionBlockComponent? = nil
        
        if let accessor = binding.accessor {
            switch accessor {
            case .accessors(let accessorBlockSyntax):
                for accessor in accessorBlockSyntax.accessors {
                    switch accessor.accessorKind.tokenKind {
                    case .keyword(.didSet):
                        guard didSetBlock == nil,
                              let body = accessor.body,
                              accessor.parameter?.unexpectedBetweenNameAndRightParen == nil else {
                            context.diagnose(AssociatedObjectMacroDiagnostic.setActionBlocksInvalidate.diagnose(at: declaration))
                            return []
                        }
                        didSetBlock = (body, accessor.parameter?.name ?? .identifier("oldValue"))
                    case .keyword(.willSet):
                        guard willSetBlock == nil,
                              let body = accessor.body,
                              accessor.parameter?.unexpectedBetweenNameAndRightParen == nil else {
                            context.diagnose(AssociatedObjectMacroDiagnostic.setActionBlocksInvalidate.diagnose(at: declaration))
                            return []
                        }
                        willSetBlock = (body, accessor.parameter?.name ?? .identifier("newValue"))
                    default:
                        context.diagnose(AssociatedObjectMacroDiagnostic.onlySupportSetActionInClosure.diagnose(at: declaration))
                        return []
                    }
                }
            case .getter(_):
                context.diagnose(AssociatedObjectMacroDiagnostic.onlySupportSetActionInClosure.diagnose(at: declaration))
                return []
            }
        }
        
        return [
            buildGetActionBlockSyntax(identifier: identifier,
                           type: type,
                           defaultValue: defaultValue,
                           settedFlag: needSetFlag(binding: binding, node: node)),
            buildSetActionBlockSyntax(identifier: identifier,
                           policy: policy,
                           willSetBlock: willSetBlock,
                           didSetBlock: didSetBlock,
                           settedFlag: needSetFlag(binding: binding, node: node))
        ]
    }
}


private extension AssociatedObjectMacro {
    static func needSetFlag(binding: PatternBindingListSyntax.Element,
                                    node: SwiftSyntax.AttributeSyntax) -> Bool {
        // If value cannot be nil, add a setted flag
        let valueOptionable = binding.typeAnnotation?.type.is(OptionalTypeSyntax.self) == true
        var defaultValueNotNil = false
        if case let .argumentList(arguments) = node.argument,
           let defaultValue: ExprSyntaxProtocol = arguments.first(where: {
               $0.label?.tokenKind == .identifier("defaultValue")
           })?.expression ?? NilLiteralExprSyntax() {
            defaultValueNotNil = !defaultValue.is(NilLiteralExprSyntax.self)
        }
        // if value optional and default value not nil, then need setted flag
        return valueOptionable && defaultValueNotNil
    }
    
    static func associateKeySetFlagSyntax(of identifier: TokenSyntax) -> TokenSyntax {
        .identifier("__associated_\(identifier.trimmed)_setted_Key")
    }
    
    static func associateKeySyntax(of identifier: TokenSyntax) -> TokenSyntax {
        .identifier("__associated_\(identifier.trimmed)_Key")
    }
    
    static func buildGetActionBlockSyntax(identifier: TokenSyntax,
                                          type: TypeSyntax,
                                          defaultValue: ExprSyntaxProtocol,
                                          settedFlag: Bool) -> AccessorDeclSyntax {
        if settedFlag {
            return AccessorDeclSyntax(stringLiteral:
                """
                get {
                    objc_getAssociatedObject(self, &Self.\(associateKeySyntax(of: identifier))) as? \(type) ??
                    (objc_getAssociatedObject(self, &Self.\(associateKeySetFlagSyntax(of: identifier))) as? Bool ?? false ? nil : \(defaultValue))
                }
                """
            )
        }
        return AccessorDeclSyntax(stringLiteral:
            """
            get {
                objc_getAssociatedObject(self, &Self.\(associateKeySyntax(of: identifier))) as? \(type) ?? \(defaultValue)
            }
            """
        )
    }
    
    // TODO: format output
    typealias SetActionBlockComponent = (body: CodeBlockSyntax, param: TokenSyntax)
    static func buildSetActionBlockSyntax(identifier: TokenSyntax,
                                          policy: MemberAccessExprSyntax,
                                          willSetBlock: SetActionBlockComponent?,
                                          didSetBlock: SetActionBlockComponent?,
                                          settedFlag: Bool) -> AccessorDeclSyntax {
        var insideSetBlock =
        """
        objc_setAssociatedObject(self, &Self.\(associateKeySyntax(of: identifier)), newValue, \(policy))
        """
        if settedFlag {
            insideSetBlock.append(contentsOf:
                """
                objc_setAssociatedObject(self, &Self.\(associateKeySetFlagSyntax(of: identifier)), true, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                """
            )
        }
        if let willSetBlock {
            let willSetCallback =
            """
            let \(willSetBlock.param) = newValue
            (\(willSetBlock.body)())
            
            """
            insideSetBlock.insert(contentsOf: willSetCallback, at: insideSetBlock.startIndex)
        }
        if let didSetBlock {
            let oldValueAssignment =
            """
            let \(didSetBlock.param) = \(identifier)
            
            """
            
            insideSetBlock.insert(contentsOf: oldValueAssignment, at: insideSetBlock.startIndex)
            
            let didSetCallback =
            """
            
            (\(didSetBlock.body.trimmed)())
            """
            insideSetBlock.append(contentsOf: didSetCallback)
        }
        return AccessorDeclSyntax(stringLiteral:
        """
        set {
            \(insideSetBlock)
        }
        """
        )
    }
}
