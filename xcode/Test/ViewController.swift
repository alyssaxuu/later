//
//  ViewController.swift
//  Test
//
//  Created by Alyssa X on 1/22/22.
//

import Cocoa
import SwiftUI
import LaunchAtLogin
import HotKey

class ViewController: NSViewController {
    
    @IBOutlet var currentView: NSView!
    @IBOutlet weak var preview: NSImageView!
    @IBOutlet weak var button: NSButton!
    @IBOutlet weak var restore: NSButton!
    @IBOutlet weak var box: NSBox!
    @IBOutlet weak var dateLabel: NSTextField!
    @IBOutlet weak var sessionLabel: NSTextField!
    @IBOutlet weak var numberOfSessions: NSButton!
    @IBOutlet weak var checkbox: NSButton!
    @IBOutlet weak var ignoreFinder: NSButton!
    @IBOutlet weak var keepWindowsOpen: NSButton!
    @IBOutlet weak var waitCheckbox: NSButton!
    @IBOutlet weak var timeDropdown: NSPopUpButton!
    @IBOutlet weak var timeLabel: NSTextField!
    @IBOutlet weak var cancelTime: NSButton!
    @IBOutlet weak var timeWrapper: NSView!
    @IBOutlet weak var timeWrapperHeight: NSLayoutConstraint!
    @IBOutlet weak var closeApps: NSButton!
    var checkKey = NSMenuItem(title: "Disable all shortcuts", action: #selector(switchKey), keyEquivalent: "")
    
    
    var timer = Timer()
    var timerCount = Timer()
    let settingsMenu = NSMenu()
    var count: Double = 0.0
    
    
    @IBOutlet weak var boxHeight: NSLayoutConstraint!
    @IBOutlet weak var topBoxSpacing: NSLayoutConstraint!
    @IBOutlet weak var containerHeight: NSLayoutConstraint!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    let popoverView = NSPopover()
    
    let defaults = UserDefaults.standard
    
    private var closeKey: HotKey? {
        didSet {
            guard let closeKey = closeKey else {
                return
            }

            closeKey.keyDownHandler = { [weak self] in
                self!.saveSessionGlobal()
            }
        }
    }
    
    private var restoreKey: HotKey? {
        didSet {
            guard let restoreKey = restoreKey else {
                return
            }

            restoreKey.keyDownHandler = { [weak self] in
                self!.restoreSessionGlobal()
            }
        }
    }
    
    var observers = [NSKeyValueObservation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (LaunchAtLogin.isEnabled) {
            checkbox.state = .on
        } else {
            checkbox.state = .off
        }
        
        if (defaults.bool(forKey: "closeApps")) {
            closeApps.state = .on
        } else {
            closeApps.state = .off
        }
        
        if (defaults.bool(forKey: "ignoreSystem")) {
            ignoreFinder.state = .on
        } else {
            ignoreFinder.state = .off
        }
        
        if (defaults.bool(forKey: "keepWindowsOpen")) {
            keepWindowsOpen.state = .on
        } else {
            keepWindowsOpen.state = .off
        }
        
        if (defaults.bool(forKey: "waitCheckbox")) {
            waitCheckbox.state = .on
        } else {
            waitCheckbox.state = .off
        }
        
        if (defaults.bool(forKey: "switchKey")) {
            checkKey.state = .on
            closeKey = nil
            restoreKey = nil
        } else {
            checkKey.state = .off
            closeKey = HotKey(key: .l, modifiers: [.command, .shift])
            restoreKey = HotKey(key: .r, modifiers: [.command, .shift])
        }
        
        
        if (!defaults.bool(forKey: "session")) {
            noSessions()
        } else {
            updateSession()
        }
        
        setScreenshot()
        fixStyles()
        setUpMenu()
        
        observeModel()
    }
    
    func observeModel() {
        self.observers = [
            NSWorkspace.shared.observe(\.runningApplications, options: [.initial]) {(model, change) in
                self.checkAnyWindows()
            }
        ]
    }
    
    @objc func counter() {
        if (count >= 0) {
            count -= 1.0
            hmsFrom(seconds: Int(count)) { hours, minutes, seconds in
                let hours = self.getStringFrom(seconds: hours)
                let minutes = self.getStringFrom(seconds: minutes)
                let seconds = self.getStringFrom(seconds: seconds)
                self.timeLabel.stringValue = "Reopening in "+"\(hours):\(minutes):\(seconds)"
            }
        } else {
            timerCount.invalidate()
        }
    }
    
    // Set a timer to restore session
    func waitForSession() {
        var time: Double = 10
        if (timeDropdown.titleOfSelectedItem == "15 minutes") {
            time = 60*15
        } else if (timeDropdown.titleOfSelectedItem == "30 minutes") {
            time = 60*30
        } else if (timeDropdown.titleOfSelectedItem == "1 hour") {
            time = 60*60
        } else if (timeDropdown.titleOfSelectedItem == "5 hours") {
            time = 60*60*5
        }
        count = time
        hmsFrom(seconds: Int(count)) { hours, minutes, seconds in
            let hours = self.getStringFrom(seconds: hours)
            let minutes = self.getStringFrom(seconds: minutes)
            let seconds = self.getStringFrom(seconds: seconds)
            self.timeLabel.stringValue = "Reopening in "+"\(hours):\(minutes):\(seconds)"
        }
        timer = Timer.scheduledTimer(timeInterval: time, target: self, selector: #selector(restoreSessionGlobal), userInfo: nil, repeats: false)
        timerCount = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(counter), userInfo: nil, repeats: true)
    }
    
    func checkAnyWindows() {
        var totalSessions = 0
        for runningApplication in NSWorkspace.shared.runningApplications {
            if ((ignoreFinder.state == .on && (runningApplication.localizedName != "Finder" && runningApplication.localizedName != "Activity Monitor" && runningApplication.localizedName != "System Preferences" && runningApplication.localizedName != "App Store")) || ignoreFinder.state == .off) {
                if (runningApplication.activationPolicy == .regular) {
                    totalSessions += 1
                }
            }
        }

        if (totalSessions == 0) {
            button.isEnabled = false
        } else {
            button.isEnabled = true
        }
    }
    
    @objc func openURL() {
        let url = URL(string: "https://twitter.com/alyssaxuu")
        NSWorkspace.shared.open(url!)
    }
    
    @objc func checkForUpdates() {
        // Use Sparkle to check for updates, not relevant in this version
    }
    
    @objc func switchKey() {
        if (checkKey.state == .on) {
            checkKey.state = .off
            defaults.set(false, forKey: "switchKey")
            closeKey = HotKey(key: .l, modifiers: [.command, .shift])
            restoreKey = HotKey(key: .r, modifiers: [.command, .shift])
        } else {
            checkKey.state = .on
            defaults.set(true, forKey: "switchKey")
            restoreKey = nil
            closeKey = nil
        }
    }
    
    // Options menu
    func setUpMenu() {
        self.settingsMenu.addItem(NSMenuItem(title: "Visit website", action: #selector(openURL), keyEquivalent: ""))
        self.settingsMenu.addItem(checkKey)
        // Checking for updates, not relevant
        //self.settingsMenu.addItem(NSMenuItem(title: "Check for updates", action: #selector(checkForUpdates), keyEquivalent: ""))
        self.settingsMenu.addItem(NSMenuItem.separator())
        self.settingsMenu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "Q"))
        settingsMenu.appearance = NSAppearance.current
    }
    
    func setScreenshot() {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as NSURL
        let fileUrl = documentsUrl.appendingPathComponent("screenshot.jpg")
        preview.image = NSImage(byReferencing: fileUrl!)
        preview.wantsLayer = true
        preview.layer?.cornerRadius = 10
    }
    
    // Styling fixes / overrides
    func fixStyles() {
        button.wantsLayer = true
        button.image = NSImage(named:"blue-button")
        button.imageScaling = .scaleAxesIndependently
        button.layer?.cornerRadius = 10

        restore.wantsLayer = true
        restore.image = NSImage(named:"green-button")
        restore.imageScaling = .scaleAxesIndependently
        restore.layer?.cornerRadius = 10
        
        numberOfSessions.wantsLayer = true
        numberOfSessions.layer?.backgroundColor = #colorLiteral(red: 0.9236671925, green: 0.1403781176, blue: 0.3365081847, alpha: 1)
        numberOfSessions.layer?.cornerRadius = numberOfSessions.frame.width / 2
        numberOfSessions.layer?.masksToBounds = true
        
        if let mutableAttributedTitle = numberOfSessions.attributedTitle.mutableCopy() as? NSMutableAttributedString {
            mutableAttributedTitle.addAttribute(.foregroundColor, value: NSColor.white, range: NSRange(location: 0, length: mutableAttributedTitle.length))
            numberOfSessions.attributedTitle = mutableAttributedTitle
        }
        
        checkbox.image?.size.height = 16
        checkbox.image?.size.width = 16
        checkbox.alternateImage?.size.height = 16
        checkbox.alternateImage?.size.width = 16
        
        if let mutableAttributedTitle = checkbox.attributedTitle.mutableCopy() as? NSMutableAttributedString {
            mutableAttributedTitle.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.9136554599, green: 0.9137651324, blue: 0.9136180282, alpha: 1), range: NSRange(location: 0, length: mutableAttributedTitle.length))
            checkbox.attributedTitle = mutableAttributedTitle
        }
        
        closeApps.image?.size.height = 16
        closeApps.image?.size.width = 16
        closeApps.alternateImage?.size.height = 16
        closeApps.alternateImage?.size.width = 16
        
        if let mutableAttributedTitle = closeApps.attributedTitle.mutableCopy() as? NSMutableAttributedString {
            mutableAttributedTitle.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.9136554599, green: 0.9137651324, blue: 0.9136180282, alpha: 1), range: NSRange(location: 0, length: mutableAttributedTitle.length))
            closeApps.attributedTitle = mutableAttributedTitle
        }
        
        ignoreFinder.image?.size.height = 16
        ignoreFinder.image?.size.width = 16
        ignoreFinder.alternateImage?.size.height = 16
        ignoreFinder.alternateImage?.size.width = 16
        
        if let mutableAttributedTitle = ignoreFinder.attributedTitle.mutableCopy() as? NSMutableAttributedString {
            mutableAttributedTitle.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.9136554599, green: 0.9137651324, blue: 0.9136180282, alpha: 1), range: NSRange(location: 0, length: mutableAttributedTitle.length))
            ignoreFinder.attributedTitle = mutableAttributedTitle
        }
        
        keepWindowsOpen.image?.size.height = 16
        keepWindowsOpen.image?.size.width = 16
        keepWindowsOpen.alternateImage?.size.height = 16
        keepWindowsOpen.alternateImage?.size.width = 16
        
        if let mutableAttributedTitle = keepWindowsOpen.attributedTitle.mutableCopy() as? NSMutableAttributedString {
            mutableAttributedTitle.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.9136554599, green: 0.9137651324, blue: 0.9136180282, alpha: 1), range: NSRange(location: 0, length: mutableAttributedTitle.length))
            keepWindowsOpen.attributedTitle = mutableAttributedTitle
        }
        
        waitCheckbox.image?.size.height = 16
        waitCheckbox.image?.size.width = 16
        waitCheckbox.alternateImage?.size.height = 16
        waitCheckbox.alternateImage?.size.width = 16
        
        if let mutableAttributedTitle = waitCheckbox.attributedTitle.mutableCopy() as? NSMutableAttributedString {
            mutableAttributedTitle.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.9136554599, green: 0.9137651324, blue: 0.9136180282, alpha: 1), range: NSRange(location: 0, length: mutableAttributedTitle.length))
            waitCheckbox.attributedTitle = mutableAttributedTitle
        }
        
        timeDropdown.appearance = NSAppearance.current
        
        if let mutableAttributedTitle = cancelTime.attributedTitle.mutableCopy() as? NSMutableAttributedString {
            mutableAttributedTitle.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.155318439, green: 0.5206356049, blue: 1, alpha: 1), range: NSRange(location: 0, length: mutableAttributedTitle.length))
            cancelTime.attributedTitle = mutableAttributedTitle
        }
    }
    
    
    @IBAction func startAtLogin(_ sender: Any) {
        if (checkbox.state == .on) {
            LaunchAtLogin.isEnabled = true
        } else {
            LaunchAtLogin.isEnabled = false
        }
    }
    
    @IBAction func closeAppsCheck(_ sender: Any) {
        if (closeApps.state == .on) {
            defaults.set(true, forKey: "closeApps")
        } else {
            defaults.set(false, forKey: "closeApps")
        }
    }
    
    
    @IBAction func ignoreSystemWindows(_ sender: Any) {
        if (ignoreFinder.state == .on) {
            defaults.set(true, forKey: "ignoreSystem")
        } else {
            defaults.set(false, forKey: "ignoreSystem")
        }
    }
    
    @IBAction func keepWindowsOpen(_ sender: Any) {
        if (keepWindowsOpen.state == .on) {
            defaults.set(true, forKey: "keepWindowsOpen")
        } else {
            defaults.set(false, forKey: "keepWindowsOpen")
        }
    }
    
    @IBAction func waitCheckboxChange(_ sender: Any) {
        if (waitCheckbox.state == .on) {
            defaults.set(true, forKey: "waitCheckbox")
        } else {
            defaults.set(false, forKey: "waitCheckbox")
        }
    }
    
    // Take a screenshot of the workspace to remember how it was like
    func takeScreenshot() {
        var displayCount: UInt32 = 0;
        var result = CGGetActiveDisplayList(0, nil, &displayCount)
        if (result != CGError.success) {
            print("error: \(result)")
            return
        }
        let allocated = Int(displayCount)
        let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)
        result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)
        
        if (result != CGError.success) {
            print("error: \(result)")
            return
        }
           
        for i in 1...displayCount {
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as NSURL
            let fileUrl = documentsUrl.appendingPathComponent("screenshot.jpg")
            let screenShot:CGImage = CGDisplayCreateImage(activeDisplays[Int(i-1)])!
            let bitmapRep = NSBitmapImageRep(cgImage: screenShot)
            let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!
            
            do {
                try jpegData.write(to: fileUrl!, options: .atomic)
            }
            catch {
                print("error: \(error)")
                
            }
        }
    }
    
    func getCurrentDate() {
        let currentDateTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .medium
        defaults.set(formatter.string(from: currentDateTime), forKey: "date")
    }
    
    
    @IBAction func click(_ sender: Any) {
        saveSessionGlobal()
        button.isEnabled = false
    }
    
    @IBAction func restoreSession(_ sender: Any) {
        restoreSessionGlobal()
    }
    
    @IBAction func hideBox(_ sender: Any) {
        noSessions()
    }
    
    @IBAction func settings(_ sender: NSButton) {
        let p = NSPoint(x: sender.frame.origin.x, y: sender.frame.origin.y - (sender.frame.height / 2))
        settingsMenu.popUp(positioning: nil, at: p, in: sender.superview)
    }
    
    @IBAction func cancelTimeClick(_ sender: Any) {
        timer.invalidate()
        timerCount.invalidate()
        hideTimer()
    }
    
    func hideTimer() {
        timeWrapperHeight.constant = 0
        boxHeight.constant = 206
        timeWrapper.isHidden = true
        currentView.needsLayout = true
        currentView.updateConstraints()
    }
    
    func showTimer() {
        timeWrapperHeight.constant = 40
        boxHeight.constant = 226
        timeWrapper.isHidden = false
        currentView.needsLayout = true
        currentView.updateConstraints()
    }

    func saveSessionGlobal() {
        var array = [String]()
        var arrayNames = [String]()
        var sessionName = ""
        var sessionFull = ""
        var sessionsAdded = 1
        var sessionsRemaining = 0
        var totalSessions = 0
        var lastState = false;
        
        takeScreenshot()
        
        let runningApp = NSWorkspace.shared.frontmostApplication!
        
        NSApp.setActivationPolicy(.regular)

        for runningApplication in NSWorkspace.shared.runningApplications {
            
            // Check if the application is in the exception list
            if ((ignoreFinder.state == .on && (runningApplication.localizedName != "Finder" && runningApplication.localizedName != "Activity Monitor" && runningApplication.localizedName != "System Preferences" && runningApplication.localizedName != "App Store")) || ignoreFinder.state == .off) {
                
                // Ignore itself + only affect regular applications
                if (runningApplication.activationPolicy == .regular && runningApplication.localizedName != "Later" && runningApplication != runningApp) {
                    array.append(runningApplication.executableURL!.absoluteString)
                    arrayNames.append(runningApplication.localizedName!)
                    
                    // Only close if "keep windows open" checkbox is disabled
                    if (keepWindowsOpen.state == .off) {
                        runningApplication.hide()
                    } else {
                        if (runningApplication.localizedName != "Finder") {
                            runningApplication.terminate()
                        }
                        lastState = true;
                    }
                    
                    // Get application names for session label
                    if (sessionName == "") {
                        sessionName = runningApplication.localizedName!
                        sessionFull = runningApplication.localizedName!
                    } else if (sessionsAdded <= 3) {
                        sessionName += ", "+runningApplication.localizedName!
                    } else {
                        sessionsRemaining += 1
                    }
                    sessionFull += ", "+runningApplication.localizedName!
                    sessionsAdded += 1
                    totalSessions += 1
                }
            }
        }
        
        if ((ignoreFinder.state == .on && (runningApp.localizedName != "Finder" && runningApp.localizedName != "Activity Monitor" && runningApp.localizedName != "System Preferences" && runningApp.localizedName != "App Store")) || ignoreFinder.state == .off) {
            if (runningApp.activationPolicy == .regular && runningApp.localizedName != "Later") {
                array.append(runningApp.executableURL!.absoluteString)
                arrayNames.append(runningApp.localizedName!)
                
                // Only close if "keep windows open" checkbox is disabled
                if (keepWindowsOpen.state == .off) {
                    runningApp.hide()
                } else {
                    if (runningApp.localizedName != "Finder") {
                        runningApp.terminate()
                    }
                    lastState = true;
                }
                // Get application names for session label
                if (sessionName == "") {
                    sessionName = runningApp.localizedName!
                    sessionFull = runningApp.localizedName!
                } else if (sessionsAdded <= 3) {
                    sessionName += ", "+runningApp.localizedName!
                } else {
                    sessionsRemaining += 1
                }
                sessionFull += ", "+runningApp.localizedName!
                sessionsAdded += 1
                totalSessions += 1
            }
        }
        
        if (sessionsRemaining > 0) {
            sessionName += ", +"+String(sessionsRemaining)+" more"
        }
        
        NSApp.setActivationPolicy(.accessory)
        
        // Save session data
        defaults.set(lastState, forKey:"lastState")
        defaults.set(array, forKey: "apps")
        defaults.set(arrayNames, forKey: "appNames")
        defaults.set(sessionName, forKey: "sessionName")
        defaults.set(sessionFull, forKey: "sessionFullName")
        defaults.set(String(totalSessions), forKey: "totalSessions")
        getCurrentDate()
        updateSession()
        if (waitCheckbox.state == .on) {
            waitForSession()
        }
        
        let appDelegate = NSApp.delegate as! AppDelegate
        appDelegate.closePopover(self)
    }
    
    func activate(name: String, url:String) {
        guard let app = NSWorkspace.shared.runningApplications.filter ({
            return $0.localizedName == name
        }).first else {
            do {
                let task = Process()
                task.executableURL = URL.init(string:url)
                try task.run()
            } catch {
                print("Error")
            }
            return
        }

        app.unhide()
    }
    
    @objc func restoreSessionGlobal() {
        
        // Check if apps are to be terminated as opposed to hiding them
        if (closeApps.state == .on) {
            for runningApplication in NSWorkspace.shared.runningApplications {
                if ((ignoreFinder.state == .on && (runningApplication.localizedName != "Finder" && runningApplication.localizedName != "Activity Monitor" && runningApplication.localizedName != "System Preferences" && runningApplication.localizedName != "App Store")) || ignoreFinder.state == .off) {
                    if (runningApplication.activationPolicy == .regular && runningApplication.localizedName != "Terminal") {
                        runningApplication.terminate()
                    }
                }
            }
        }
        
        // Restore apps
        if let apps = defaults.object(forKey: "appNames") as? [String] {
            if let executables = defaults.object(forKey: "apps") as? [String] {
                for (index, app) in apps.enumerated() {
                    activate(name:app, url:executables[index])
                }
                noSessions()
            }
        }
        
        let appDelegate = NSApp.delegate as! AppDelegate
        appDelegate.closePopover(self)
    }
    
    // No sessions popover state
    func noSessions() {
        defaults.set(false, forKey:"session")
        boxHeight.constant = 0
        topBoxSpacing.constant = 0
        containerHeight.constant = 290
        currentView.needsLayout = true
        currentView.updateConstraints()
        fixStyles()
        checkAnyWindows()
    }
    
    func hmsFrom(seconds: Int, completion: @escaping (_ hours: Int, _ minutes: Int, _ seconds: Int)->()) {
        completion(seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }

    func getStringFrom(seconds: Int) -> String {
        return seconds < 10 ? "0\(seconds)" : "\(seconds)"
    }
    
    // New session or override
    func updateSession() {
        defaults.set(true, forKey:"session")
        if let dateString = defaults.string(forKey: "date") {
            dateLabel.stringValue = dateString
            dateLabel.lineBreakMode = .byTruncatingTail
        }
        if let sessionName = defaults.string(forKey: "sessionName") {
            sessionLabel.stringValue = sessionName
            sessionLabel.lineBreakMode = .byTruncatingTail
            if let sessionFullName = defaults.string(forKey: "sessionFullName") {
                sessionLabel.toolTip = sessionFullName
            }
        }
        if let totalSessions = defaults.string(forKey: "totalSessions") {
            numberOfSessions.title = totalSessions
        }
        if (waitCheckbox.state == .on) {
            showTimer()
        } else {
            hideTimer()
        }
        fixStyles()
        setScreenshot()
        topBoxSpacing.constant = 16
        containerHeight.constant = 520
        currentView.needsLayout = true
        currentView.updateConstraints()
        checkAnyWindows()
    }
    
}
