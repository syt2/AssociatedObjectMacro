//
//  File.swift
//  
//
//  Created by syt on 2023/6/20.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AssociatedObjectPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AssociatedObjectMacro.self
    ]
}
