// © 2015 George King.
// All rights reserved.

// tool main.

import Foundation


initAppLaunchSysTime()

func main() { // this wrapper prevents noreturn warning on dispatch_main.
  let t = Tracer(scene: testScene, passCount: testPassCount, maxRaySteps: testMaxRaySteps, bufferSize: testBufferSize) {
    (tracer) in
    println("finished pass...")
  }
  t.run()
  dispatch_main()
}

main()
