//
//  Banner.swift
//  InupiaqKeyboard
//
//  Created by Grant Magdanz on 9/24/15.
//  Copyright (c) 2015 Apple. All rights reserved.
//

import UIKit

class Banner: ExtraView {
    var icon: UIImage = UIImage(named: "banner")!
    var iconView: UIImageView
    var textView = UILabel(frame: CGRect(x: 0, y: 0, width: 120, height: 40))
    
    required init(globalColors: GlobalColors.Type?, darkMode: Bool, solidColorMode: Bool) {
        iconView = UIImageView(image: icon)
        // TODO: hard coded values
        iconView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        iconView.layer.cornerRadius = 6
        iconView.clipsToBounds = true
        
        // uncomment to add text on the banner of the keyboard
        // textView.text = "  Add text."
        textView.alpha = 0.3
        textView.font = UIFont.italicSystemFont(ofSize: 16.0)
        
        super.init(globalColors: globalColors, darkMode: darkMode, solidColorMode: solidColorMode)
        self.addSubview(iconView)
        self.addSubview(textView)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setNeedsLayout() {
        super.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.iconView.center = self.center
        // TODO: hardcoded
        self.iconView.frame.origin = CGPoint(x: self.iconView.frame.origin.x, y: 5)
    }
}
