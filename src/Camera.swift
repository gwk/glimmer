// © 2015 George King.
// All rights reserved.

import Foundation

struct Camera {
  let pos: V3D
  let dir: V3D
  let vert: F64

  func hori(ar: F64) -> F64 { return vert * ar }
  
  
}

