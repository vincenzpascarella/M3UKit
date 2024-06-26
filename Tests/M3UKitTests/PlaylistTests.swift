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

import XCTest
@testable import M3UKit

final class PlaylistTests: XCTestCase {
  func testInit() {
    let name = "name"
    let groupTitle = "groupTitle"

    let attributes = Playlist.Media.Attributes(
      groupTitle: groupTitle
    )

    let duration = 0
    let kind = Playlist.Media.Kind.live
    let url = URL(string: "https://not.a/real/url")!

    let media = Playlist.Media(
      duration: duration,
      attributes: attributes,
      kind: kind,
      name: name,
      url: url
    )

    XCTAssertEqual(media.duration, duration)
    XCTAssertEqual(media.attributes, attributes)
    XCTAssertEqual(media.name, name)
    XCTAssertEqual(media.kind, kind)
    XCTAssertEqual(media.url, url)
    XCTAssertEqual(media.attributes.groupTitle, groupTitle)

    XCTAssertEqual(Playlist(medias: [media]).medias, [media])
  }
}
