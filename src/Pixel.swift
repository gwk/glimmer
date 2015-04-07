// © 2015 George King.
// All rights reserved.

import Foundation


struct Pixel {
  let col: V3D
  let count: Double
  
  init() {
    col = V3D()
    count = 0
  }
  
  init(sample: V3D) {
    col = sample
    count = 1
  }
  
  init(prev: Pixel, col: V3D) {
    let n = prev.count
    let n1 = n + 1
    self.col = (prev.col * n + col) / n1
    self.count = n1
  }
  
  var colU8: (U8, U8, U8) { // TODO: use V3U8.
    let c = col.clampToUnit
    return (U8(c.x * 255), U8(c.y * 255), U8(c.z * 255))
  }
}
