import Foundation
import MemoryWallAgentTools

let registry = ToolRegistry(context: .live(workspace: nil))
let result = registry.run(arguments: Array(CommandLine.arguments.dropFirst()))
if let output = try? result.jsonString() {
    print(output)
} else {
    print("{\"ok\":false,\"message\":\"failed to encode result\",\"data\":{}}")
}
exit(result.ok ? 0 : 1)
