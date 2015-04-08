// © 2015 George King.
// All rights reserved.

import Foundation

let maxRaySteps = 6
let tracePasses = 1 << 12

let windowSize = V2I(256, 256)
let bufferSize = V2I(256, 256) //windowSize// * 2
let aspect = Double(bufferSize.x) / Double(bufferSize.y)

let scene = {
  () -> Scene in
  let rotL = M3D.rotY(k_pi / 8)
  let rotR = M3D.rotY(-k_pi / 8)
  let rotB = M3D.rotX(-k_pi / 8)
  let rotT = M3D.rotX(k_pi / 8)
  return Scene(
    camera: Camera(pos: V3D(0, 0, -1), dir: V3D(0, 0, 1), vert: 0.5),
    surfaces: [
      Plane(pos: V3D(-1, 0, 0), norm: rotL * V3D(1, 0, 0), material: Material(isLight: false, col: V3D(0.8, 0.3, 0.3))), // red left.
      Plane(pos: V3D( 1, 0, 0), norm: rotR * V3D(-1, 0, 0), material: Material(isLight: false, col: V3D(0.3, 0.8, 0.3))), // green right.
      Plane(pos: V3D(0, -1, 0), norm: rotB * V3D(0, 1, 0), material: Material(isLight: false, col: V3D(0.3, 0.3, 0.8))), // blue floor.
      Plane(pos: V3D(0,  1, 0), norm: rotT * V3D(0, -1, 0), material: Material(isLight: false, col: V3D(1, 1, 1))), // white ceil.
      Plane(pos: V3D(0, 0,  1), norm: V3D(0,  0, -1), material: Material(isLight: false, col: V3D(1, 1, 1))), // back.
      
      Sphere(pos: V3D(0, 0, 0),  rad: 0.4, material: Material(isLight: false, col:V3D(1, 1, 1))),
      
      Sphere(pos: V3D(0, 1, 0), rad: 0.3, material: Material(isLight: true, col:V3D(8, 8, 8))), // center light.
    ])
}()


let raysTot = AtmCounters(count: maxRaySteps)
let raysLit = AtmCounters(count: maxRaySteps) // rays that hit a light source.
let raysMissed = AtmCounters(count: maxRaySteps) // rays that miss all objects.
var raysDied: I64 = 0
var bouncesTot: I64 = 0
var bouncesNeg: I64 = 0 // bounces that result in an incorrect ray pointing into the internal hemisphere; should never happen.


func tracePrimaryRay(primaryRay: Ray) -> V3D {
  var ray = primaryRay
  var col = V3D(1, 1, 1)
  for i in 0..<maxRaySteps {
    raysTot.inc(i)
    if let intersection = scene.query(ray) {
      col = col * intersection.surface.material.col
      if intersection.surface.material.isLight {
        raysLit.inc(i)
        return col
      }
      ray = bounce(ray, intersection)
      atmInc(&bouncesTot)
      if intersection.norm.dot(ray.dir) < 0 {
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


var concTraceRows: I64 = 0

func traceRow(buffer: PixelBuffer, j: Int, fj: Double) {
  atmInc(&concTraceRows)
  for i in 0..<bufferSize.x {
    let fi = ((Double(i) / Double(bufferSize.x)) * 2 - 1) * aspect
    let primary = Ray(pos: V3D(fi, fj, -1), dir: V3D(0, 0, 1))
    let col = tracePrimaryRay(primary)
    #if true // accumulation.
      buffer.setEl(i, j, Pixel(prev: buffer.el(i, j), col: col))
    #else // no accumulation.
      buffer.setEl(i, j, Pixel(col: col))
    #endif
  }
  atmDec(&concTraceRows)
}


let traceAttr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0);
let traceQueue = dispatch_queue_create("com.gonkus.glint.traceQueue", traceAttr)
// concurrency is not working; currently crashes in various places in -Onone mode.
// note: remember to turn off compiler optimizations when working on this.

func schedulePass(buffer: PixelBuffer, passIndex: Int, passCount: Int, passCompleteAction: Action) {
  let passTime = appTime()
  raysTot.zeroAll()
  raysLit.zeroAll()
  raysMissed.zeroAll()
  raysDied = 0
  bouncesTot = 0
  bouncesNeg = 0
  let cam = scene.camera
  let camRot = M3D.rot(V3D.unitZ, cam.dir)
  let corner = camRot * V3D(cam.hori(buffer.size.aspect), cam.vert, 1)
  for j in 0..<bufferSize.y {
    let fj = (Double(j) / Double(bufferSize.y)) * 2 - 1
    dispatch_async(traceQueue) {
      traceRow(buffer, j, fj)
    }
  }
  dispatch_barrier_async(traceQueue) {
    assert(concTraceRows == 0)
    func frac(num: I64, den: I64) -> F64 { return F64(num) / F64(max(1, den)) }
    #if true
      var lines = [
        "pass:\(passIndex) time:\(appTime() - passTime)",
        "  bounces: \(bouncesTot); negs:\(bouncesNeg)|\(frac(bouncesNeg, bouncesTot))"
      ]
      for i in 0..<maxRaySteps {
        let tot = raysTot[i]
        let lit = raysLit[i]
        let missed = raysMissed[i]
        let bounced = tot - (lit + missed)
        lines.append("  rays[\(i)]:\(tot) lit:\(lit)|\(frac(lit, tot)) missed:\(missed)|\(frac(missed, tot)) bounced:\(bounced)|\(frac(bounced, tot))")
      }
      lines.append("  died:\(raysDied)|\(frac(raysDied, raysTot[0]))")
      outLLA(lines)
    #endif
    dispatch_async(dispatch_get_main_queue(), passCompleteAction)
    if passIndex < passCount {
      schedulePass(buffer, passIndex + 1, passCount, passCompleteAction)
    }
  }
}


func runTracer(passCompleteAction: Action) -> PixelBuffer {
  let traceBuffer = PixelBuffer()
  traceBuffer.resize(bufferSize, val: Pixel())
  dispatch_async(traceQueue) {
    schedulePass(traceBuffer, 0, tracePasses, passCompleteAction)
  }
  return traceBuffer
}

