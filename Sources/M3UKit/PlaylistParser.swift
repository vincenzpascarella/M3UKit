//
// M3UKit
//
// Copyright (c) 2022 Omar Albeik
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Foundation

/// A class to parse `Playlist` objects from a `PlaylistSource`.
public final class PlaylistParser {

  /// Playlist parser options
  public struct Options: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
      self.rawValue = rawValue
    }

    /// Remove season number and episode number "S--E--" from the name of media.
    public static let removeSeriesInfoFromText = Options(rawValue: 1 << 0)

    /// Extract id from the URL (usually last path component removing the extension)
    public static let extractIdFromURL = Options(rawValue: 1 << 1)

    /// All available options.
    public static let all: Options = [
      .removeSeriesInfoFromText,
      .extractIdFromURL,
    ]
  }

  /// Parser options.
  public let options: Options

  /// Create a new parser.
  /// - Parameter options: Parser options, defaults to .all
  public init(options: Options = []) {
    self.options = options
  }

  /// Parse a playlist.
  /// - Parameter input: source.
  /// - Returns: playlist.
  public func parse(_ input: PlaylistSource) throws -> Playlist {
    let rawString = try extractRawString(from: input)

    var medias: [Playlist.Media] = []

    var lastMetadataLine: String?
    var lastURL: URL?
    var lineNumber = 0

    rawString.enumerateLines { [weak self] line, stop in
      guard let self else {
        stop = true
        return
      }

      if self.isInfoLine(line) {
        lastMetadataLine = line
      } else if !self.isEXT(line), let url = URL(string: line) {
        lastURL = url
      }

      if let metadataLine = lastMetadataLine, let url = lastURL {
        let metadata = self.parseMetadata(line: lineNumber, rawString: metadataLine, url: url)
        let kind = self.parseMediaKind(url, duration: metadata.duration)
        medias.append(.init(metadata: metadata, kind: kind, url: url, lineInM3U: lineNumber))
        lastMetadataLine = nil
        lastURL = nil
        
      }

      lineNumber += 1
    }

    return Playlist(medias: medias)
  }

  /// Walk over a playlist and return its medias one-by-one.
  /// - Parameters:
  ///   - input: source.
  ///   - handler: Handler to be called with the parsed medias.
  public func walk(
    _ input: PlaylistSource,
    handler: @escaping (Playlist.Media) -> Void
  ) throws {
    let rawString = try extractRawString(from: input)

    var lastMetadataLine: String?
    var lastURL: URL?
    var lineNumber = 0

    rawString.enumerateLines { [weak self] line, stop in
      guard let self else {
        stop = true
        return
      }

      if self.isInfoLine(line) {
        lastMetadataLine = line
      } else if !self.isEXT(line), let url = URL(string: line) {
        lastURL = url
      }

      if let metadataLine = lastMetadataLine, let url = lastURL {
        let metadata = self.parseMetadata(line: lineNumber, rawString: metadataLine, url: url)
        let kind = self.parseMediaKind(url, duration: metadata.duration)
        handler(.init(metadata: metadata, kind: kind, url: url, lineInM3U: lineNumber))
        lastMetadataLine = nil
        lastURL = nil
      }
      lineNumber += 1
    }
  }

  /// Parse a playlist on a queue with a completion handler.
  /// - Parameters:
  ///   - input: source.
  ///   - processingQueue: queue to perform parsing on. Defaults to `.global(qos: .background)`
  ///   - callbackQueue: queue to call callback on. Defaults to `.main`
  ///   - completion: completion handler to call with the result.
  public func parse(
    _ input: PlaylistSource,
    processingQueue: DispatchQueue = .global(qos: .background),
    callbackQueue: DispatchQueue = .main,
    completion: @escaping (Result<Playlist, Error>) -> Void
  ) {
    processingQueue.async {
      do {
        let playlist = try self.parse(input)
        callbackQueue.async {
          completion(.success(playlist))
        }
      } catch {
        callbackQueue.async {
          completion(.failure(error))
        }
      }
    }
  }

  @available(iOS 15, tvOS 15, macOS 12, watchOS 8, *)
  /// Parse a playlist.
  /// - Parameter input: source.
  /// - Parameter priority: Processing task priority. Defaults to `.background`
  /// - Returns: playlist.
  public func parse(
    _ input: PlaylistSource,
    priority: TaskPriority = .background
  ) async throws -> Playlist {
    let processingTask = Task(priority: priority) {
      try self.parse(input)
    }
    return try await processingTask.value
  }

  // MARK: - Helpers

  internal func extractRawString(from input: PlaylistSource) throws -> String {
    let filePrefix = "#EXTM3U"
    guard var rawString = input.rawString else {
      throw ParsingError.invalidSource
    }
    if !rawString.starts(with: filePrefix) {
      guard let range = rawString.firstRange(of: filePrefix) else {
        let actualFilePrefix = String(rawString.prefix { !$0.isNewline })
        throw ParsingError.invalidSourcePrefix(actualFilePrefix)
    }
      rawString.removeSubrange(...range.upperBound)
      return rawString
    }
    rawString.removeFirst(filePrefix.count)
    return rawString
  }

  internal enum ParsingError: LocalizedError {
    case invalidSource
    case invalidSourcePrefix(String)
    case missingDuration(Int, String)

    internal var errorDescription: String? {
      switch self {
      case .invalidSource:
        return LocalizableString.invalidSource
      case .invalidSourcePrefix(let prefix):
          return LocalizableString.invalidSourcePrefix + (prefix.isEmpty ? "" : " - \(prefix)")
      case .missingDuration(let line, let raw):
        return LocalizableString.missingDuration + "\(line) \"\(raw)\""
      }
    }
  }

  internal typealias Show = (name: String, se: (s: Int, e: Int)?)

  internal func parseMetadata(line: Int, rawString: String, url: URL) -> Playlist.Media.Metadata {
    let duration = extractDuration(line: line, rawString: rawString) ?? -9999
    let attributes = parseAttributes(rawString: rawString, url: url)
    let name = extractName(rawString)
    return (duration, attributes, name)
  }

  internal func isInfoLine(_ input: String) -> Bool {
    return input.starts(with: "#EXTINF:")
  }
    
  internal func isEXT(_ input: String) -> Bool {
    return input.starts(with: "#EXT")
  }

  internal func extractDuration(line: Int, rawString: String) -> Int? {
    guard let match = durationRegex.firstMatch(in: rawString) else { return nil }
    let duration = Int(match)
    return duration
  }

  internal func extractName(_ input: String) -> String {
    return nameRegex.firstMatch(in: input) ?? ""
  }

  internal func extractId(_ input: URL) -> String {
    String(input.lastPathComponent.split(separator: ".").first ?? "")
  }

    internal func parseMediaKind(_ input: URL, duration: Int = 0) -> Playlist.Media.Kind {
    let string = input.absoluteString
    if mediaKindSeriesRegex.numberOfMatches(source: string) == 1 {
      return .series
    }
    if mediaKindMoviesRegex.numberOfMatches(source: string) == 1 {
      return .movie
    }
    if mediaKindLiveRegex.numberOfMatches(source: string) == 1 || duration == -1 {
      return .live
    }
    return .unknown
  }

  internal func parseAttributes(rawString: String, url: URL) -> Playlist.Media.Attributes {
    var attributes = Playlist.Media.Attributes()
    if let name = attributesNameRegex.firstMatch(in: rawString) {
      let show = parseSeasonEpisode(name)
      attributes.name = show.name
      attributes.seasonNumber = show.se?.s
      attributes.episodeNumber = show.se?.e
    }
    if let groupTitle = attributesGroupTitleRegex.firstMatch(in: rawString) {
      if attributes.seasonNumber != nil {
          attributes.groupTitle = attributes.name
      } else {
          attributes.groupTitle = groupTitle
      }
    }
    return attributes
  }

  internal func parseSeasonEpisode(_ input: String) -> Show {
    let ranges = seasonEpisodeRegex.matchingRanges(in: input)
    guard
      ranges.count == 3,
      let s = Int(input[ranges[1]]),
      let e = Int(input[ranges[2]])
    else {
      return (name: input, se: nil)
    }
    var name = input
    if options.contains(.removeSeriesInfoFromText) {
      name.removeSubrange(ranges[0])
    }
    return (name: name, se: (s, e))
  }

  // MARK: - Regex
  internal let durationRegex: RegularExpression = #"#EXTINF:\s*(\-*\d+)"#
  internal let nameRegex: RegularExpression = #".*,(.+?)$"#

  internal let mediaKindMoviesRegex: RegularExpression = #"\/movie\/"#
  internal let mediaKindSeriesRegex: RegularExpression = #"\/series\/"#
  internal let mediaKindLiveRegex: RegularExpression = #"\/live\/"#

  internal let seasonEpisodeRegex: RegularExpression = #" (?i)s(\d+) ?(?i)e(\d+)"#
  internal let attributesNameRegex: RegularExpression = #"tvg-name=\"(.?|.+?)\""#
  internal let attributesGroupTitleRegex: RegularExpression = #"group-title=\"(.?|.+?)\""#
}
