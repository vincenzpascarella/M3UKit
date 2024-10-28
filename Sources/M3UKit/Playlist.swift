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

/// Object representing a playlist containing media items.
public struct Playlist: Equatable, Hashable, Codable {

  /// Object representing a media.
  public struct Media: Equatable, Hashable, Codable {

    /// Object representing attributes for a media.
    public struct Attributes: Equatable, Hashable, Codable {
      /// Create a new attributes object.
      /// - Parameters:
      ///   - id: id.
      ///   - name: name.
      ///   - groupTitle: group title.
      ///   - seasonNumber: Season number (for TV shows).
      ///   - episodeNumber: Episode number (for TV shows).
      public init(
        name: String? = nil,
        groupTitle: String? = nil,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil
      ) {
        self.name = name
        self.groupTitle = groupTitle
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
      }
        
      /// tvg-name.
      public var name: String?
      
      /// group-title.
      public var groupTitle: String?

      /// Season number (for TV shows).
      public var seasonNumber: Int?

      /// Episode number (for TV shows).
      public var episodeNumber: Int?
    }

    /// Enum representing media kind.
    public enum Kind: String, Equatable, Hashable, Codable {
      case movie
      case series
      case live
      case unknown
    }

    internal typealias Metadata = (
      duration: Int,
      attributes: Attributes,
      name: String
    )

    internal init(
      metadata: Metadata,
      kind: Kind,
      url: URL,
      lineInM3U: Int
    ) {
      self.init(
        attributes: metadata.attributes,
        kind: kind,
        name: metadata.name,
        url: url,
        lineInM3U: lineInM3U
      )
    }

    /// Create a new media object.
    /// - Parameters:
    ///   - duration: duration.
    ///   - attributes: attributes.
    ///   - kind: kind.
    ///   - name: name.
    ///   - url: url.
    public init(
      attributes: Attributes,
      kind: Kind,
      name: String,
      url: URL,
      lineInM3U: Int? = nil
    ) {
      self.attributes = attributes
      self.kind = kind
      self.name = name
      self.url = url
      self.lineInM3U = lineInM3U
    }

    /// Attributes.
    public var attributes: Attributes

    /// Kind.
    public var kind: Kind

    /// Media name.
    public var name: String

    /// Media URL.
    public var url: URL
    
    /// Used to discriminate equals streams
    public var lineInM3U: Int?
  }

  /// Create a playlist.
  /// - Parameter medias: medias.
  public init(medias: [Media]) {
    self.medias = medias
  }

  /// Medias.
  public var medias: [Media]
}
