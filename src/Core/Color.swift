
public protocol Color: Equatable {
    var r: UInt8 { get }
    var g: UInt8 { get }
    var b: UInt8 { get }
    var a: UInt8 { get }
    
    init(r: UInt8, g: UInt8, b: UInt8, a: UInt8)
    init(luminosity: UInt8, a: UInt8)
}

public extension Color {
    // TODO(?): Does color need these in the first place?
    // TODO(!): These methods are extremely likely to overflow.
    //          I should decide on the correct way to handle this.
    static func + (lhs: Self, rhs: some Color) -> Self {
        .init(r: lhs.r + rhs.r, g: lhs.g + rhs.g, b: lhs.b + rhs.b, a: lhs.a + rhs.a)
    }
    static func - (lhs: Self, rhs: some Color) -> Self {
        .init(r: lhs.r - rhs.r, g: lhs.g - rhs.g, b: lhs.b - rhs.b, a: lhs.a - rhs.a)
    }
    static func + (lhs: Self, rhs: UInt8) -> Self {
        .init(r: lhs.r + rhs, g: lhs.g + rhs, b: lhs.b + rhs, a: lhs.a + rhs)
    }
    static func - (lhs: Self, rhs: UInt8) -> Self {
        .init(r: lhs.r - rhs, g: lhs.g - rhs, b: lhs.b - rhs, a: lhs.a - rhs)
    }
    
    /// This initializer makes all color layouts interchangeable at compile time as long
    /// as they are representable with 8 bit rgba values. It proves that any color is convertible
    /// to any other color.
    ///
    /// The engine uses this to emit draw methods optimized for individual color layouts without
    /// exposing added complexity to the user. Color representation matching the engine internal
    /// type (currently `RGBA` but potentially customizeable in the future) should inline and
    /// optimize away any conversion.
    init(_ other: some Color) {
        self.init(r: other.r, g: other.g, b: other.b, a: other.a)
    }
    
    static func == (lhs: Self, rhs: some Color) -> Bool {
        lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b && lhs.a == rhs.a
    }
}

// TODO(?): How to make palettes generic? I can only think of a way that would abuse function
//          overloading a little, and I would prefer to keep the code as simple as possible.
public struct RGBA: Color {
    public let r, g, b, a: UInt8
    
    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    
    public init(luminosity: UInt8, a: UInt8 = 255) {
        self.r = luminosity
        self.g = luminosity
        self.b = luminosity
        self.a = a
    }
    
    public static let clear = RGBA(r: 0, g: 0, b: 0, a: 0)
    
    public static let black      = Pico.black
    public static let darkBlue   = Pico.darkBlue
    public static let darkPurple = Pico.darkPurple
    public static let darkGreen  = Pico.darkGreen
    public static let brown      = Pico.brown
    public static let darkGray   = Pico.darkGray
    public static let lightGray  = Pico.lightGray
    public static let white      = Pico.white
    public static let red        = Pico.red
    public static let orange     = Pico.orange
    public static let yellow     = Pico.yellow
    public static let green      = Pico.green
    public static let blue       = Pico.blue
    public static let lavender   = Pico.lavender
    public static let pink       = Pico.pink
    public static let peach      = Pico.peach
    
    enum Strawberry {
        public static let red    = RGBA(r: 214, g: 95,  b: 118)
        public static let banana = RGBA(r: 230, g: 192, b: 130)
        public static let apple  = RGBA(r: 205, g: 220, b: 146)
        public static let lime   = RGBA(r: 177, g: 219, b: 159)
        public static let sky    = RGBA(r: 129, g: 171, b: 201)
        public static let lemon  = RGBA(r: 240, g: 202, b: 101)
        public static let orange = RGBA(r: 227, g: 140, b: 113)
        
        public static let white = RGBA(r: 224, g: 224, b: 224)
        public static let light = RGBA(r: 128, g: 128, b: 128)
        public static let gray  = RGBA(r: 59,  g: 59,  b: 59 )
        public static let dark  = RGBA(r: 28,  g: 28,  b: 28 )
        public static let black = RGBA(r: 15,  g: 15,  b: 15 )
    }
    
    enum Pico {
        public static let black      = RGBA(r: 0,   g: 0,   b: 0  )
        public static let darkBlue   = RGBA(r: 29,  g: 43,  b: 83 )
        public static let darkPurple = RGBA(r: 126, g: 37,  b: 83 )
        public static let darkGreen  = RGBA(r: 0,   g: 135, b: 81 )
        public static let brown      = RGBA(r: 171, g: 82,  b: 53 )
        public static let darkGray   = RGBA(r: 95,  g: 87,  b: 79 )
        public static let lightGray  = RGBA(r: 194, g: 195, b: 199)
        public static let white      = RGBA(r: 255, g: 241, b: 232)
        public static let red        = RGBA(r: 255, g: 0,   b: 77 )
        public static let orange     = RGBA(r: 255, g: 163, b: 0  )
        public static let yellow     = RGBA(r: 255, g: 236, b: 39 )
        public static let green      = RGBA(r: 0,   g: 228, b: 54 )
        public static let blue       = RGBA(r: 41,  g: 173, b: 255)
        public static let lavender   = RGBA(r: 131, g: 118, b: 156)
        public static let pink       = RGBA(r: 255, g: 119, b: 168)
        public static let peach      = RGBA(r: 255, g: 204, b: 170)
    }
}

public struct BGRA: Color {
    public let b, g, r, a: UInt8
    
    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
    
    public init(luminosity: UInt8, a: UInt8 = 255) {
        self.r = luminosity
        self.g = luminosity
        self.b = luminosity
        self.a = a
    }
}
