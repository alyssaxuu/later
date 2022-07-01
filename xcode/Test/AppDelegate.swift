//
//  AppDelegate.swift
//  Later
//
//  Created by Alyssa X on 1/22/22.
//

import Cocoa
import SwiftUI
import LaunchAtLogin


@main
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength: 20)
    let popoverView = NSPopover()
    var eventMonitor: EventMonitor?
    let defaults = UserDefaults.standard
     
    func runApp() {
        statusItem.button?.image = NSImage(named: NSImage.Name("icon"))
        statusItem.button?.target = self
        statusItem.button?.action = #selector(AppDelegate.togglePopover(_:))
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let vc = storyboard.instantiateController(withIdentifier: "ViewController1") as? ViewController else {
            fatalError("Unable to find ViewController")
        }
        popoverView.contentViewController = vc
        popoverView.behavior = .transient
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [unowned self] event in
            if popoverView.isShown {
                closePopover(event)
            }
        }
        eventMonitor?.start()
    }


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        runApp();
        
        LaunchAtLogin.isEnabled = true
        defaults.set(true, forKey: "ignoreSystem")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if popoverView.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    func showPopover(_ sender: AnyObject?) {
        popoverView.animates = true
        if let button = statusItem.button {
            popoverView.backgroundColor = #colorLiteral(red: 0.1490048468, green: 0.1490279436, blue: 0.1489969194, alpha: 1)
            popoverView.appearance = NSAppearance(named: .aqua)
            popoverView.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
        eventMonitor?.start()
    }
    
    func closePopover(_ sender: AnyObject?) {
        popoverView.performClose(sender)
        eventMonitor?.stop()
    }
    
    
}

extension NSPopover {
    
    private struct Keys {
        static var backgroundViewKey = "backgroundKey"
    }
    
    private var backgroundView: NSView {
        let bgView = objc_getAssociatedObject(self, &Keys.backgroundViewKey) as? NSView
        if let view = bgView {
            return view
        }
        
        let view = NSView()
        objc_setAssociatedObject(self, &Keys.backgroundViewKey, view, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        NotificationCenter.default.addObserver(self, selector: #selector(popoverWillOpen(_:)), name: NSPopover.willShowNotification, object: nil)
        return view
    }
    
    @objc private func popoverWillOpen(_ notification: Notification) {
        if backgroundView.superview == nil {
            if let contentView = contentViewController?.view, let frameView = contentView.superview {
                frameView.wantsLayer = true
                backgroundView.frame = NSInsetRect(frameView.frame, 1, 1)
                backgroundView.autoresizingMask = [.width, .height]
                frameView.addSubview(backgroundView, positioned: .below, relativeTo: contentView)
            }
        }
    }
    
    var backgroundColor: NSColor? {
        get {
            if let bgColor = backgroundView.layer?.backgroundColor {
                return NSColor(cgColor: bgColor)
            }
            return nil
        }
        set {
            backgroundView.wantsLayer = true
            backgroundView.layer?.backgroundColor = newValue?.cgColor
            backgroundView.layer?.borderColor = newValue?.cgColor
        }
    }
}
