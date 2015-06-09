// © 2015 George King.
// All rights reserved.

import Foundation


class Tracer {
  let scene: Scene
  let passCount: Int
  let maxRaySteps: Int
  let onPassCompletion: (Tracer)->()

  let buffer: PixelBuffer
  let rowPairs: [(V3D, V3D)]
  
  var passIndex = 0
  var rowIndex = 0
  
  let raysTot: AtmCounters
  let raysLit: AtmCounters // rays that hit a light source.
  let raysMissed: AtmCounters // rays that miss all objects.
  var raysDied: I64 = 0
  var bouncesTot: I64 = 0
  var bouncesNeg: I64 = 0 // bounces that result in an incorrect ray pointing into the internal hemisphere; should never happen.
  var passTime: Time = 0
  
  var rowCount: Int { return buffer.size.y }

  var isPassComplete: Bool { return rowIndex == rowCount }
  var isTraceComplete: Bool { return passIndex == passCount }
  
  init(scene: Scene, passCount: Int, maxRaySteps: Int, bufferSize: V2I, onPassCompletion: (Tracer)->()) {
    self.scene = scene
    self.passCount = passCount
    self.maxRaySteps = maxRaySteps
    self.onPassCompletion = onPassCompletion
    
    raysTot = AtmCounters(count: maxRaySteps)
    raysLit = AtmCounters(count: maxRaySteps) // rays that hit a light source.
    raysMissed = AtmCounters(count: maxRaySteps) // rays that miss all objects.

    buffer = PixelBuffer()
    buffer.resize(bufferSize, val: Pixel())

    // set up scanlines.
    let cam = scene.camera
    let camRot = M3D.rot(V3D.unitZ, cam.dir)
    let cx = cam.hori(buffer.size.aspect)
    let cy = cam.vert
    let cornerLB = camRot * V3D(-cx, -cy, 1)
    let cornerLT = camRot * V3D(-cx, cy, 1)
    let cornerRB = camRot * V3D(cx, -cy, 1)
    let cornerRT = camRot * V3D(cx, cy, 1)
    
    let rowCount = bufferSize.y
    rowPairs = map(0..<buffer.size.y) {
      (j) -> (V3D, V3D) in
      let tj = ((Double(j) + 0.5) / Double(rowCount))
      let rowL = cornerLB.lerp(cornerLT, tj)
      let rowR = cornerRB.lerp(cornerRT, tj)
      return (rowL, rowR)
    }
  }
  
  func tracePrimaryRay(primaryRay: Ray) -> V3D {
    var ray = primaryRay
    var col = V3D(1, 1, 1)
    for i in 0..<maxRaySteps {
      //raysTot.inc(i)
      if let intersection = scene.query(ray) {
        col = col * intersection.surface.material.col
        if intersection.surface.material.isLight {
          //raysLit.inc(i)
          return col
        }
        ray = bounce(ray, intersection)
        //atmInc(&bouncesTot)
        if intersection.norm.dot(ray.dir) < 0 {
          //atmInc(&bouncesNeg)
        }
      } else { // ray missed all objects in scene.
        //raysMissed.inc(i)
        return V3D()
      }
    }
    //atmInc(&raysDied)
    return V3D() // ray died after rayMaxSteps.
  }
  
  
  func traceRow(rowIndex: Int, rowL: V3D, rowR: V3D) {
    //atmInc(&concTraceRows)
    for i in 0..<buffer.size.x {
      let ti = ((Double(i) + 0.5) / Double(buffer.size.x))
      let primary = Ray(pos: scene.camera.pos, dir: rowL.lerp(rowR, ti).norm)
      let col = tracePrimaryRay(primary)
      let b = buffer
      syncAction(b) {
        #if true // accumulation.
          b.setEl(i, rowIndex, Pixel(prev: b.el(i, rowIndex), col: col))
          #else // no accumulation.
          b.setEl(i, rowIndex, Pixel(col: col))
        #endif
      }
    }
    //atmDec(&concTraceRows)
  }
  
  func finishPass() {
    func frac(num: I64, den: I64) -> F64 { return F64(num) / F64(max(1, den)) }

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

    raysTot.zeroAll()
    raysLit.zeroAll()
    raysMissed.zeroAll()
    raysDied = 0
    bouncesTot = 0
    bouncesNeg = 0

    dispatch_sync(dispatch_get_main_queue()) {
      self.onPassCompletion(self)
    }
    self.passIndex++
    self.rowIndex = 0
    passTime = appTime()
  }
  
  func run() {
    passTime = appTime()
    for i in 0..<1 {
      spawnThread() {
        while true {
          let rowIndex = syncAround(self) {
            () -> Int? in
            if self.isPassComplete {
              self.finishPass()
            }
            if self.isTraceComplete { return nil }
            return self.rowIndex++
          }
          if let rowIndex = rowIndex {
            let (l, r) = self.rowPairs[rowIndex]
            self.traceRow(rowIndex, rowL:l, rowR:r)
          } else { // trace is complete.
            break
          }
        }
      }
    }
  }
}

