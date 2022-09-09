import Foundation
import PackagePlugin

@main
struct SwiftFormatPlugin: CommandPlugin {
    func performCommand(context: PackagePlugin.PluginContext, arguments: [String]) async throws {
        let swiftFormatTool = try context.tool(named: "swift-format")
        let swiftFormatPath = URL(fileURLWithPath: swiftFormatTool.path.string)

        for target in context.package.targets(ofType: SwiftSourceModuleTarget.self) {
            let swiftFormatArgs = [
                "format",
                "--in-place",
                "--ignore-unparsable-files",
                "--parallel",
                "--recursive",
                target.directory.string
            ]

            let task = try Process.run(swiftFormatPath, arguments: swiftFormatArgs)
            task.waitUntilExit()

            if task.terminationStatus == 0 {
                print("Formatted the source code in \(target.directory)")
            } else {
                Diagnostics.error("swift-format invocation failed: exitStatus=\(task.terminationStatus)")
            }
        }
    }
}
