import ObjectiveC

@attached(peer, names: arbitrary)
@attached(accessor)
public macro AssociatedObject(policy: objc_AssociationPolicy, defaultValue: Any?) = #externalMacro(module: "AssociatedObjectMacros", type: "AssociatedObjectMacro")

@attached(peer, names: arbitrary)
@attached(accessor)
public macro AssociatedObject(policy: objc_AssociationPolicy) = #externalMacro(module: "AssociatedObjectMacros", type: "AssociatedObjectMacro")
