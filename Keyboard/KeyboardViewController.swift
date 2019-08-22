//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Updated by Grant Magdanz on 9/24/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

import UIKit
import AudioToolbox

enum TTDeviceType{
    case ttDeviceTypeIPhone4
    case ttDeviceTypeIPhone5
    case ttDeviceTypeIPhone6
    case ttDeviceTypeIPhone6p
    
}

var deviceType = TTDeviceType.ttDeviceTypeIPhone5

let metrics: [String:Double] = [
    "topBanner": 30
]
func metric(_ name: String) -> CGFloat { return CGFloat(metrics[name]!) }

class KeyboardViewController: UIInputViewController {
    
    let backspaceDelay: TimeInterval = 0.5
    let backspaceRepeat: TimeInterval = 0.07
    
    var keyboard: Keyboard!
    var forwardingView: ForwardingView!
    var layout: KeyboardLayout?
    var heightConstraint: NSLayoutConstraint?
    
    var bannerView: ExtraView?
    var settingsView: ExtraView?
    
    var viewLongPopUp:CYRKeyboardButtonView = CYRKeyboardButtonView()
    var button = CYRKeyboardButton()
    
    var currentMode: Int {
        didSet {
            if oldValue != currentMode {
                setMode(currentMode)
            }
            
            forwardingView.currentMode = currentMode
        }
    }
    
    var backspaceActive: Bool {
        get {
            return (backspaceDelayTimer != nil) || (backspaceRepeatTimer != nil)
        }
    }
    var backspaceDelayTimer: Timer?
    var backspaceRepeatTimer: Timer?
    
    enum AutoPeriodState {
        case noSpace
        case firstSpace
    }
    
    var autoPeriodState: AutoPeriodState = .noSpace
    var lastCharCountInBeforeContext: Int = 0
    
    var shiftState: ShiftState {
        didSet {
            switch shiftState {
            case .disabled:
                self.updateKeyCaps(false)
            case .enabled:
                self.updateKeyCaps(true)
            case .locked:
                self.updateKeyCaps(true)
            }
        }
    }
    
    // state tracking during shift tap
    var shiftWasMultitapped: Bool = false
    var shiftStartingState: ShiftState?
    
    var keyboardHeight: CGFloat {
        get {
            if let constraint = self.heightConstraint {
                return constraint.constant
            }
            else {
                return 0
            }
        }
        set {
            self.setHeight(newValue)
        }
    }
    
    // TODO: why does the app crash if this isn't here?
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        // set setting defaults
        var defaults = [
            kAutoCapitalization: true,
            kPeriodShortcut: true,
            kKeyboardClicks: true,
            kSmallLowercase: true
        ]
        
        // all languages should be on by default
        for language in Languages.getLanguages() {
            defaults[language] = true
        }
        
        UserDefaults.standard.register(defaults: defaults)
        
        self.keyboard = buildKeyboard()
        
        self.shiftState = .disabled
        self.currentMode = 0
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.forwardingView = ForwardingView(frame: CGRect.zero)
        self.view.addSubview(self.forwardingView)
        
        initializePopUp()
        
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardViewController.defaultsChanged(_:)), name: UserDefaults.didChangeNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardViewController.hideExpandView(_:)), name: NSNotification.Name(rawValue: "hideExpandViewNotification"), object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    deinit {
        backspaceDelayTimer?.invalidate()
        backspaceRepeatTimer?.invalidate()
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func defaultsChanged(_ notification: Notification) {
        self.updateKeyboard()
        self.updateKeyCaps(self.shiftState.uppercase())
    }
    
    // without this here kludge, the height constraint for the keyboard does not work for some reason
    var kludge: UIView?
    func setupKludge() {
        if self.kludge == nil {
            let kludge = UIView()
            self.view.addSubview(kludge)
            kludge.translatesAutoresizingMaskIntoConstraints = false
            kludge.isHidden = true
            
            let a = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
            let b = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
            let c = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
            let d = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
            self.view.addConstraints([a, b, c, d])
            
            self.kludge = kludge
        }
    }
    
    /*
    BUG NOTE

    For some strange reason, a layout pass of the entire keyboard is triggered 
    whenever a popup shows up, if one of the following is done:

    a) The forwarding view uses an autoresizing mask.
    b) The forwarding view has constraints set anywhere other than init.

    On the other hand, setting (non-autoresizing) constraints or just setting the
    frame in layoutSubviews works perfectly fine.

    I don't really know what to make of this. Am I doing Autolayout wrong, is it
    a bug, or is it expected behavior? Perhaps this has to do with the fact that
    the view's frame is only ever explicitly modified when set directly in layoutSubviews,
    and not implicitly modified by various Autolayout constraints
    (even though it should really not be changing).
    */
    
    var constraintsAdded: Bool = false
    func setupLayout() {
        if !constraintsAdded {
            self.layout = type(of: self).layoutClass.init(model: self.keyboard, superview: self.forwardingView, layoutConstants: type(of: self).layoutConstants, globalColors: type(of: self).globalColors, darkMode: self.darkMode(), solidColorMode: self.solidColorMode())
            
            self.layout?.initialize()
            self.setMode(0)
            
            self.setupKludge()
            
            self.updateKeyCaps(self.shiftState.uppercase())
            self.setCapsIfNeeded()
            
            self.updateAppearances(self.darkMode())
            self.addInputTraitsObservers()
            
            self.constraintsAdded = true
        }
    }
    
    // only available after frame becomes non-zero
    func darkMode() -> Bool {
        let darkMode = { () -> Bool in
            return textDocumentProxy.keyboardAppearance == UIKeyboardAppearance.dark
        }()
        
        return darkMode
    }
    
    func solidColorMode() -> Bool {
        return UIAccessibilityIsReduceTransparencyEnabled()
    }
    
    var lastLayoutBounds: CGRect?
    override func viewDidLayoutSubviews() {
        if view.bounds == CGRect.zero {
            return
        }
        
        self.setupLayout()
        
        let orientationSavvyBounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.heightForOrientation(self.interfaceOrientation, withTopBanner: false))
        
        if (lastLayoutBounds != nil && lastLayoutBounds == orientationSavvyBounds) {
            // do nothing
        }
        else {
            let uppercase = self.shiftState.uppercase()
            let characterUppercase = (UserDefaults.standard.bool(forKey: kSmallLowercase) ? uppercase : true)
            
            self.forwardingView.frame = orientationSavvyBounds
            self.layout?.layoutKeys(self.currentMode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
            self.lastLayoutBounds = orientationSavvyBounds
            self.setupKeys()
        }
        
        self.bannerView?.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: metric("topBanner"))
        
        let newOrigin = CGPoint(x: 0, y: self.view.bounds.height - self.forwardingView.bounds.height)
        self.forwardingView.frame.origin = newOrigin
    }
    
    override func loadView() {
        super.loadView()
        
        if let aBanner = self.createBanner() {
            aBanner.isHidden = true
            self.view.insertSubview(aBanner, belowSubview: self.forwardingView)
            self.bannerView = aBanner
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.bannerView?.isHidden = false
        self.keyboardHeight = self.heightForOrientation(self.interfaceOrientation, withTopBanner: true)
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        // optimization: ensures smooth animation
        if let keyPool = self.layout?.keyPool {
            for view in keyPool {
                view.shouldRasterize = true
            }
        }
        
        self.keyboardHeight = self.heightForOrientation(toInterfaceOrientation, withTopBanner: true)
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        // optimization: ensures quick mode and shift transitions
        if let keyPool = self.layout?.keyPool {
            for view in keyPool {
                view.shouldRasterize = false
            }
        }
    }
    
    func heightForOrientation(_ orientation: UIInterfaceOrientation, withTopBanner: Bool) -> CGFloat {
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        
        //TODO: hardcoded stuff
        let actualScreenWidth = (UIScreen.main.nativeBounds.size.width / UIScreen.main.nativeScale)
        let canonicalPortraitHeight = (isPad ? CGFloat(264) : CGFloat(orientation.isPortrait && actualScreenWidth >= 400 ? 226 : 216))
        let canonicalLandscapeHeight = (isPad ? CGFloat(352) : CGFloat(162))
        let topBannerHeight = (withTopBanner ? metric("topBanner") : 0)
        
        return CGFloat(orientation.isPortrait ? canonicalPortraitHeight + topBannerHeight : canonicalLandscapeHeight + topBannerHeight)
    }
    
    @objc func hideExpandView(_ notification: Notification)
    {
        
        if (notification as NSNotification).userInfo != nil
        {
            let title = (notification as NSNotification).userInfo!["text"] as! String
            if let proxy = (self.textDocumentProxy as? UIKeyInput)
            {
                if self.shiftState == .enabled
                {
                    proxy.insertText(title.capitalized)
                }
                else if self.shiftState == .locked
                {
                    proxy.insertText(title.uppercased())
                }
                else
                {
                    proxy.insertText(title.lowercased())
                }
                
            }
            
            self.setCapsIfNeeded()
            
        }
        
        viewLongPopUp.isHidden = true
        
    }
    
    /*
    BUG NOTE

    None of the UIContentContainer methods are called for this controller.
    */
    
    //override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    //    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    //}
    
    func setupKeys() {
        if self.layout == nil {
            return
        }
        
        for page in keyboard.pages {
            for rowKeys in page.rows { // TODO: quick hack
                for key in rowKeys {
                    if let keyView = self.layout?.viewForKey(key) {
                        keyView.removeTarget(nil, action: nil, for: UIControlEvents.allEvents)
                        
                        switch key.type {
                        case Key.KeyType.KeyboardChange:
                            keyView.addTarget(self, action: "advanceTapped:", for: .touchUpInside)
                        case Key.KeyType.Backspace:
                            let cancelEvents: UIControlEvents = [UIControlEvents.touchUpInside, UIControlEvents.touchUpInside, UIControlEvents.touchDragExit, UIControlEvents.touchUpOutside, UIControlEvents.touchCancel, UIControlEvents.touchDragOutside]
                            
                            keyView.addTarget(self, action: "backspaceDown:", for: .touchDown)
                            keyView.addTarget(self, action: "backspaceUp:", for: cancelEvents)
                        case Key.KeyType.Shift:
                            keyView.addTarget(self, action: Selector("shiftDown:"), for: .touchDown)
                            keyView.addTarget(self, action: Selector("shiftUp:"), for: .touchUpInside)
                            keyView.addTarget(self, action: Selector("shiftDoubleTapped:"), for: .touchDownRepeat)
                        case
                        Key.KeyType.LetterChange,
                        Key.KeyType.NumberChange,
                        Key.KeyType.SpecialCharacterChange:
                            keyView.addTarget(self, action: Selector("modeChangeTapped:"), for: .touchDown)
                        case Key.KeyType.Settings:
                            keyView.addTarget(self, action: Selector("toggleSettings"), for: .touchUpInside)
                        default:
                            break
                        }
                        
                        if key.isCharacter {
                            if UIDevice.current.userInterfaceIdiom != UIUserInterfaceIdiom.pad {
                                keyView.addTarget(self, action: Selector("showPopup:"), for: [.touchDown, .touchDragInside, .touchDragEnter])
                                keyView.addTarget(keyView, action: Selector("hidePopup"), for: [.touchDragExit, .touchCancel])
                                keyView.addTarget(self, action: Selector("hidePopupDelay:"), for: [.touchUpInside, .touchUpOutside, .touchDragOutside])
                            }
                            
                            keyView.addTarget(self, action: Selector("keyCharDoubleTapped:"), for: .touchDownRepeat)
                        }
                        
                        if key.hasOutput {
                            keyView.addTarget(self, action: "keyPressedHelper:", for: .touchUpInside)
                        }
                        
                        if key.type != Key.KeyType.Shift && key.type != Key.KeyType.LetterChange &&
                                       key.type != Key.KeyType.NumberChange && key.type != Key.KeyType.SpecialCharacterChange {
                            keyView.addTarget(self, action: Selector("highlightKey:"), for: [.touchDown, .touchDragInside, .touchDragEnter])
                            keyView.addTarget(self, action: Selector("unHighlightKey:"), for: [.touchUpInside, .touchUpOutside, .touchDragOutside, .touchDragExit, .touchCancel])
                        }
                        
                        keyView.addTarget(self, action: Selector("playKeySound"), for: .touchDown)
                    }
                }
            }
        }
    }
    
    /////////////////
    // POPUP DELAY //
    /////////////////
    
    var keyWithDelayedPopup: KeyboardKey?
    var popupDelayTimer: Timer?
    
    func showPopup(_ sender: KeyboardKey) {
        if sender == self.keyWithDelayedPopup {
            self.popupDelayTimer?.invalidate()
        }
        sender.showPopup()
    }
    
    func hidePopupDelay(_ sender: KeyboardKey) {
        self.popupDelayTimer?.invalidate()
        
        if sender != self.keyWithDelayedPopup {
            self.keyWithDelayedPopup?.hidePopup()
            self.keyWithDelayedPopup = sender
        }
        
        if sender.popup != nil {
            self.popupDelayTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(KeyboardViewController.hidePopupCallback), userInfo: nil, repeats: false)
        }
    }
    
    @objc func hidePopupCallback() {
        self.keyWithDelayedPopup?.hidePopup()
        self.keyWithDelayedPopup = nil
        self.popupDelayTimer = nil
    }
    
    /////////////////////
    // POPUP DELAY END //
    /////////////////////
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }

    // TODO: this is currently not working as intended; only called when selection changed -- iOS bug
    override func textDidChange(_ textInput: UITextInput?) {
        self.contextChanged()
    }
    
    func contextChanged() {
        self.setCapsIfNeeded()
        self.autoPeriodState = .noSpace
    }
    
    func setHeight(_ height: CGFloat) {
        if self.heightConstraint == nil {
            self.heightConstraint = NSLayoutConstraint(
                item:self.view,
                attribute:NSLayoutAttribute.height,
                relatedBy:NSLayoutRelation.equal,
                toItem:nil,
                attribute:NSLayoutAttribute.notAnAttribute,
                multiplier:0,
                constant:height)
            self.heightConstraint!.priority = UILayoutPriority(rawValue: 999)
            
            self.view.addConstraint(self.heightConstraint!) // TODO: what if view already has constraint added?
        }
        else {
            self.heightConstraint?.constant = height
        }
    }
    
    func updateAppearances(_ appearanceIsDark: Bool) {
        self.layout?.solidColorMode = self.solidColorMode()
        self.layout?.darkMode = appearanceIsDark
        self.layout?.updateKeyAppearance()
        
        self.bannerView?.darkMode = appearanceIsDark
        self.settingsView?.darkMode = appearanceIsDark
    }
    
    func highlightKey(_ sender: KeyboardKey) {
        sender.isHighlighted = true
    }
    
    func unHighlightKey(_ sender: KeyboardKey) {
        sender.isHighlighted = false
    }
    
    func keyPressedHelper(_ sender: KeyboardKey) {
        if let model = self.layout?.keyForView(sender) {
            self.keyPressed(model)

            // auto exit from special char subkeyboard
            if model.type == Key.KeyType.Space || model.type == Key.KeyType.Return {
                self.currentMode = 0
            }
            else if model.lowercaseOutput == "'" {
                self.currentMode = 0
            }
            else if model.type == Key.KeyType.Character {
                self.currentMode = 0
            }
            
            // auto period on double space
            // TODO: timeout
            
            self.handleAutoPeriod(model)
            // TODO: reset context
        }
        
        self.setCapsIfNeeded()
    }
    
    func handleAutoPeriod(_ key: Key) {
        if !UserDefaults.standard.bool(forKey: kPeriodShortcut) {
            return
        }
        
        if self.autoPeriodState == .firstSpace {
            if key.type != Key.KeyType.Space {
                self.autoPeriodState = .noSpace
                return
            }
            
            let charactersAreInCorrectState = { () -> Bool in
                let previousContext = self.textDocumentProxy.documentContextBeforeInput
                
                if previousContext == nil || (previousContext!).characters.count < 3 {
                    return false
                }
                
                var index = previousContext!.endIndex
                
                index = previousContext!.index(before: index)
                if previousContext![index] != " " {
                    return false
                }
                
                index = previousContext!.index(before: index)
                if previousContext![index] != " " {
                    return false
                }
                
                index = previousContext!.index(before: index)
                let char = previousContext![index]
                if self.characterIsWhitespace(char) || self.characterIsPunctuation(char) || char == "," {
                    return false
                }
                
                return true
            }()
            
            if charactersAreInCorrectState {
                self.textDocumentProxy.deleteBackward()
                self.textDocumentProxy.deleteBackward()
                self.textDocumentProxy.insertText(".")
                self.textDocumentProxy.insertText(" ")
            }
            
            self.autoPeriodState = .noSpace
        }
        else {
            if key.type == Key.KeyType.Space {
                self.autoPeriodState = .firstSpace
            }
        }
    }
    
    func cancelBackspaceTimers() {
        self.backspaceDelayTimer?.invalidate()
        self.backspaceRepeatTimer?.invalidate()
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = nil
    }
    
    func backspaceDown(_ sender: KeyboardKey) {
        cancelBackspaceTimers()

        let textDocumentProxy = self.textDocumentProxy
        let context = textDocumentProxy.documentContextBeforeInput
        if context != nil && context!.count > 1 {
            // if the character to delete is a new line character, we need
            // to delete the empty space character as well.
            let index = context!.index(before: context!.endIndex)
            if context![index] == "\n" {
                textDocumentProxy.deleteBackward()
            }
        }
        textDocumentProxy.deleteBackward()
        
        setCapsIfNeeded()
        
        // trigger for subsequent deletes
        backspaceDelayTimer = Timer.scheduledTimer(timeInterval: backspaceDelay - backspaceRepeat,
            target: self, selector: #selector(KeyboardViewController.backspaceDelayCallback), userInfo: nil, repeats: false)
    }
    
    func backspaceUp(_ sender: KeyboardKey) {
        self.cancelBackspaceTimers()
    }
    
    @objc func backspaceDelayCallback() {
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = Timer.scheduledTimer(timeInterval: backspaceRepeat, target: self, selector: #selector(KeyboardViewController.backspaceRepeatCallback), userInfo: nil, repeats: true)
    }
    
    @objc func backspaceRepeatCallback() {
        playKeySound()
        
        let textDocumentProxy = self.textDocumentProxy
        let context = textDocumentProxy.documentContextBeforeInput
        if context != nil && context!.count > 1 {
            // if the character to delete is a new line character, we need
            // to delete the empty space character as well.
            let index = context!.index(before: context!.endIndex)
            if context![index] == "\n" {
                textDocumentProxy.deleteBackward()
            }
        }
        textDocumentProxy.deleteBackward()
        setCapsIfNeeded()
    }
    
    func shiftDown(_ sender: KeyboardKey) {
        self.shiftStartingState = self.shiftState
        
        if let shiftStartingState = self.shiftStartingState {
            if shiftStartingState.uppercase() {
                // handled by shiftUp
                return
            }
            else {
                switch self.shiftState {
                case .disabled:
                    self.shiftState = .enabled
                case .enabled:
                    self.shiftState = .disabled
                case .locked:
                    self.shiftState = .disabled
                }
                
                (sender.shape as? ShiftShape)?.withLock = false
            }
        }
    }
    
    func shiftUp(_ sender: KeyboardKey) {
        if self.shiftWasMultitapped {
            // do nothing
        }
        else {
            if let shiftStartingState = self.shiftStartingState {
                if !shiftStartingState.uppercase() {
                    // handled by shiftDown
                }
                else {
                    switch self.shiftState {
                    case .disabled:
                        self.shiftState = .enabled
                    case .enabled:
                        self.shiftState = .disabled
                    case .locked:
                        self.shiftState = .disabled
                    }
                    
                    (sender.shape as? ShiftShape)?.withLock = false
                }
            }
        }

        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
    }
    
    func shiftDoubleTapped(_ sender: KeyboardKey) {
        self.shiftWasMultitapped = true
        
        switch self.shiftState {
        case .disabled:
            self.shiftState = .locked
        case .enabled:
            self.shiftState = .locked
        case .locked:
            self.shiftState = .disabled
        }
    }
    
    func updateKeyCaps(_ uppercase: Bool) {
        let characterUppercase = (UserDefaults.standard.bool(forKey: kSmallLowercase) ? uppercase : true)
        self.layout?.updateKeyCaps(false, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
    }
    
    func updateKeyboard() {
        // this function is sometimes called at the very beginning of loading the keyboard when the layout is null. We don't want to crash, so we'll just get out.
        if self.layout == nil {
            return
        }
        self.keyboard = buildKeyboard()
        self.layout!.model = self.keyboard
        self.forwardingView.setLongHoldKeys(self.keyboard.getLongHoldKeys())
        
        let uppercase = self.shiftState.uppercase()
        let characterUppercase = (UserDefaults.standard.bool(forKey: kSmallLowercase) ? uppercase : true)
        self.layout?.layoutKeys(self.currentMode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
        self.setupKeys()
    }
    
    func modeChangeTapped(_ sender: KeyboardKey) {
        if let toMode = self.layout?.viewToModel[sender]?.toMode {
            self.currentMode = toMode
        }
    }
    
    func setMode(_ mode: Int) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        let uppercase = self.shiftState.uppercase()
        let characterUppercase = (UserDefaults.standard.bool(forKey: kSmallLowercase) ? uppercase : true)
        self.layout?.layoutKeys(mode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
        
        self.setupKeys()
    }
    
    func advanceTapped(_ sender: KeyboardKey) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        self.advanceToNextInputMode()
    }
    
    @IBAction func toggleSettings() {
        // lazy load settings
        if self.settingsView == nil {
            if let aSettings = self.createSettings() {
                aSettings.darkMode = self.darkMode()
                
                aSettings.isHidden = true
                self.view.addSubview(aSettings)
                self.settingsView = aSettings
                
                aSettings.translatesAutoresizingMaskIntoConstraints = false
                
                let widthConstraint = NSLayoutConstraint(item: aSettings, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.width, multiplier: 1, constant: 0)
                let heightConstraint = NSLayoutConstraint(item: aSettings, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.height, multiplier: 1, constant: 0)
                let centerXConstraint = NSLayoutConstraint(item: aSettings, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerX, multiplier: 1, constant: 0)
                let centerYConstraint = NSLayoutConstraint(item: aSettings, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerY, multiplier: 1, constant: 0)
                
                self.view.addConstraint(widthConstraint)
                self.view.addConstraint(heightConstraint)
                self.view.addConstraint(centerXConstraint)
                self.view.addConstraint(centerYConstraint)
            }
        }
        
        if let settings = self.settingsView {
            let hidden = settings.isHidden
            settings.isHidden = !hidden
            self.forwardingView.isHidden = hidden
            self.forwardingView.isUserInteractionEnabled = !hidden
            self.bannerView?.isHidden = hidden
        }
    }
    
    func setCapsIfNeeded() -> Bool {
        if self.shouldAutoCapitalize() {
            switch self.shiftState {
            case .disabled:
                self.shiftState = .enabled
            case .enabled:
                self.shiftState = .enabled
            case .locked:
                self.shiftState = .locked
            }
            
            return true
        }
        else {
            switch self.shiftState {
            case .disabled:
                self.shiftState = .disabled
            case .enabled:
                self.shiftState = .disabled
            case .locked:
                self.shiftState = .locked
            }
            
            return false
        }
    }
    
    func characterIsPunctuation(_ character: Character) -> Bool {
        return (character == ".") || (character == "!") || (character == "?")
    }
    
    func characterIsNewline(_ character: Character) -> Bool {
        return (character == "\n") || (character == "\r")
    }
    
    func characterIsWhitespace(_ character: Character) -> Bool {
        // there are others, but who cares
        return (character == " ") || (character == "\n") || (character == "\r") || (character == "\t")
    }
    
    func stringIsWhitespace(_ string: String?) -> Bool {
        if string != nil {
            for char in (string!).characters {
                if !characterIsWhitespace(char) {
                    return false
                }
            }
        }
        return true
    }
    
    func shouldAutoCapitalize() -> Bool {
        if !UserDefaults.standard.bool(forKey: kAutoCapitalization) {
            return false
        }
        
        if let autocapitalization = textDocumentProxy.autocapitalizationType {
            
            switch autocapitalization {
            case .none:
                return false
            case .words:
                if let beforeContext = textDocumentProxy.documentContextBeforeInput {
                    let previousCharacter = beforeContext[beforeContext.characters.index(before: beforeContext.endIndex)]
                    return self.characterIsWhitespace(previousCharacter)
                }
                else {
                    return true
                }
                
            case .sentences:
                if let beforeContext = textDocumentProxy.documentContextBeforeInput {
                    let offset = min(3, beforeContext.characters.count)
                    var index = beforeContext.endIndex
                    
                    for i in 0 ..< offset {
                        index = beforeContext.index(before: index)
                        let char = beforeContext[index]
                        
                        if characterIsPunctuation(char) {
                            if i == 0 {
                                return false //not enough spaces after punctuation
                            }
                            else {
                                return true //punctuation with at least one space after it
                            }
                        }
                        else {
                            if !characterIsWhitespace(char) {
                                return false //hit a foreign character before getting to 3 spaces
                            }
                            else if characterIsNewline(char) {
                                return true //hit start of line
                            }
                        }
                    }
                    
                    return true //either got 3 spaces or hit start of line
                }
                else {
                    return true
                }
            case .allCharacters:
                return true
            }
        }
        else {
            return false
        }
    }
    
    // this only works if full access is enabled
    func playKeySound() {
        if !UserDefaults.standard.bool(forKey: kKeyboardClicks) {
            return
        }
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: {
            AudioServicesPlaySystemSound(1104)
        })
    }
    
    // setups long pressed popup keys
    func initializePopUp() {
        button.isHidden = true
        button.forwordingView = forwardingView
        button.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        button.tag = 111
        self.view.insertSubview(self.button, aboveSubview: self.forwardingView)
        button.setupInputOptionsConfiguration(with: forwardingView)
        button.isHidden = true
        viewLongPopUp.isHidden = true
        
        forwardingView.setLongHoldKeys(keyboard.getLongHoldKeys())
    }
    
    // called when a key that is allowed to have multiple characters is pressed and held
    // shows multiple options
    func keyCharDoubleTapped(_ sender: KeyboardKey) {
        if sender.tag == 888 {
            sender.hidePopup()
            if let key = self.layout?.keyForView(sender) {
                var arrOptions: [String] = []
                if (key.isCharacter) {
                    if self.shiftState == .locked {
                        // convert all letters to uppercase
                        arrOptions = key.extraCharacters.map(
                            { (letter: String) -> String in
                                return (letter as NSString).uppercased})
                    } else if self.shiftState == .enabled || !UserDefaults.standard.bool(forKey: kSmallLowercase) {
                        // capitalize the String
                        arrOptions = key.extraCharacters.map {(letter: String) -> String in
                            // ∅ is used in Tlingit, but not as a letter. It should always
                            // be capitalized.
                            if letter == "∅" {
                                return "∅".uppercased()
                            } else {
                                return (letter as NSString).capitalized
                            }
                        }
                    } else {
                        // convert to lowercase
                        arrOptions = key.extraCharacters.map { (letter: String) -> String in
                            // ∅ is used in Tlingit, but not as a letter. It should always
                            // be capitalized.
                            if letter == "∅" {
                                return "∅".uppercased()
                            } else {
                                return (letter as NSString).lowercased
                            }
                        }
                    }
                }
                
                if arrOptions.count > 1 { // this test isn't really necessary as the fowarding view is filtering letters
                    if arrOptions[0].characters.count > 0 {
                        var offsetY : CGFloat = 9
                        
                        if KeyboardViewController.getDeviceType() == TTDeviceType.ttDeviceTypeIPhone4 {
                            offsetY = 9
                            if self.interfaceOrientation == UIInterfaceOrientation.landscapeLeft || self.interfaceOrientation == UIInterfaceOrientation.landscapeRight {
                                offsetY = 3
                            }
                        } else if KeyboardViewController.getDeviceType() == TTDeviceType.ttDeviceTypeIPhone5 {
                            offsetY = 9
                            if self.interfaceOrientation == UIInterfaceOrientation.landscapeLeft || self.interfaceOrientation == UIInterfaceOrientation.landscapeRight {
                                offsetY = 3
                            }
                            
                        } else if KeyboardViewController.getDeviceType() == TTDeviceType.ttDeviceTypeIPhone6 {
                            offsetY = 13
                            if self.interfaceOrientation == UIInterfaceOrientation.landscapeLeft || self.interfaceOrientation == UIInterfaceOrientation.landscapeRight {
                                offsetY = 3
                            }
                            
                        } else if KeyboardViewController.getDeviceType() == TTDeviceType.ttDeviceTypeIPhone6p {
                            offsetY = 16
                            if self.interfaceOrientation == UIInterfaceOrientation.landscapeLeft || self.interfaceOrientation == UIInterfaceOrientation.landscapeRight {
                                offsetY = 3
                            }
                        }
                        
                        self.button.removeFromSuperview()
                        
                        self.button.frame = CGRect(x: sender.frame.origin.x, y: sender.frame.origin.y + sender.frame.size.height - offsetY, width: sender.frame.size.width, height: sender.frame.size.height)
                        
                        //					self.button.frame = CGRectMake(sender.frame.origin.x, sender.frame.origin.y , sender.frame.size.width, sender.frame.size.height)
                        
                        self.view.insertSubview(self.button, aboveSubview: self.forwardingView)
                        
                        self.viewLongPopUp = self.button.showLongPopUpOptions()
                        self.button.input = sender.text
                        self.button.isHidden = true
                        self.button.inputOptions = arrOptions
                        self.viewLongPopUp.isHidden = false
                        
                        for anyView in self.view.subviews {
                            if anyView is CYRKeyboardButtonView {
                                anyView.removeFromSuperview()
                            }
                        }
                        
                        self.viewLongPopUp.isUserInteractionEnabled = false;
                        
                        button.setupInputOptionsConfiguration(with: forwardingView)
                        self.view.insertSubview(self.viewLongPopUp, aboveSubview: self.forwardingView)
                        self.forwardingView.isLongPressEnable = true
                        self.view.bringSubview(toFront: self.viewLongPopUp)
                        //self.forwardingView.resetTrackedViews()
                        //sender.hidePopup()
                        //self.view.addSubview(self.viewLongPopUp)
                        
                        sender.tag = 0
                    }
                }
            }
        }
    }
    
    // returns the device type
    class func getDeviceType()->TTDeviceType {
        var height = UIScreen.main.bounds.size.height
        
        if UIScreen.main.bounds.size.height < UIScreen.main.bounds.size.width {
            height = UIScreen.main.bounds.size.width
        }
        
        switch (height) {
        case 480:
            deviceType = TTDeviceType.ttDeviceTypeIPhone4 ;
            break;
            
        case 568:
            deviceType = TTDeviceType.ttDeviceTypeIPhone5 ;
            break;
        case 667:
            deviceType = TTDeviceType.ttDeviceTypeIPhone6 ;
            break;
        case 736:
            deviceType = TTDeviceType.ttDeviceTypeIPhone6p ;
            break;
            
        default:
            break;
        }
        
        return deviceType
        
    }
    
    //////////////////////////////////////
    // MOST COMMONLY EXTENDABLE METHODS //
    //////////////////////////////////////
    
    class var layoutClass: KeyboardLayout.Type { get { return KeyboardLayout.self }}
    class var layoutConstants: LayoutConstants.Type { get { return LayoutConstants.self }}
    class var globalColors: GlobalColors.Type { get { return GlobalColors.self }}
    
    func keyPressed(_ key: Key) {
        textDocumentProxy.insertText(key.outputForCase(self.shiftState.uppercase()))
    }
    
    // a banner that sits in the empty space on top of the keyboard
    func createBanner() -> ExtraView? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        //return ExtraView(globalColors: self.dynamicType.globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        return nil
    }
    
    // a settings view that replaces the keyboard when the settings button is pressed
    func createSettings() -> ExtraView? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        let settingsView = DefaultSettings(globalColors: type(of: self).globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        settingsView.backButton?.addTarget(self, action: #selector(KeyboardViewController.toggleSettings), for: UIControlEvents.touchUpInside)
        return settingsView
    }
}
