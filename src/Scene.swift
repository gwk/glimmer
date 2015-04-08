// © 2015 George King.
// All rights reserved.

import Foundation


struct Scene {
  let camera: Camera
  let surfaces: [Surface]
  
  func query(ray: Ray) -> Intersection? {
    var best: Intersection? = nil
    for s in surfaces {
      if let i = s.intersection(ray) {
        if let b = best {
          if b.dist <= i.dist {
            continue
          }
        }
        best = i
      }
    }
    return best
  }
}


