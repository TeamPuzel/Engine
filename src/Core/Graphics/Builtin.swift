
import Assets

/// A namespace for built in tile fonts.
public struct TileFonts {
    public static var pico: TileFont<UnsafeTGAPointer> {
        .init(
            source: UnsafeTGAPointer(PICOFONT_TGA),
            charWidth: 3, charHeight: 5, map: { char in switch char {
                case "0": (0, 0)
                case "1": (1, 0)
                case "2": (2, 0)
                case "3": (3, 0)
                case "4": (4, 0)
                case "5": (5, 0)
                case "6": (6, 0)
                case "7": (7, 0)
                case "8": (8, 0)
                case "9": (9, 0)
                    
                case "A", "a": (10, 0)
                case "B", "b": (11, 0)
                case "C", "c": (12, 0)
                case "D", "d": (13, 0)
                case "E", "e": (14, 0)
                case "F", "f": (15, 0)
                case "G", "g": (16, 0)
                case "H", "h": (17, 0)
                case "I", "i": (18, 0)
                case "J", "j": (19, 0)
                case "K", "k": (20, 0)
                case "L", "l": (21, 0)
                case "M", "m": (22, 0)
                case "N", "n": (23, 0)
                case "O", "o": (24, 0)
                case "P", "p": (25, 0)
                case "Q", "q": (26, 0)
                case "R", "r": (27, 0)
                case "S", "s": (28, 0)
                case "T", "t": (29, 0)
                case "U", "u": (30, 0)
                case "V", "v": (31, 0)
                case "W", "w": (32, 0)
                case "X", "x": (33, 0)
                case "Y", "y": (34, 0)
                case "Z", "z": (35, 0)
                    
                case ".": (36, 0)
                case ",": (37, 0)
                case "!": (38, 0)
                case "?": (39, 0)
                case "\"": (40, 0)
                case "'": (41, 0)
                case "`": (42, 0)
                case "@": (43, 0)
                case "#": (44, 0)
                case "$": (45, 0)
                case "%": (46, 0)
                case "&": (47, 0)
                case "(": (48, 0)
                case ")": (49, 0)
                case "[": (50, 0)
                case "]": (51, 0)
                case "{": (52, 0)
                case "}": (53, 0)
                case "|": (54, 0)
                case "/": (55, 0)
                case "\\": (56, 0)
                case "+": (57, 0)
                case "-": (58, 0)
                case "*": (59, 0)
                case ":": (60, 0)
                case ";": (61, 0)
                case "=": (62, 0)
                case "<": (63, 0)
                case ">": (64, 0)
                case "_": (65, 0)
                case "~": (66, 0)
                    
                case _: nil
            } }
        )
    }
}
