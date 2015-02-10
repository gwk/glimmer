// © 2015 George King.
// All rights reserved.


func handleEvent(event: GLEvent) {
  switch event {
  case .Touch(let touch): break //println("T \(touch.time)")
  case .Key(let key): break //println("K \(key.time)")
    //case .Tick(let tick): println("  \(tick)")
  default: break
  }
}