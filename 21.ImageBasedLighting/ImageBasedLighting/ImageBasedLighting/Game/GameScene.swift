/// Copyright (c) 2022 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import CoreGraphics

struct GameScene {
  lazy var ground: Model = {
    let model = Model(name: "large_plane.obj")
    model.tiling = 16
    return model
  }()
  lazy var car: Model = {
    Model(name: "racing-car.obj")
  }()

  var models: [Model] = []
  var camera = ArcballCamera()
  var defaultView: Transform {
    Transform(
      position: [2.85, 1.54, -2.34],
      rotation: [-0.4, -0.88, 0])
  }
  var lighting = SceneLighting()
    
    let skybox: Skybox?

  init() {
      skybox = Skybox(textureName: "sky")
    camera.transform = defaultView
    camera.target = car.position
    camera.distance = 4
    camera.far = 20
    models = [ground, car]
  }

  mutating func update(size: CGSize) {
    camera.update(size: size)
  }

  mutating func update(deltaTime: Float) {
    let input = InputController.shared
    if input.keysPressed.contains(.one) {
      camera.transform = Transform()
    }
    if input.keysPressed.contains(.two) {
      camera.transform = defaultView
    }
    input.keysPressed.removeAll()
    camera.update(deltaTime: deltaTime)
  }
}
