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
    let num = norm.dot(pos - ray.pos)
    let den = norm.dot(ray.dir)
    let dist = num / den
    if !dist.isFinite || dist <= 0 || den > 0 { return nil }
    // zero and tiny denominators result in infinity, indicating a ray parallel to the plane.
    // negative distance indicates the ray is behind the plane.
    // zero distance indicates that the ray originated on the plane, in which case it should not be captured.
    // positive den indicates that the ray hit the back side of the plane, and should pass through.
    // if planes are two sided, then we can experience a double-bounce when the reflected ray pos ends up on the far side.
    let intersectPos = ray.pos + ray.dir * dist
    return Intersection(pos: intersectPos, norm: norm, dist: dist, surface: self)
  }
}

