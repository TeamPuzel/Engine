#!swift

import Darwin

let bundlePath = "./bundle"
let include = "#include \"bundle.h\"\n"

let dir = opendir(bundlePath)!
defer { closedir(dir) }

var fileNames: [String] = []
while let object = readdir(dir) {
    guard object.pointee.d_type == DT_REG else { continue }
    withUnsafePointer(to: object.pointee.d_name) { ptr in
        ptr.withMemoryRebound(to: CChar.self, capacity: 1) { str in
            fileNames.append(String(cString: str))
        }
    }
}

fileNames.forEach { print("Detected \($0)") }

let files = fileNames.map { fopen("\(bundlePath)/\($0)", "r")! }
defer { files.forEach { fclose($0) } }

let data = files.map {
    func next(_ file: UnsafeMutablePointer<FILE>) -> UInt8? {
        let byte = fgetc(file)
        return byte == EOF ? nil : UInt8(byte)
    }
    
    var buf: [UInt8] = []
    while let byte = next($0) {
        buf.append(byte)
    }
    return buf
}

let names = fileNames.map { $0.uppercased().replacing(".", with: "_") }
let namedData = zip(names, data)

print("Generating code...")

func codegen(_ name: String, _ data: [UInt8]) -> (header: String, source: String) {
    let header = "const unsigned char *\(name);\n"
    
    var source = ""
    source.append("unsigned char \(name)_DATA[] = {\n")
    source.append("    ")
    for byte in data {
        source.append(byte.description + ",")
    }
    source.append("\n};\n")
    source.append("const unsigned char *\(name) = \(name)_DATA;\n")
    
    return (header, source)
}

let code = namedData
    .map { (name, data) in codegen(name, data) }
    .reduce(into: (header: String(), source: include)) { acc, el in
        acc.header.append(contentsOf: el.header)
        acc.source.append(contentsOf: el.source)
    }

print("Writing files...")

let header = fopen("./module/include/bundle.h", "w")!
defer { fflush(header); fclose(header) }
fwrite(code.header, MemoryLayout<CChar>.stride, code.header.count, header)

let source = fopen("./module/bundle.c", "w")!
defer { fflush(source); fclose(source) }
fwrite(code.source, MemoryLayout<CChar>.stride, code.source.count, source)
