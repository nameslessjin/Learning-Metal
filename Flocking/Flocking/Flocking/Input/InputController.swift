//
//  InputController.swift
//  Flocking
//
//  Created by JINSEN WU on 10/13/23.
//

import GameController

class InputController {
    struct Point {
        var x: Float
        var y: Float
        static let zero = Point(x: 0, y: 0)
    }
    
    static let shared = InputController()
    var keyPressed: Set<GCKeyCode> = []
    var leftMouseDown = false
    var mouseDelta = Point.zero
    var mouseScroll = Point.zero
    var touchLocation: CGPoint?
    
    private init() {
        let center = NotificationCenter.default
        center.addObserver(forName: .GCKeyboardDidConnect, object: nil, queue: nil) {
            notification in
            let keyboard = notification.object as? GCKeyboard
            keyboard?.keyboardInput?.keyChangedHandler =  { _, _, keyCode, pressed in
                if pressed {
                    self.keyPressed.insert(keyCode)
                } else {
                    self.keyPressed.remove(keyCode)
                }
            }
        }
        
        center.addObserver(forName: .GCMouseDidConnect, object: nil, queue: nil) {
            notification in
            let mouse = notification.object as? GCMouse
            mouse?.mouseInput?.leftButton.pressedChangedHandler = { _, _, pressed in
                self.leftMouseDown = pressed
            }
            mouse?.mouseInput?.mouseMovedHandler = { _, deltaX, deltaY in
                self.mouseDelta = Point(x: deltaX, y: deltaY)
            }
            mouse?.mouseInput?.scroll.valueChangedHandler = { _, xValue, yValue in
                self.mouseScroll.x = xValue
                self.mouseScroll.y = yValue
            }
        }
        
#if os(macOS)
        NSEvent.addLocalMonitorForEvents(matching: [.keyUp, .keyDown]) { _ in nil}
#endif
    }
}
