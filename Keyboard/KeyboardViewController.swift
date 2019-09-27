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

        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardViewController.hideExpandView(_:)), name: NSNotification.Name(rawValue: "hideExpandViewNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardViewController.defaultsChanged(_:)), name: UserDefaults.didChangeNotification, object: nil)
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

            let a = NSLayoutConstraint(item: kludge, attribute: NSLayoutConstraint.Attribute.left, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0)
            let b = NSLayoutConstraint(item: kludge, attribute: NSLayoutConstraint.Attribute.right, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.left, multiplier: 1, constant: 0)
            let c = NSLayoutConstraint(item: kludge, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
            let d = NSLayoutConstraint(item: kludge, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1, constant: 0)
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
            self.updateCapsIfNeeded()

            self.updateAppearances(self.darkMode())
            self.addInputTraitsObservers()

            self.constraintsAdded = true
        }
    }

    // only available after frame becomes non-zero
    func darkMode() -> Bool {
        let darkMode = { () -> Bool in
            let proxy = self.textDocumentProxy
            return proxy.keyboardAppearance == UIKeyboardAppearance.dark
        }()

        return darkMode
    }

    func solidColorMode() -> Bool {
        return UIAccessibility.isReduceTransparencyEnabled
    }

    func isPortrait() -> Bool
    {
        let size = UIScreen.main.bounds.size
        if size.width > size.height {
            //print("Landscape: \(size.width) X \(size.height)")
            return false
        } else {
            //print("Portrait: \(size.width) X \(size.height)")
            return true
        }
    }

    var lastLayoutBounds: CGRect?
    override func viewDidLayoutSubviews() {
        if view.bounds == CGRect.zero {
            return
        }

        self.setupLayout()

        let orientationSavvyBounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.height(orientationIsPortrait: self.isPortrait(), withTopBanner: false))

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
        self.keyboardHeight = self.height(orientationIsPortrait: self.isPortrait(), withTopBanner: true)
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

        self.keyboardHeight = self.height(orientationIsPortrait: self.isPortrait(), withTopBanner: true)
    }

    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        // optimization: ensures quick mode and shift transitions
        if let keyPool = self.layout?.keyPool {
            for view in keyPool {
                view.shouldRasterize = false
            }
        }
    }

    func height(orientationIsPortrait isPortrait: Bool, withTopBanner: Bool) -> CGFloat {
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad

        // AB: consider re-enabling this when interfaceOrientation actually breaks
        //// HACK: Detecting orientation manually
        //let screenSize: CGSize = UIScreen.main.bounds.size
        //let orientation: UIInterfaceOrientation = screenSize.width < screenSize.height ? .portrait : .landscapeLeft

        //TODO: hardcoded stuff
        let actualScreenWidth = (UIScreen.main.nativeBounds.size.width / UIScreen.main.nativeScale)
        let canonicalPortraitHeight: CGFloat
        let canonicalLandscapeHeight: CGFloat
        if isPad {
            canonicalPortraitHeight = 264
            canonicalLandscapeHeight = 352
        }
        else {
            canonicalPortraitHeight = isPortrait && actualScreenWidth >= 400 ? 226 : 216
            canonicalLandscapeHeight = 162
        }

        let topBannerHeight = (withTopBanner ? metric("topBanner") : 0)

        return CGFloat(isPortrait ? canonicalPortraitHeight + topBannerHeight : canonicalLandscapeHeight + topBannerHeight)
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

            self.updateCapsIfNeeded()

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
                        keyView.removeTarget(nil, action: nil, for: UIControl.Event.allEvents)

                        switch key.type {
                        case Key.KeyType.keyboardChange:
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.advanceTapped(_:)),
                                              for: .touchUpInside)
                        case Key.KeyType.backspace:
                            let cancelEvents: UIControl.Event = [UIControl.Event.touchUpInside, UIControl.Event.touchUpInside, UIControl.Event.touchDragExit, UIControl.Event.touchUpOutside, UIControl.Event.touchCancel, UIControl.Event.touchDragOutside]

                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.backspaceDown(_:)),
                                              for: .touchDown)
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.backspaceUp(_:)),
                                              for: cancelEvents)
                        case Key.KeyType.shift:
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.shiftDown(_:)),
                                              for: .touchDown)
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.shiftUp(_:)),
                                              for: .touchUpInside)
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.shiftDoubleTapped(_:)),
                                              for: .touchDownRepeat)
                        case Key.KeyType.modeChange:
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.modeChangeTapped(_:)),
                                              for: .touchDown)
                        case Key.KeyType.settings:
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.toggleSettings),
                                              for: .touchUpInside)
                        default:
                            break
                        }

                        if key.isCharacter {
                            if UIDevice.current.userInterfaceIdiom != UIUserInterfaceIdiom.pad {
                                keyView.addTarget(self,
                                                  action: #selector(KeyboardViewController.showPopup(_:)),
                                                  for: [.touchDown, .touchDragInside, .touchDragEnter])
                                keyView.addTarget(keyView,
                                                  action: #selector(KeyboardKey.hidePopup),
                                                  for: [.touchDragExit, .touchCancel])
                                keyView.addTarget(self,
                                                  action: #selector(KeyboardViewController.hidePopupDelay(_:)),
                                                  for: [.touchUpInside, .touchUpOutside, .touchDragOutside])
                            }

                            keyView.addTarget(self, action: Selector("keyCharDoubleTapped:"), for: .touchDownRepeat)
                        }

                        if key.hasOutput {
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.keyPressedHelper(_:)),
                                              for: .touchUpInside)
                        }

                        if key.type != Key.KeyType.shift && key.type != Key.KeyType.modeChange {
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.highlightKey(_:)),
                                              for: [.touchDown, .touchDragInside, .touchDragEnter])
                            keyView.addTarget(self,
                                              action: #selector(KeyboardViewController.unHighlightKey(_:)),
                                              for: [.touchUpInside, .touchUpOutside, .touchDragOutside, .touchDragExit, .touchCancel])
                        }

                        keyView.addTarget(self,
                                          action: #selector(KeyboardViewController.playKeySound),
                                          for: .touchDown)
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

    @objc func showPopup(_ sender: KeyboardKey) {
        if sender == self.keyWithDelayedPopup {
            self.popupDelayTimer?.invalidate()
        }
        sender.showPopup()
    }

    @objc func hidePopupDelay(_ sender: KeyboardKey) {
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
        self.updateCapsIfNeeded()
        self.autoPeriodState = .noSpace
    }

    func setHeight(_ height: CGFloat) {
        if self.heightConstraint == nil {
            self.heightConstraint = NSLayoutConstraint(
                item:self.view!,
                attribute:NSLayoutConstraint.Attribute.height,
                relatedBy:NSLayoutConstraint.Relation.equal,
                toItem:nil,
                attribute:NSLayoutConstraint.Attribute.notAnAttribute,
                multiplier:0,
                constant:height)
            self.heightConstraint!.priority = UILayoutPriority(rawValue: 1000)

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

    @objc func highlightKey(_ sender: KeyboardKey) {
        sender.isHighlighted = true
    }

    @objc func unHighlightKey(_ sender: KeyboardKey) {
        sender.isHighlighted = false
    }

    @objc func keyPressedHelper(_ sender: KeyboardKey) {
        if let model = self.layout?.keyForView(sender) {
            self.keyPressed(model)

            // auto exit from special char subkeyboard
            if model.type == Key.KeyType.space || model.type == Key.KeyType.return {
                self.currentMode = 0
            }
            else if model.lowercaseOutput == "'" {
                self.currentMode = 0
            }
            else if model.type == Key.KeyType.character {
                self.currentMode = 0
            }

            // auto period on double space
            // TODO: timeout

            self.handleAutoPeriod(model)
            // TODO: reset context
        }

        self.updateCapsIfNeeded()
    }

    func handleAutoPeriod(_ key: Key) {
        if !UserDefaults.standard.bool(forKey: kPeriodShortcut) {
            return
        }

        if self.autoPeriodState == .firstSpace {
            if key.type != Key.KeyType.space {
                self.autoPeriodState = .noSpace
                return
            }

            let charactersAreInCorrectState = { () -> Bool in
                let previousContext = self.textDocumentProxy.documentContextBeforeInput

                if previousContext == nil || (previousContext!).count < 3 {
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
            if key.type == Key.KeyType.space {
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

    @objc func backspaceDown(_ sender: KeyboardKey) {
        self.cancelBackspaceTimers()

        self.textDocumentProxy.deleteBackward()
        self.updateCapsIfNeeded()

        // trigger for subsequent deletes
        self.backspaceDelayTimer = Timer.scheduledTimer(timeInterval: backspaceDelay - backspaceRepeat, target: self, selector: #selector(KeyboardViewController.backspaceDelayCallback), userInfo: nil, repeats: false)
    }

    @objc func backspaceUp(_ sender: KeyboardKey) {
        self.cancelBackspaceTimers()
    }

    @objc func backspaceDelayCallback() {
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = Timer.scheduledTimer(timeInterval: backspaceRepeat, target: self, selector: #selector(KeyboardViewController.backspaceRepeatCallback), userInfo: nil, repeats: true)
    }

    @objc func backspaceRepeatCallback() {
        self.playKeySound()

        self.textDocumentProxy.deleteBackward()
        self.updateCapsIfNeeded()
    }

    @objc func shiftDown(_ sender: KeyboardKey) {
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

    @objc func shiftUp(_ sender: KeyboardKey) {
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

    @objc func shiftDoubleTapped(_ sender: KeyboardKey) {
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

    @objc func modeChangeTapped(_ sender: KeyboardKey) {
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

    @objc func advanceTapped(_ sender: KeyboardKey) {
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

                let widthConstraint = NSLayoutConstraint(item: aSettings, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0)
                let heightConstraint = NSLayoutConstraint(item: aSettings, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 0)
                let centerXConstraint = NSLayoutConstraint(item: aSettings, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
                let centerYConstraint = NSLayoutConstraint(item: aSettings, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)

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

    func updateCapsIfNeeded() {
        if self.shouldAutoCapitalize() {
            switch self.shiftState {
            case .disabled:
                self.shiftState = .enabled
            case .enabled:
                self.shiftState = .enabled
            case .locked:
                self.shiftState = .locked
            }
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
            for char in (string!) {
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

        let traits = self.textDocumentProxy
        if let autocapitalization = traits.autocapitalizationType {
            let documentProxy = self.textDocumentProxy
            //var beforeContext = documentProxy.documentContextBeforeInput

            switch autocapitalization {
            case .none:
                return false
            case .words:
                if let beforeContext = documentProxy.documentContextBeforeInput {
                    let previousCharacter = beforeContext[beforeContext.index(before: beforeContext.endIndex)]
                    return self.characterIsWhitespace(previousCharacter)
                }
                else {
                    return true
                }

            case .sentences:
                if let beforeContext = documentProxy.documentContextBeforeInput {
                    let offset = min(3, beforeContext.count)
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
            @unknown default:
                return false
            }
        }
        else {
            return false
        }
    }

    // this only works if full access is enabled
    @objc func playKeySound() {
        if !UserDefaults.standard.bool(forKey: kKeyboardClicks) {
            return
        }

        DispatchQueue.global(qos: .default).async(execute: {
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
                    if arrOptions[0].count > 0 {
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
                        self.view.bringSubviewToFront(self.viewLongPopUp)
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
        self.textDocumentProxy.insertText(key.outputForCase(self.shiftState.uppercase()))
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
        settingsView.backButton?.addTarget(self, action: #selector(KeyboardViewController.toggleSettings), for: UIControl.Event.touchUpInside)
        return settingsView
    }
}
