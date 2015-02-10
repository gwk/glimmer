// © 2015 George King.
// All rights reserved.

import Foundation

#if os(OSX)
  import OpenGL
  import OpenGL.GL
  #else
  import OpenGLES
  import OpenGLES.GL
#endif


let bufferTex = GLTexture()
let renderBufferLen = bufferLen  * 3 // RGB.
var renderBuffer = [U8](count: renderBufferLen, repeatedValue: 0)


let program = GLProgram(name: "program", sources: [
  "varying vec2 texPos;",
  
  "vert:",
  "attribute vec2 glPos;",
  "void main(void) {",
  "  texPos = glPos,",
  "  gl_Position = vec4((glPos * 2.) - 1., 0.0, 1.0);",
  "}",
  
  "frag:",
  "uniform mediump sampler2D tex;",
  "void main(void) {",
  "  vec4 texel = texture2D(tex, texPos);", // TODO: texelFetch.
  "  gl_FragColor = vec4(texel.rgb, 1.0);",
  "}"
  ])


var needsSetup = true
func setup() {
  if !needsSetup {
    return
  }
  needsSetup = false
  runTracer()
}


var renderCounter = 0

func render(scale: F32, sizePt: V2S, time: Time) {
  //println("render: \(renderCounter)")
  glClearColor(0, 0, 0, 0)
  glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
  setup()
  
  // copy trace buffer to render buffer.
  for j in 0..<bufferSize.y {
    for i in 0..<bufferSize.x {
      let off = (bufferSize.x * j + i)
      let (r, g, b) = traceBuffer[off].colU8
      renderBuffer[3 * off + 0] = r
      renderBuffer[3 * off + 1] = g
      renderBuffer[3 * off + 2] = b
    }
  }
  renderBuffer.withUnsafeBufferPointer() {
    (bp) -> () in
    bufferTex.update(w: bufferSize.x, h: bufferSize.y, fmt: .RGB, dataFmt: .RGB, dataType: .U8, data: bp.baseAddress)
    bufferTex.setFilter(GLenum(GL_NEAREST))
  }

  // triangle fan starting from upper left, counterclockwise.
  let verts = [V2S(0, 0), V2S(0, 1), V2S(1, 1), V2S(1, 0)]
  program.use()
  program.bindAttr("glPos", stride: sizeof(V2S), V2S: verts, offset: 0)
  glDrawArrays(GLenum(GL_TRIANGLE_FAN), 0, GLint(verts.count * 2))
  glAssert()
  //renderCounter++
}

