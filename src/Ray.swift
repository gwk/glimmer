// © 2015 George King.
// All rights reserved.

import Foundation


struct Ray: CustomStringConvertible {
  let pos: V3D
  let dir: V3D // normalized direction.
  
  var description: String { return "Ray(pos:\(pos) dir:\(dir))" }
}

