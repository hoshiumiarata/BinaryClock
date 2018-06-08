import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSTabViewDelegate {
    @IBOutlet weak var popover: NSPopover!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var timer : Timer? = nil
    
    @IBOutlet weak var time: NSTextField!

    @IBOutlet weak var tabView: NSTabView!
    
    @IBOutlet weak var activeIntensity: NSSlider!
    @IBOutlet weak var inactiveIntensity: NSSlider!
    
    @IBOutlet weak var showSeconds: NSButton!
    
    @IBOutlet weak var activeColor: NSColorWell!
    @IBOutlet weak var inactiveColor: NSColorWell!
    
    override init()
    {
        NSUserDefaultsController.shared.initialValues = [
            "active_color" : NSArchiver.archivedData(withRootObject: NSColor(red: 0.0, green: 0.0, blue: 0.25, alpha: 1.0)),
            "inactive_color" : NSArchiver.archivedData(withRootObject: NSColor(red: 0.75, green: 0.75, blue: 1.0, alpha: 1.0))
        ]
    }
    
    func applicationDidFinishLaunching(_ notification: Notification)
    {
        createTimer()
        statusItem.button?.action = #selector(AppDelegate.statusItemClick)
        
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown], handler: {
            (e : NSEvent) in
            if self.popover.isShown
            {
                self.popover.close()
            }
        })
    }
    
    @objc func statusItemClick()
    {
        popover.show(relativeTo: NSRect(), of: statusItem.button!, preferredEdge: .maxY)
    }
    
    func applicationWillTerminate(_ notification: Notification)
    {
        NSStatusBar.system.removeStatusItem(statusItem)
    }
    
    func createTimer()
    {
        timer?.invalidate()
        timer = Timer(timeInterval: showSeconds.state == .on ? 1.0 : 60.0, target: self, selector: #selector(AppDelegate.timer(_:)), userInfo: nil, repeats: true)
        RunLoop.current.add(timer!, forMode: .defaultRunLoopMode)
        timer?.fire()
    }
    
    @objc func timer(_ timer: Timer)
    {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        if showSeconds.state == .on
        {
            formatter.timeStyle = .medium
        }
        time.stringValue = formatter.string(from: Date())
        
        updateImage()
    }
    
    func updateImage()
    {
        statusItem.button?.image = generateImage()
    }
    
    func generateImage() -> NSImage
    {
        let colored = tabView.indexOfTabViewItem(tabView.selectedTabViewItem!) == 1
        
        let height = NSStatusBar.system.thickness - 2
        let width = showSeconds.state == .on ? height * 3.0 / 2.0 : height
        
        let size = NSMakeSize(width, height)
        
        let img = NSImage(size: size)
        
        img.isTemplate = !colored
        
        img.lockFocus()
        
        let x_count = showSeconds.state == .on ? 6 : 4
        let time = getCurrentTime()
        for i in 0..<x_count
        {
            let y_count = 4
            let excess = {
                () -> Int in
                switch i {
                case 0: return 2
                case 2, 4: return 1
                default: return 0
                }
            }()
            let digit = {
                () -> Int in
                switch i {
                case 0: return time.hours / 10
                case 1: return time.hours % 10
                case 2: return time.minutes / 10
                case 3: return time.minutes % 10
                case 4: return time.seconds / 10
                case 5: return time.seconds % 10
                default: return 0
                }
            }()
            let hex = digitToHex(digit)
            for j in 0..<y_count - excess
            {
                let space_x = height / 10.0
                let space_y = space_x
                let w : CGFloat = (width + space_x) / CGFloat(x_count)
                let h : CGFloat = (height + space_y) / CGFloat(y_count)
                let color : NSColor
                if colored
                {
                    color = hex[j] ? activeColor.color : inactiveColor.color
                }
                else
                {
                    let intensitySlider = hex[j] ? activeIntensity : inactiveIntensity
                    color = NSColor(white: 0.0, alpha: CGFloat(intensitySlider!.doubleValue / intensitySlider!.maxValue))
                }
                color.setFill()
                NSBezierPath.fill(NSRect(x: w * CGFloat(i), y: h * CGFloat(j), width: w - space_x, height: h - space_y))
            }
        }
        
        img.unlockFocus()
        return img
    }
    
    func getCurrentTime() -> (hours : Int, minutes : Int, seconds : Int)
    {
        let components = NSCalendar.current.dateComponents([.hour, .minute, .second], from: Date())
        return (components.hour!, components.minute!, components.second!)
    }
    
    func digitToHex(_ digit : Int) -> [Bool]
    {
        return [digit & 1 != 0, digit & 2 != 0, digit & 4 != 0, digit & 8 != 0]
    }
    
    @IBAction func updateClock(_ sender: AnyObject)
    {
        createTimer()
    }
    
    func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?)
    {
        updateClock(tabView)
    }
}
