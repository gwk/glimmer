// © 2015 George King.
// All rights reserved.

import Foundation


class Sphere: Surface {
  let pos: V3D
  let rad: Double
  let material: Material
  
  var box: Box { return Box(low: pos - rad, high: pos + rad) }
  
  init(pos: V3D, rad: Double, material: Material) {
    self.pos = pos
    self.rad = rad
    self.material = material
  }
  
  func intersectionDist(ray: Ray) -> Double? {
    let thing = ray.dir.dot(ray.pos - pos)
    let discriminant = thing.sqr - (ray.pos - pos).sqrLen + rad.sqr
    if discriminant <= 0 { return nil }
    // discriminant < 0 means a clean miss.
    // discriminant == 0 is a perfect tangent, which is also a miss for our purposes.
    let dist = -discriminant.sqrt - thing
    // choose the smaller of the two possible solutions.
    if dist < 0 { return nil }
    // negative distance means ray was either inside of or behind the sphere.
    // zero distance means that the ray originated on the sphere,
    // in which case it should not be captured.
    return dist
  }
  
  func intersection(ray: Ray) -> Intersection? {
    if let dist = intersectionDist(ray) {
      let intersectPos = ray.pos + ray.dir * dist
      let norm = (intersectPos - pos) / rad
      return Intersection(pos: intersectPos, norm: norm, dist: dist, surface: self)
    } else {
      return nil
    }
  }
}


