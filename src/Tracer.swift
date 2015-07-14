// © 2015 George King.
// All rights reserved.

import Foundation
import simd


class TracerState {
  let buffer: PixelBuffer
  let passCount: Int

  var passIndex = 0
  var rowIndex = 0
  var passTime: Time = 0

  var rowCount: Int { return Int(buffer.size.y) }
  var isPassComplete: Bool { return rowIndex == rowCount }
  var isTraceComplete: Bool { return passIndex == passCount }
  
  init(bufferSize: V2I, passCount: Int) {
    buffer = PixelBuffer()
    buffer.resize(bufferSize, val: Pixel())
    self.passCount = passCount
  }
}


class Tracer {
  let scene: Scene
  let bufferSize: V2I
  let maxRaySteps: Int
  let onPassCompletion: (Tracer, TracerState)->()
  
  let rowPairs: [(V3D, V3D)]
  
  let lockedState: Locked<TracerState>
  
  // atomic counters are not part of the lock-protected state.
  let raysTot: AtmCounters
  let raysLit: AtmCounters // rays that hit a light source.
  let raysMissed: AtmCounters // rays that miss all objects.
  var raysDied: I64 = 0
  var bouncesTot: I64 = 0
  var bouncesNeg: I64 = 0 // bounces that result in an incorrect ray pointing into the internal hemisphere; should never happen.
  
  init(scene: Scene, bufferSize: V2I, passCount: Int, maxRaySteps: Int, onPassCompletion: (Tracer, TracerState)->()) {
    self.scene = scene
    self.bufferSize = bufferSize
    self.maxRaySteps = maxRaySteps
    self.onPassCompletion = onPassCompletion
    
    lockedState = Locked(TracerState(bufferSize: bufferSize, passCount: passCount))
    raysTot = AtmCounters(count: maxRaySteps)
    raysLit = AtmCounters(count: maxRaySteps) // rays that hit a light source.
    raysMissed = AtmCounters(count: maxRaySteps) // rays that miss all objects.

    // set up scanlines.
    let cam = scene.camera
    let camRot = M3D.rot(V3D.unitZ, cam.dir)
    let cx = cam.hori(bufferSize.aspect)
    let cy = cam.vert
    let cornerLB = camRot * V3D(-cx, -cy, 1)
    let cornerLT = camRot * V3D(-cx, cy, 1)
    let cornerRB = camRot * V3D(cx, -cy, 1)
    let cornerRT = camRot * V3D(cx, cy, 1)
    
    let rowCount = bufferSize.y
    rowPairs = (0..<rowCount).map {
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
    for _ in 0..<maxRaySteps {
      //raysTot.inc(i)
      if let intersection = scene.query(ray) {
        col = col * intersection.surface.material.col
        if intersection.surface.material.isLight {
          //raysLit.inc(i)
          return col
        }
        ray = bounce(ray, intersection: intersection)
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
    for i in 0..<Int(bufferSize.x) {
      let ti = ((Double(i) + 0.5) / Double(bufferSize.x))
      let primary = Ray(pos: scene.camera.pos, dir: rowL.lerp(rowR, ti).norm)
      let col = tracePrimaryRay(primary)
      lockedState.access {
        (state) -> () in
        let b = state.buffer
        #if true // accumulation.
          b.setEl(i, rowIndex, Pixel(prev: b.el(i, rowIndex), col: col))
          #else // no accumulation.
          b.setEl(i, rowIndex, Pixel(col: col))
        #endif
      }
    }
    //atmDec(&concTraceRows)
  }
  
  func startPass(state: TracerState) {
    state.passTime = appTime()
  }
  
  func finishPass(state: TracerState) {
    func frac(num: I64, _ den: I64) -> F64 { return F64(num) / F64(max(1, den)) }

    var lines = [
      "pass:\(state.passIndex) time:\(appTime() - state.passTime)",
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
    lines.append("  lock: \(lockedState.statsDesc())")
    outLLA(lines)

    raysTot.zeroAll()
    raysLit.zeroAll()
    raysMissed.zeroAll()
    raysDied = 0
    bouncesTot = 0
    bouncesNeg = 0

    sync {
      self.onPassCompletion(self, state)
    }
    state.passIndex++
    state.rowIndex = 0
  }
  
  func run() {
    lockedState.access(startPass)
    for i in 0..<processorCount {
      spawnThread("trace thread \(i)") {
        while true {
          let rowIndex = self.lockedState.access {
            (state) -> Int? in
            if state.isPassComplete { // first thread to notice completed pass advances to next pass for all threads.
              self.finishPass(state)
              self.startPass(state)
            }
            if state.isTraceComplete { return nil } // all threads eventually reach this state.
            return state.rowIndex++ // take the current row and increment.
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

