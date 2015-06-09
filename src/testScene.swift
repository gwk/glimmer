// © 2015 George King.
// All rights reserved.

import Foundation


let testMaxRaySteps = 4
let testPassCount = 1 << 12

let testBufferSize = V2I(256, 256)

let testScene = {
  () -> Scene in
  return Scene(
    camera: Camera(pos: V3D(0.5, 0.5, -2.5), dir: V3D(-0.2, -0.2, 1), vert: 0.5),
    surfaces: [
      Plane(pos: V3D(-1, 0, 0), norm: V3D(1, 0, 0), material: Material(isLight: false, col: V3D(0.8, 0.3, 0.3))), // red left.
      Plane(pos: V3D( 1, 0, 0), norm: V3D(-1, 0, 0), material: Material(isLight: false, col: V3D(0.3, 0.8, 0.3))), // green right.
      Plane(pos: V3D(0, -1, 0), norm: V3D(0, 1, 0), material: Material(isLight: false, col: V3D(0.3, 0.3, 0.8))), // blue floor.
      Plane(pos: V3D(0,  1, 0), norm: V3D(0, -1, 0), material: Material(isLight: false, col: V3D(1, 1, 1))), // white ceil.
      Plane(pos: V3D(0, 0,  1), norm: V3D(0,  0, -1), material: Material(isLight: false, col: V3D(1, 1, 1))), // back.
      
      Sphere(pos: V3D(0, 0, 0),  rad: 0.4, material: Material(isLight: false, col:V3D(1, 1, 1))),
      
      Sphere(pos: V3D(0, 1, 0), rad: 0.2, material: Material(isLight: true, col:V3D(8, 8, 8))), // center light.
    ])
  }()


