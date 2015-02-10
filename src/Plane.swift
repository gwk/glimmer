// © 2015 George King.
// All rights reserved.

import Foundation


class Plane: Surface {
  let pos: V3D
  let norm: V3D
  let material: Material
  
  init(pos: V3D, norm: V3D, material: Material) {
    self.pos = pos
    self.norm = norm
    self.material = material
  }
  
  func intersection(ray: Ray) -> Intersection? {
    let num = dot(pos - ray.pos, norm)
    let den = dot(ray.dir, norm)
    if den <= 0 { return nil }
    let dist = num / den
    return Intersection(pos: ray.pos + ray.dir * (dist), norm: norm, dist: dist, surface: self)
  }
}



