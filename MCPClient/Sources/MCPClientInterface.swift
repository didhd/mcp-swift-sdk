import Foundation
import JSONRPC
import MCPInterface

// MARK: - MCPClientInterface

public protocol MCPClientInterface {
  var serverInfo: ServerInfo { get async }

  /// The tools supported by the server, if tools are supported.
  var tools: ReadOnlyCurrentValueSubject<CapabilityStatus<[Tool]>, Never> { get async }
  /// The prompts supported by the server, if prompts are supported.
  var prompts: ReadOnlyCurrentValueSubject<CapabilityStatus<[Prompt]>, Never> { get async }
  /// The resource provided by the server, if resources are supported.
  var resources: ReadOnlyCurrentValueSubject<CapabilityStatus<[Resource]>, Never> { get async }
  /// The resource templates supported by the server, if resources are supported.
  var resourceTemplates: ReadOnlyCurrentValueSubject<CapabilityStatus<[ResourceTemplate]>, Never> { get async }

  /// Invoke a tool provided by the server.
  /// - Parameters:
  ///  - name: The name of the tool to call.
  ///  - arguments: The arguments to pass to the tool.
  ///  - progressHandler: A closure that will be called with the progress of the tool execution. The first parameter is the current progress, and the second the total progress to reach if known.
  func callTool(
    named name: String,
    arguments: JSON?,
    progressHandler: ((Double, Double?) -> Void)?) async throws -> CallToolResult

  /// Get a prompt provided by the server.
  /// - Parameters:
  /// - name: The name of the prompt to get.
  /// - arguments: Arguments to use for templating the prompt.
  func getPrompt(named name: String, arguments: JSON?) async throws -> GetPromptResult

  /// Read a specific resource URI.
  /// - Parameters:
  /// - uri: The URI of the resource to read.
  func readResource(uri: String) async throws -> ReadResourceResult
}

// MARK: - ClientCapabilityHandlers

/// Describes the supported capabilities of an MCP client, and how to handle each of the supported ones.
///
/// Note: This is similar to `ClientCapabilities`, with the addition of the handler function.
public struct ClientCapabilityHandlers {
  public let roots: CapabilityHandler<ListChangedCapability, ListRootsRequest.Handler>?
  public let sampling: CapabilityHandler<EmptyObject, CreateSamplingMessageRequest.Handler>?
  // TODO: add experimental

  public init(
    roots: CapabilityHandler<ListChangedCapability, ListRootsRequest.Handler>? = nil,
    sampling: CapabilityHandler<EmptyObject, CreateSamplingMessageRequest.Handler>? = nil)
  {
    self.roots = roots
    self.sampling = sampling
  }
}

// MARK: - MCPClientError

public enum MCPClientError: Error {
  case versionMismatch(received: String, expected: String)
  case toolCallError(executionErrors: [CallToolResult.ExecutionError])
}

// MARK: LocalizedError

extension MCPClientError: LocalizedError {

  public var errorDescription: String? {
    switch self {
    case .versionMismatch(let received, let expected):
      "Version mismatch between server and client. Received: \(received), Expected: \(expected)"
    case .toolCallError(let executionErrors):
      "Error executing tool:\n\(executionErrors.map { $0.errorDescription ?? "unknown error" }.joined(separator: "\n\n"))"
    }
  }
}
