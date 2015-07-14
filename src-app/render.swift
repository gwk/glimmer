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


let windowSize = V2I(256, 256)

var tracer: Tracer! = nil
var traceTex: GLTexture! = nil

let texBuffer = AreaBuffer<(U8, U8, U8)>()

var needsSetup = true
func setup() {
  if !needsSetup {
    return
  }
  needsSetup = false
  traceTex = GLTexture()
  texBuffer.resize(testBufferSize, val: (0, 0, 0))
  tracer = Tracer(scene: testScene, bufferSize: testBufferSize, passCount: testPassCount, maxRaySteps: testMaxRaySteps) {
    (tracer, tracerState) in
    // copy trace buffer to render buffer.
    assert(texBuffer.count == tracerState.buffer.count)
    for i in 0..<texBuffer.count {
      texBuffer[i] = tracerState.buffer[i].colU8
    }
    appDelegate.viewController.glView.layer!.setNeedsDisplay()
  }
  tracer.run()
}


var renderCounter = 0

func render(scale: F32, sizePt: V2S, time: Time) {
  print("render: \(renderCounter)")
  glClearColor(0, 0, 0, 0)
  glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
  setup()
  
  // TODO: bind traceTex?
  texBuffer.withUnsafeBufferPointer() {
    (bp) -> () in
    traceTex.update(w: Int(texBuffer.size.x), h: Int(texBuffer.size.y), fmt: .RGB, dataFmt: .RGB, dataType: .U8, data: bp.baseAddress)
    traceTex.setFilter(GLenum(GL_NEAREST))
  }

  // triangle fan starting from upper left, counterclockwise.
  let verts = [V2S(0, 0), V2S(0, 1), V2S(1, 1), V2S(1, 0)]
  program.use()
  program.bindAttr("glPos", stride: sizeof(V2S), V2S: verts, offset: 0)
  glDrawArrays(GLenum(GL_TRIANGLE_FAN), 0, GLint(verts.count * 2))
  glAssert()
  renderCounter++
}

