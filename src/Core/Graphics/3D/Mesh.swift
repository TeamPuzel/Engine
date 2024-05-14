
/// The 3D equivalent of `Drawable`, can be represented by a mesh.
public protocol MeshDrawable<V, T> {
    associatedtype V: Vertex
    associatedtype T: Drawable
    var mesh: Mesh<V, T> { get }
}

/// A collection of vertices and their corresponding shaders and textures.
public struct Mesh<V: Vertex, T: Drawable>: ~Copyable {
    public let vertices: [V]
    public let texture: T
}
