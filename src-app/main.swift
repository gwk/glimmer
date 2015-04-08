// © 2015 George King.
// All rights reserved.

// app main.

import Cocoa


initAppLaunchSysTime()

let app = NSApplication.sharedApplication()
app.setActivationPolicy(NSApplicationActivationPolicy.Regular)

// app delegate saved to global so that object is retained for lifetime of app.
let appDelegate = AppDelegate()
app.delegate = appDelegate

app.run()
