// © 2015 George King.
// All rights reserved.

import Foundation

struct Camera {
  let pos: V3D
  let dir: V3D
  let vert: F64
  
  init(pos: V3D, dir: V3D, vert: F64) {
    self.pos = pos
    self.dir = dir.norm
    self.vert = vert
  }
  
  func hori(ar: F64) -> F64 { return vert * ar }
}

