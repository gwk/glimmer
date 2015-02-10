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
    let thing = dot(ray.dir, (ray.pos - pos))
    let discriminant = thing.sqr - (ray.pos - pos).sqrLen + rad.sqr
    if discriminant <= 0 { return nil }
    let dist = -discriminant.sqrt - thing
    if dist <= 0 { return nil }
    return dist
  }
  
  func intersection(ray: Ray) -> Intersection? {
    if let dist = intersectionDist(ray) {
      let intersectionPos = ray.pos + ray.dir * dist
      let norm = (intersectionPos - pos) / rad
      return Intersection(pos: intersectionPos, norm: norm, dist: dist, surface: self)
    } else {
      return nil
    }
  }
}


