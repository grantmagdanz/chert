//
//  ForwardingView.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/19/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

class ForwardingView: UIView,UIGestureRecognizerDelegate {
    fileprivate var longHoldKeys: Set<String> = Set<String>();

    var touchToView: [UITouch:UIView] = [:]

	var gesture = UILongPressGestureRecognizer()

	var isLongPressEnable = false
	var isLongPressKeyPress = false

	var currentMode: Int = 0
	var keyboard_type: UIKeyboardType?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentMode = UIView.ContentMode.redraw
        self.isMultipleTouchEnabled = true
        self.isUserInteractionEnabled = true
        self.isOpaque = false

		gesture = UILongPressGestureRecognizer(target: self, action: #selector(ForwardingView.handleLongGesture(_:)))

		gesture.minimumPressDuration = 0.5
		gesture.delegate = self
		gesture.cancelsTouchesInView = false
		self.addGestureRecognizer(gesture)

    }

    required init?(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    // Why have this useless drawRect? Well, if we just set the backgroundColor to clearColor,
    // then some weird optimization happens on UIKit's side where tapping down on a transparent pixel will
    // not actually recognize the touch. Having a manual drawRect fixes this behavior, even though it doesn't
    // actually do anything.
    override func draw(_ rect: CGRect) {}

    override func hitTest(_ point: CGPoint, with event: UIEvent!) -> UIView? {
        if self.isHidden || self.alpha == 0 || !self.isUserInteractionEnabled {
            return nil
        }
        else {
            return (self.bounds.contains(point) ? self : nil)
        }
    }

    func handleControl(_ view: UIView?, controlEvent: UIControl.Event) {
        if let control = view as? UIControl {
            let targets = control.allTargets
            for target in targets {
                if let actions = control.actions(forTarget: target, forControlEvent: controlEvent) {
                    for action in actions {
                        let selectorString = action
                        let selector = Selector(selectorString)
                        control.sendAction(selector, to: target, for: nil)
                    }

                }
            }
        }
    }

	@IBAction func handleLongGesture(_ longPress: UIGestureRecognizer)
	{
		if (longPress.state == UIGestureRecognizer.State.ended)
		{
			//println("Ended")

			let position = longPress.location(in: self)
			let view = findNearestView(position)

			if view is KeyboardKey
			{
				NotificationCenter.default.post(name: Notification.Name(rawValue: "hideExpandViewNotification"), object: nil)
			}

			isLongPressEnable = false

			isLongPressKeyPress = true

			if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
			{
				let keyboardKey = view as! KeyboardKey
				keyboardKey.isHighlighted = false
			}


		}
		else if (longPress.state == UIGestureRecognizer.State.began)
		{
			if (longPress.state == UIGestureRecognizer.State.began)
			{
				//println("Began")

				isLongPressEnable = true

				let position = longPress.location(in: self)
				let view = findNearestView(position)

				let viewChangedOwnership = false

				if !viewChangedOwnership {

					if view is KeyboardKey
					{
						let v = view as! KeyboardKey
						if self.isLongPressEnableKey(v.text as NSString)
						{
							view!.tag = 888

							self.handleControl(view, controlEvent: .touchDownRepeat)
						}

					}
				}
			}
		}
	}


	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool
	{
		if gestureRecognizer is UILongPressGestureRecognizer
		{
			if (gestureRecognizer.state == UIGestureRecognizer.State.possible)
			{
				let position = touch.location(in: self)
				let view = findNearestView(position)

				let viewChangedOwnership = false

				if !viewChangedOwnership {

					if view is KeyboardKey
					{
						let v = view as! KeyboardKey
						if self.isLongPressEnableKey(v.text as NSString)
						{
							return true
						}
					}
				}
				return false
			}
			else if (gestureRecognizer.state == UIGestureRecognizer.State.ended)
			{
				let position = gestureRecognizer.location(in: self)
				let view = findNearestView(position)

				let viewChangedOwnership = false

				if !viewChangedOwnership {

					if view is KeyboardKey
					{
						let v = view as! KeyboardKey
						if self.isLongPressEnableKey(v.text as NSString)
						{
							return true
						}
					}
				}
				return false
			}
		}
		else
		{
			return true
		}
		return false
	}

	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
	{
		return true
	}

    // TODO: there's a bit of "stickiness" to Apple's implementation
    func findNearestView(_ position: CGPoint) -> UIView? {
        if !self.bounds.contains(position) {
            return nil
        }

        var closest: (UIView, CGFloat)? = nil

        for anyView in self.subviews {
            let view = anyView
            if view.isHidden {
                continue
            }

            view.alpha = 1

            let distance = distanceBetween(view.frame, point: position)

            if closest != nil {
                if distance < closest!.1 {
                    closest = (view, distance)
                }
            }
            else {
                closest = (view, distance)
            }
        }

        if closest != nil {
            return closest!.0
        }
        else {
            return nil
        }
    }

    // http://stackoverflow.com/questions/3552108/finding-closest-object-to-cgpoint b/c I'm lazy
    func distanceBetween(_ rect: CGRect, point: CGPoint) -> CGFloat {
        if rect.contains(point) {
            return 0
        }

        var closest = rect.origin

        if (rect.origin.x + rect.size.width < point.x) {
            closest.x += rect.size.width
        }
        else if (point.x > rect.origin.x) {
            closest.x = point.x
        }
        if (rect.origin.y + rect.size.height < point.y) {
            closest.y += rect.size.height
        }
        else if (point.y > rect.origin.y) {
            closest.y = point.y
        }

        let a = pow(Double(closest.y - point.y), 2)
        let b = pow(Double(closest.x - point.x), 2)
        return CGFloat(sqrt(a + b));
    }

    // reset tracked views without cancelling current touch
    func resetTrackedViews() {
        for view in self.touchToView.values {
            self.handleControl(view, controlEvent: .touchCancel)
        }
        self.touchToView.removeAll(keepingCapacity: true)
    }

	func resetPopUpViews() {
		for view in self.touchToView.values {

			let v = view as! KeyboardKey
			v.hidePopup()
		}
	}

    func ownView(_ newTouch: UITouch, viewToOwn: UIView?) -> Bool {
        var foundView = false

        if viewToOwn != nil {
            for (touch, view) in self.touchToView {
                if viewToOwn == view {
                    if touch == newTouch {
                        break
                    }
                    else {
                        self.touchToView[touch] = nil
                        foundView = true
                    }
                    break
                }
            }
        }

        self.touchToView[newTouch] = viewToOwn
        return foundView
    }

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		// println("touchesBegan")
		for touch in touches {
			let position = touch.location(in: self)
			let view = findNearestView(position)

			let viewChangedOwnership = self.ownView(touch, viewToOwn: view)

			if(isLongPressEnable == true)
			{
				if let _ = view
				{
					if !viewChangedOwnership
					{
						self.handleControl(view, controlEvent: .touchDown)
						//self.touchToView[touch] = nil
					}
				}

				NotificationCenter.default.post(name: Notification.Name(rawValue: "hideExpandViewNotification"), object: nil)
				isLongPressEnable = false

				if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
				{
					let keyboardKey = view as! KeyboardKey
					keyboardKey.isHighlighted = false
				}

			}
			else
			{
				if !viewChangedOwnership {
					self.handleControl(view, controlEvent: .touchDown)

					if touch.tapCount > 1 {
						// two events, I think this is the correct behavior but I have not tested with an actual UIControl
						self.handleControl(view, controlEvent: .touchDownRepeat)
					}
				}
			}

		}
	}

	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		//println("touchesMoved")
		for touch in touches
		{
            let position = touch.location(in: self)

			if(isLongPressEnable)
			{
				let expandedButtonView : CYRKeyboardButtonView! = self.getCYRView()

				if expandedButtonView != nil
				{
					expandedButtonView.updateSelectedInputIndex(for: position)
				}
			}
			else
			{
				let oldView = self.touchToView[touch]
				let newView = findNearestView(position)

				if oldView != newView
				{
					self.handleControl(oldView, controlEvent: .touchDragExit)

					let viewChangedOwnership = self.ownView(touch, viewToOwn: newView)

					if !viewChangedOwnership
					{
						self.handleControl(newView, controlEvent: .touchDragEnter)
					}
					else
					{
						self.handleControl(newView, controlEvent: .touchDragInside)
					}
				}
				else
				{
					self.handleControl(oldView, controlEvent: .touchDragInside)
				}
			}
		}
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		for touch in touches {
			let view = self.touchToView[touch]

			let touchPosition = touch.location(in: self)

			if(isLongPressKeyPress == true)
			{
				let expandedButtonView : CYRKeyboardButtonView! = self.getCYRView()
				if (expandedButtonView.selectedInputIndex != NSNotFound)
				{
					let inputOption = self.getCYRButton().inputOptions[expandedButtonView.selectedInputIndex] as! String

					self.resetPopUpViews()

					NotificationCenter.default.post(name: Notification.Name(rawValue: "hideExpandViewNotification"), object: nil, userInfo: ["text":inputOption])

				}

				isLongPressKeyPress = false

				if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
				{
					let keyboardKey = view as! KeyboardKey
					keyboardKey.isHighlighted = false
				}

			}
			else
			{
				if self.bounds.contains(touchPosition)
				{
					self.handleControl(view, controlEvent: .touchUpInside)
				}
				else
				{
					self.handleControl(view, controlEvent: .touchCancel)
				}

				//self.touchToView[touch] = nil
			}

			self.touchToView[touch] = nil
		}
	}

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let view = self.touchToView[touch]
            
            self.handleControl(view, controlEvent: .touchCancel)
            
            self.touchToView[touch] = nil
        }
    }

	func isLongPressEnableKey(_ text:NSString) -> Bool
	{
		let alphabet_lengh = text.length

		if(alphabet_lengh > 1)
		{
			return false
		}

		if longHoldKeys.contains(text.lowercased)
		{
            if(keyboard_type == UIKeyboardType.decimalPad || keyboard_type == UIKeyboardType.numberPad)
            {
                return false
            }

            return true
		}

		return false
	}

    func setLongHoldKeys(_ keys: Set<String>) {
        self.longHoldKeys = Set<String>()
        for key in keys {
            self.longHoldKeys.insert(key.lowercased())
        }
    }

	func isSubViewContainsCYRView() -> Bool
	{
		for anyView in self.superview!.subviews
		{
			if anyView is CYRKeyboardButtonView
			{
				return true
			}
		}
		return false
	}

	func getCYRView() -> CYRKeyboardButtonView!
	{
		if isSubViewContainsCYRView()
		{
			for anyView in self.superview!.subviews
			{
				if anyView is CYRKeyboardButtonView
				{
					return anyView as! CYRKeyboardButtonView
				}
			}
		}

		return nil
	}

	func isSubViewContainsCYRButton() -> Bool
	{
		for anyView in self.superview!.subviews
		{
			if anyView is CYRKeyboardButton
			{
				return true
			}
		}
		return false
	}

	func getCYRButton() -> CYRKeyboardButton!
	{
		if isSubViewContainsCYRButton()
		{
			for anyView in self.superview!.subviews
			{
				if anyView is CYRKeyboardButton
				{
					return anyView as! CYRKeyboardButton
				}
			}
		}

		return nil
	}

}
