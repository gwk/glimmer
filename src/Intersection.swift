// © 2015 George King.
// All rights reserved.

import Foundation


struct Intersection {
  let pos: V3D
  let norm: V3D
  let dist: Double
  let surface: Surface
}


func randD() -> Double {
  let max = Double((1<<32) - 1)
  return Double(arc4random()) / max
}


func randDSigned() -> Double {
  return randD() * 2 - 1
}

func randD(min: Double, max: Double) -> Double {
  return randD() * (max - min) + min
}

func randNormOld() -> V3D {
  let y = randD().sqrt
  let theta = acos(y)
  let phi = k_2_pi * randD()
  let x = sin(theta) * cos(phi)
  let z = sin(theta) * sin(phi)
  return V3D(x, y, z)
}

func randNorm(min: Double, max: Double) -> V3D {
  assert(min >= -1 && min <= 1)
  assert(max >= -1 && max <= 1)
  let x = randD(min, max: max)
  let theta = randD(0, max: k_2_pi)
  let w = sqrt(1 - x.sqr)
  return V3D(x, w * cos(theta), w * sin(theta))
}

func randNorm() -> V3D {
  return randNorm(-1, max: 1)
}


func bounce(ray: Ray, intersection: Intersection) -> Ray {
  let norm = intersection.norm
  
  #if false // perfect specularity.
    let out = ray.dir - norm * 2 * ray.dir.dot(norm)
    #elseif false // unfinished diffusion.
    let axis = V3D(1, 0, 0)
    let randGlobal = randNorm(0, 1) // hemisphere in pos x.
    let theta = acos(dot(axis, randGlobal))
    let c = cross(axis, randGlobal)
    let rot = M3DRot(theta, c)
    let out = rot * randGlobal
    #else // perfectly diffuse.
    var out = randNorm(-1, max: 1)
    if norm.dot(out) < 0 {
      out = out * -1
    }
  #endif
  return Ray(pos: intersection.pos, dir: out)
  
  #if false // crazy.
    let theta = acos(dot(reflection, norm)) // angle between normal and reflection.
    let distortion = k_2_pi * 0.5
    let angle_min = max(-k_2_pi, theta - distortion)
    let angle_max = min(k_2_pi, theta + distortion)
    let pitch = randD(angle_min, angle_max)
    let yaw = randD(-distortion, distortion)
    
    let tangent = cross(norm, reflection)
    let rotPitch = M3DRot(pitch, tangent)
    let rotYaw = M3DRot(yaw, norm)
    let distorted = (rotPitch * rotYaw) * reflection
  #endif
}
