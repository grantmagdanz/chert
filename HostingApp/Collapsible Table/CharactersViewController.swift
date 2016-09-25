//
//  CollapsibleTableViewController.swift
//  ios-swift-collapsible-table-section
//
//  Created by Yong Su on 5/30/16.
//  Copyright © 2016 Yong Su. All rights reserved.
//

import UIKit

extension UIView {
    func rotate(toValue: CGFloat, duration: CFTimeInterval = 0.2, completionDelegate: AnyObject? = nil) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.toValue = toValue
        rotateAnimation.duration = duration
        rotateAnimation.removedOnCompletion = false
        rotateAnimation.fillMode = kCAFillModeForwards
        
        if let delegate: AnyObject = completionDelegate {
            rotateAnimation.delegate = delegate
        }
        self.layer.addAnimation(rotateAnimation, forKey: nil)
    }
}

class CharactersViewController: UITableViewController {
    //
    // MARK: - Data
    //
    struct Section {
        var name: String! {
            get {
                if collapsed! {
                    return "▹  \(language)"
                } else {
                    return "▿  \(language)"
                }
            }
        }
        var language: String!
        var items: [String]!
        var collapsed: Bool!
        
        init(language: String, items: [String], collapsed: Bool = true) {
            self.language = language
            self.items = items
            self.collapsed = collapsed
        }
    }
    
    var sections = [Section]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize the sections array
        sections = []
        let names = Languages.getNames()
        
        for language in Languages.getLanguages() {
            let keyBindings = Languages.getCharSet(language)
            var items = [String]()
            items = []
            
            // build up the extra characters
            for (var base, extra) in keyBindings {
                if base as! String == "___" {
                    // This is for accents
                    base = "Tone Marks"
                } else if base as! String == "√" {
                    base = "\(base)  (press '123' then '#+=')"
                } else {
                    base = base.lowercaseString
                }
                
                var item = "\(base): "
                
                for char in extra as! NSArray {
                    item = item + "\(convertAccents(char as! String).lowercaseString), "
                }
                
                // Fixing fencepost problem by dropping the last space and comma.
                items.append(item.substringToIndex(item.endIndex.predecessor().predecessor()))
            }

            // Letters should be displayed in alphabetical order
            items = items.sort {
                /* The apostrophe should come second to last followed by tone marks.
                 * With Lingit, since the ∅ is not a letter, it should come at the end but
                 * before the tone marks
                 */
                if ($0.hasPrefix("Tone Marks") && $1.hasPrefix("'")) || ($0.hasPrefix("'") && $1.hasPrefix("Tone Marks")) {
                    return true
                } else if $0.hasPrefix("Tone Marks") || $0.hasPrefix("'") {
                    return false
                } else if $1.hasPrefix("Tone Marks") || $1.hasPrefix("'") {
                    return true
                } else if language == Languages.Lingit {
                    if $0.hasPrefix("o") && !$1.hasPrefix("√"){
                        return false
                    } else if $1.hasPrefix("o") && !$0.hasPrefix("√") {
                        return true
                    }
                }
                
                return $0 < $1
            }
            
            sections.append(Section(language: names[language]!, items: items))
        }
        
        tableView.backgroundColor = UIColor.clearColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
    
    private func convertAccents(input: String) -> String {
        var letter = input
        if input.uppercaseString == "ACUTE" {
            letter = "\u{25cc}\u{0301}"
        } else if input.uppercaseString == "CIRCUMFLEX" {
            letter = "\u{25cc}\u{0302}"
        } else if input.uppercaseString == "GRAVE" {
            letter = "\u{25cc}\u{0300}"
        } else if input.uppercaseString == "CARON" {
            letter = "\u{25cc}\u{030C}"
        }
        return letter
    }
    
    //
    // MARK: - UITableViewDelegate
    //
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (sections[section].collapsed!) ? 0 : sections[section].items.count
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableCellWithIdentifier("header") as! CollapsibleTableViewHeader
        
        header.toggleButton.tag = section
        header.titleLabel.text = sections[section].name
        header.toggleButton.rotate(sections[section].collapsed! ? 0.0 : CGFloat(M_PI_2))
        header.toggleButton.addTarget(self, action: #selector(CharactersViewController.toggleCollapse), forControlEvents: .TouchUpInside)
        
        return header.contentView
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell!
        
        cell.textLabel?.text = sections[indexPath.section].items[indexPath.row]
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: NSInteger) -> CGFloat {
        // height of the header rows in the table
        return 40.0
    }
    
    //
    // MARK: - Event Handlers
    //
    func toggleCollapse(sender: UIButton) {
        let section = sender.tag
        let collapsed = sections[section].collapsed
        
        // Toggle collapse
        sections[section].collapsed = !collapsed
        
        // Reload section
        tableView.reloadSections(NSIndexSet(index: section), withRowAnimation: .Automatic)
    }
    
}