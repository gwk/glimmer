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
    if !isfinite(dist) || dist <= 0 { return nil }
    // zero and tiny denominators result in infinity, indicating a ray parallel to the plane.
    // negative distance indicates the ray is behind the plane.
    // zero distance indicates that the ray originated on the plane,
    // in which case it should not be captured.
    let intersectPos = ray.pos + ray.dir * dist
    let normSign = -sign(den) // plane is two-sided, so if ray and plane norm are pointing the same way, flip plane norm.
    return Intersection(pos: intersectPos, norm: norm * normSign, dist: dist, surface: self)
  }
}

