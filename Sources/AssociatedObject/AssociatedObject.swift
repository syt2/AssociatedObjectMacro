import ObjectiveC

@attached(peer, names: arbitrary)
@attached(accessor)
public macro AssociatedObject(policy: objc_AssociationPolicy, defaultValue: Any? = nil) = #externalMacro(module: "AssociatedObjectMacros", type: "AssociatedObjectMacro")
