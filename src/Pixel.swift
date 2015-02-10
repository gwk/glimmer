// © 2015 George King.
// All rights reserved.

import Foundation


struct Pixel {
  let accum: V3D
  let count: Double
  
  init() {
    accum = V3D()
    count = 0
  }
  
  init(sample: V3D) {
    accum = sample
    count = 1
  }
  
  init(prev: Pixel, col: V3D) {
    accum = prev.accum + col
    count = prev.count + 1
  }
  
  var col: V3D { return count < 1 ? V3D() : (accum / count).clampToUnit }
  
  var colU8: (U8, U8, U8) { // TODO: use V3U8.
    let c = col
    return (U8(c.x * 255), U8(c.y * 255), U8(c.z * 255))
  }
}
