// © 2015 George King.
// All rights reserved.

import Cocoa


class AppDelegate: NSObject, NSApplicationDelegate {
  
  var window: NSWindow!
  var viewController: GLViewController!
  
  override init() {}
  
  func applicationDidFinishLaunching(note: NSNotification) {
    
    let processInfo = NSProcessInfo.processInfo()
    
    // menu bar.
    let quitItem = NSMenuItem(
      title: "Quit " + processInfo.processName,
      action: Selector("terminate:"),
      keyEquivalent:"q")
    
    
    let appMenu = NSMenu()
    appMenu.addItem(quitItem)
    
    let appMenuBarItem = NSMenuItem()
    appMenuBarItem.submenu = appMenu
    
    let menuBar = NSMenu()
    menuBar.addItem(appMenuBarItem)
    
    let app = NSApplication.sharedApplication()
    app.mainMenu = menuBar
    
    viewController = GLViewController(pixFmt: .RGBAU8D16)
    viewController.title = "Glimmer"
    viewController.render = render
    viewController.handleEvent = handleEvent
    viewController.glView.glLayer.asynchronous = false
    
    window = NSWindow(
      contentRect: CGRectZero, // arbitrary; gets clobbered by controller view initial size.
      styleMask: NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask,
      backing: NSBackingStoreType.Buffered,
      `defer`: false)
    window.contentViewController = viewController
    window.bind(NSTitleBinding, toObject:viewController, withKeyPath:"title", options:nil)
    window.contentAspectRatio = viewController.view.frame.size
    viewController.updateWindowObserver()
    
    window.origin = CGPoint(8, 48)
    window.size = CGSize(Flt(windowSize.x), Flt(windowSize.y))
    window.makeKeyAndOrderFront(nil)
  }
}
