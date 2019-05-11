//
//  ViewController.swift
//  HiThere
//
//  Created by leavez on 2019/5/8.
//  Copyright © 2019 me.leavez. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    struct Settings {
        var showingDuration: TimeInterval = 4
        var imageWidth: CGFloat = 60
        var imageOffsetToCursor = CGPoint(x: 20, y: -10)
    }
    
    var settings = Settings()

    lazy private(set) var imageSize: CGSize = {
        guard let size = NSImage(named: "pic")?.size else {
            fatalError()
        }
        let ratio = size.height / size.width
        let width: CGFloat = settings.imageWidth
        return CGSize(width: width, height: width * ratio)
    }()
    
    var showing = false {
        didSet {
            if showing {
                // Use a delay to make a feeling of 'appeared suddenly'.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    
                    let location = NSEvent.mouseLocation
                    self.view.window?.setFrame(CGRect(x: 0, y: 0, width: self.imageSize.width, height: self.imageSize.height), display: false)
                    self.moveWindow(position: location)
                }
            } else {
                view.window?.setFrame(NSRect(x: 0, y: 0, width: 0, height: 0), display: true)
            }
        }
    }
    
    private var positionHistory: [(p:CGPoint, timestamp:Double)] = []
    
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = { // set up the status bar menu
            statusItem.button?.title = "🐙"
            let menu = NSMenu()
            statusItem.menu = menu
        
            let autoDisappear = NSMenuItem(title: "Auto Disappear", action: #selector(ViewController.didSelectedAutoDisappear), keyEquivalent: "")
            autoDisappear.state = self.autoDisappear ? .on : .off
            autoDisappear.target = self
            menu.addItem(autoDisappear)
            menu.addItem(NSMenuItem.separator())
            let item = NSMenuItem(title: "quit", action:#selector(ViewController.quit), keyEquivalent:"q")
            item.target = self
            menu.addItem(item)
        }()
        

        // Observe the cursor postion
        NSEvent.addGlobalMonitorForEvents(matching: NSEvent.EventTypeMask.mouseMoved, handler: { [weak self] (mouseEvent:NSEvent) in
            self?.mouseDidMove(event: mouseEvent)
        })
        
//        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.mouseMoved) { (mouseEvent:NSEvent) -> NSEvent? in
//            self.mouseDidMove(event: mouseEvent)
//            return mouseEvent
//        }
        
    }

    private var firstShown = true
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if firstShown {
            firstShown = false
            
            // Make the window always on top
            // Another option is set in the storyboard to the window: 'Can join all space'
            // to make the window visiable to all display spaces.
            view.window?.level = .floating
            self.showing = false
            
            if let window = self.view.window {
                window.hasShadow = false
                window.isOpaque = false
                window.backgroundColor = .clear
            }
        }
        
    }


    func mouseDidMove(event: NSEvent) {
        // get postion
        var postion = event.locationInWindow
        if event.window == view.window, let w = view.window {
            postion.x += w.frame.origin.x
            postion.y += w.frame.origin.y
        }
        
        if self.showing {
            moveWindow(position: postion)
        }
        
        if (!frozeTime && shouldShow(position: postion, timestamp: event.timestamp)) {
            print("fire")
            self.showing.toggle()
            
            if (autoDisappear) {
                frozeTime = true
                DispatchQueue.main.asyncAfter(deadline: .now() + settings.showingDuration) {
                    self.showing.toggle()
                    self.frozeTime = false
                }
            } else {
                frozeTime = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.frozeTime = false
                }
            }
            
        }
    }
    private var frozeTime = false
    
    func moveWindow(position:CGPoint) {
        let offset = settings.imageOffsetToCursor
        view.window?.setFrameOrigin(CGPoint(x: position.x + offset.x , y: position.y + offset.y))
    }
    
    func shouldShow(position: CGPoint, timestamp: Double) -> Bool {
        // remove outdated history
        positionHistory = positionHistory.filter { (_, time) -> Bool in
            let t = timestamp - time
            return t < 0.4
        }
        
        // add to history
        positionHistory.append((position, timestamp))
        
        // check
        let points = positionHistory.map{ $0.p.x } // for simplicity we just look the x-axis
        let result = checkTrace(points: points)
        if result.hit {
            print(positionHistory.count)
            positionHistory = []
        } else {
            // The history will be checked every time cursor moved. It may cost some
            // cpu resource. So we remove some necessary points.
            for i in result.redundancyIndeces.reversed() {
                positionHistory.remove(at: i)
            }
        }
        
        return result.hit
    }

    
    // Detect a shake trace for a points history
    // It will detect a Z shape trace, with 5 segments ( "Z" have 3 segments)
    //
    // - return (is a trigger trace, the redudency histories to remove)
    //      The trace algorithm only care about the break point, so it
    //      tell outside which point could be deleted.
    private func checkTrace(points: [CGFloat]) -> (hit:Bool, redundancyIndeces:Array<Int>) {
        // check
        guard points.count > 1 else { return (false, []) }
        
        var last = points.first!
        var direction: CGFloat = 0
        var terminal = last
        
        let triggerLength: CGFloat = 50
        var hits = 0
        var indecesToRemove:[Int] = []
        
        for (index, p) in points[1...].enumerated() {
            let delta = p - last
            if delta == 0 {
                continue
            }
            if direction == 0 {
                direction = delta
            } else if delta.sign != direction.sign { // have the same sign
                let new_teminal = last
                if abs(new_teminal - terminal) > triggerLength {
                    // a valid section
                    hits += 1
                    terminal = new_teminal
                    direction = delta
                }
            } else {
                indecesToRemove.append(index)
            }
            last = p
        }
        return (hits >= 4, indecesToRemove)
    }
    
    
    
    
    
    
    
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
    
    @objc func didSelectedAutoDisappear() {
        let new = !autoDisappear
        UserDefaults.standard.set(new, forKey: "autoDisappearKey")
        
        statusItem.menu?.items.first?.state = new ? .on : .off
        if new {
            self.showing = false
        }
    }
    private var autoDisappear: Bool {
        return UserDefaults.standard.object(forKey: "autoDisappearKey") as? Bool ?? true
    }
    
}


