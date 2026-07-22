import CoreGraphics
import SwiftUI
import XCTest

@testable import Views

@MainActor
final class MyViewLayoutTests: XCTestCase {
  func testWrappedLinkTitleAlignsLinesToLeadingEdge() throws {
    let renderer = ImageRenderer(
      content: MyLinkTitle(title: "MMMMMMMM\nII")
        .font(.system(size: 32))
        .foregroundStyle(.black)
        .multilineTextAlignment(.center)
        .frame(width: 240, height: 100)
    )
    renderer.scale = 1

    let image = try XCTUnwrap(renderer.cgImage)
    let lineLeadingEdges = try lineLeadingEdges(in: image)

    XCTAssertGreaterThanOrEqual(lineLeadingEdges.count, 2)
    XCTAssertLessThanOrEqual(abs(lineLeadingEdges[0] - lineLeadingEdges[1]), 1)
  }

  private func lineLeadingEdges(in image: CGImage) throws -> [Int] {
    let width = image.width
    let height = image.height
    var pixels = [UInt8](repeating: 255, count: width * height)
    let context = try XCTUnwrap(
      CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width,
        space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGImageAlphaInfo.none.rawValue
      )
    )
    context.setFillColor(gray: 1, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

    let darkRows = (0..<height).compactMap { y -> (y: Int, minX: Int)? in
      let minX = (0..<width).first { x in
        pixels[y * width + x] < 200
      }
      return minX.map { (y, $0) }
    }

    var lineLeadingEdges: [Int] = []
    var previousY: Int?
    for row in darkRows {
      if let previousY, row.y == previousY + 1 {
        lineLeadingEdges[lineLeadingEdges.count - 1] = min(
          lineLeadingEdges[lineLeadingEdges.count - 1],
          row.minX
        )
      } else {
        lineLeadingEdges.append(row.minX)
      }
      previousY = row.y
    }
    return lineLeadingEdges
  }
}
