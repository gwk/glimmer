// © 2015 George King.
// All rights reserved.

import Foundation


let windowSize = V2I(600, 400)
let bufferSize = windowSize// * 2
let aspect = Double(bufferSize.x) / Double(bufferSize.y)

let bufferLen = bufferSize.x * bufferSize.y
var traceBuffer = [Pixel](count: bufferLen, repeatedValue: Pixel())

let scene = {
  () -> Scene in
  return Scene(
    surfaces: [
      //Plane(pos: V3D(-1, 0, 0), norm: V3D(-1, 0, 0), material: Material(isLight: false, col: V3D(0.8, 0.3, 0.3))), // red left.
      //Plane(pos: V3D( 1, 0, 0), norm: V3D( 1, 0, 0), material: Material(isLight: false, col: V3D(0.3, 0.8, 0.3))), // green right.
      //Plane(pos: V3D(0, -1, 0), norm: V3D(0, -1, 0), material: Material(isLight: false, col: V3D(0.3, 0.3, 0.8))), // blue floor.
      //Plane(pos: V3D(0,  1, 0), norm: V3D(0,  1, 0), material: Material(isLight: true, col: V3D(0.5, 0.5, 0.5))), // gray ceil.
      //Plane(pos: V3D(0, 0,  1), norm: V3D(0,  0, 1), material: Material(isLight: false, col: V3D(1, 1, 1))), // back.
      
      Sphere(pos: V3D(0, 0, 0),  rad: 0.4, material: Material(isLight: false, col:V3D(0.8, 0.8, 0.8))),
      
      Sphere(pos: V3D(0, 1, 0), rad: 0.3, material: Material(isLight: true, col:V3D(1, 1, 1))), // center light.
    ])
}()


let rayMaxSteps = 6

var bouncesTot: I64 = 0
var bouncesNeg: I64 = 0 // bounces that result in an incorrect ray pointing into the internal hemisphere; should never happen.

var raysTot = AtmCounters(count: rayMaxSteps)
var raysLit = AtmCounters(count: rayMaxSteps) // rays that hit a light source.
var raysMissed = AtmCounters(count: rayMaxSteps) // rays that miss all objects.
var raysDied: I64 = 0

func tracePrimaryRay(primaryRay: Ray) -> V3D {
  var ray = primaryRay
  var col = V3D(1, 1, 1)
  for i in 0..<rayMaxSteps {
    raysTot.inc(i)
    if let intersection = scene.query(ray) {
      col = col * intersection.surface.material.col
      if intersection.surface.material.isLight {
        raysLit.inc(i)
        return col
      }
      ray = bounce(ray, intersection)
      atmInc(&bouncesTot)
      if dot(intersection.norm, ray.dir) < 0 {
        atmInc(&bouncesNeg)
      }
    } else { // ray missed all objects in scene.
      raysMissed.inc(i)
      return V3D()
    }
  }
  atmInc(&raysDied)
  return V3D() // ray died after rayMaxSteps.
}


func traceLine(j: Int) {
  let fj = (Double(j) / Double(bufferSize.y)) * 2 - 1
  for i in 0..<bufferSize.x {
    let fi = ((Double(i) / Double(bufferSize.x)) * 2 - 1) * aspect
    let primary = Ray(pos: V3D(fi, fj, -1), dir: V3D(0, 0, 1))
    let col = tracePrimaryRay(primary)
    let off = (j * bufferSize.x + i)
    #if true // accumulation.
      traceBuffer[off] = Pixel(prev: traceBuffer[off], col: col)
    #else // no accumulation.
      traceBuffer[off] = Pixel(sample: col)
    #endif
  }
}


let traceAttr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
let traceQueue = dispatch_queue_create("traceQueue", traceAttr)

func schedulePass() {
  let passTime = appTime()
  for j in 0..<bufferSize.y {
    dispatch_async(traceQueue) {
      traceLine(j)
    }
  }
  dispatch_barrier_async(traceQueue) {
    func frac(num: I64, den: I64) -> F64 { return F64(num) / F64(den) }
    println("time:\(appTime() - passTime)")
    
    println("bounces: \(bouncesTot); negs \(frac(bouncesNeg, bouncesTot))")
    bouncesTot = 0
    bouncesNeg = 0
    
    for i in 0..<rayMaxSteps {
      let tot = max(1, raysTot[i])
      println("rays:\(tot) lit:\(raysLit[i])|\(frac(raysLit[i], tot)) miss:\(raysMissed[i])|\(frac(raysMissed[i], tot))")
    }
    let raysTot0 = max(1, raysTot[0])
    println("died:\(raysDied)|\(frac(raysDied, raysTot0))")
    raysTot.zeroAll()
    raysLit.zeroAll()
    raysMissed.zeroAll()
    raysDied = 0
    schedulePass()
  }
}


func runTracer() {
  dispatch_async(traceQueue) {
    schedulePass()
  }
}

