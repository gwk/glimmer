// © 2015 George King.
// All rights reserved.

// tool main.

import Foundation


initAppLaunchSysTime()

func main() { // this wrapper prevents noreturn warning on dispatch_main.
  let traceBuffer = runTracer() {}
  dispatch_main()
}

main()
