
/// An *unsafe* protocol for vertex types.
///
/// # Safety
/// A vertex must be a trivial type as it will be memory copied onto the GPU.
/// Since memory representation of Swift structs is technically not guaranteed it is inherently
/// unsafe to implement, unless it is for a C struct (declared in a header file).
///
/// I don't want to have to split my code up into multiple languages so I will ignore that,
/// however it is important to note as it may cause issues.
public protocol Vertex {
    
}
