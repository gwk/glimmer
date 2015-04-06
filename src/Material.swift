// © 2015 George King.
// All rights reserved.

import Foundation


class Material {
  let isLight: Bool
  let col: V3D
  
  init(isLight: Bool, col: V3D) {
    self.isLight = isLight
    self.col = col
  }
}


