// © 2015 George King.
// All rights reserved.

import Foundation


protocol Surface {
  var material: Material { get }
  func intersection(ray: Ray) -> Intersection?
}


