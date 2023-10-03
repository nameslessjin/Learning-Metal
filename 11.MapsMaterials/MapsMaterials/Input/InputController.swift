import GameController

class InputController {
    struct Point {
        var x: Float
        var y: Float
        static let zero = Point(x: 0, y: 0)
    }
    
    static let shared = InputController() // creates a singleton input controller that you can access throughout the app
    var keysPressed: Set<GCKeyCode> = []
    var leftMouseDown = false
    var mouseDelta = Point.zero
    var mouseScroll = Point.zero
    var touchLocation: CGPoint?
    var touchDelta: CGSize? {
        didSet {
            touchDelta?.height *= -1
            if let delta = touchDelta {
                mouseDelta = Point(x: Float(delta.width), y: Float(delta.height))
            }
            leftMouseDown = touchDelta != nil
        }
    }
    
    private init() {
        let center = NotificationCenter.default
        // we add an observer to set the keyCHangedHandler when the keyboard first connects to the app
        // when the player presses or lifts a key, the keyChangedHandler code runs and either adds or removes the key from the set
        center.addObserver(forName: .GCKeyboardDidConnect, object: nil, queue: nil) {
            notification in
                let keyboard = notification.object as? GCKeyboard
                keyboard?.keyboardInput?.keyChangedHandler = {_, _, keyCode, pressed in
                    if pressed {
                        self.keysPressed.insert(keyCode)
                    } else {
                        self.keysPressed.remove(keyCode)
                    }
                }
        }
        
        #if os(macOS)
        // interrupt the view's responder chain by handling any key pressed and telling the system that it doesn't need
        // to take action when a key is pressed
        NSEvent.addLocalMonitorForEvents(matching: [.keyUp, .keyDown]) { _ in nil}
        #endif
        
        center.addObserver(forName: .GCMouseDidConnect, object: nil, queue: nil) {
            notification in
                let mouse = notification.object as? GCMouse
                mouse?.mouseInput?.leftButton.pressedChangedHandler = { _, _, pressed in self.leftMouseDown = pressed} // record left button
                mouse?.mouseInput?.mouseMovedHandler = { _, deltaX, deltaY in self.mouseDelta = Point(x: deltaX, y: deltaY)} // track mouse movement
                mouse?.mouseInput?.scroll.valueChangedHandler = { _, xValue, yValue in  // record scroll wheel movement
                    self.mouseScroll.x = xValue
                    self.mouseScroll.y = yValue
                }
        }
    }
}
