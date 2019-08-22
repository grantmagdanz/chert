//
//  CollapsibleTableViewController.swift
//  ios-swift-collapsible-table-section
//
//  Created by Yong Su on 5/30/16.
//  Copyright © 2016 Yong Su. All rights reserved.
//

import UIKit

extension UIView {
    func rotate(_ toValue: CGFloat, duration: CFTimeInterval = 0.2, completionDelegate: AnyObject? = nil) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.toValue = toValue
        rotateAnimation.duration = duration
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.fillMode = CAMediaTimingFillMode.forwards
        
        if let delegate = completionDelegate as? CAAnimationDelegate {
            rotateAnimation.delegate = delegate
        }
        self.layer.add(rotateAnimation, forKey: nil)
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
        var language: String
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
            for (baseChar, extra) in keyBindings {
                var base = baseChar as! String
                if base == "___" {
                    // This is for accents
                    if language == Languages.Yugtun {
                        // NOTE: This is a hack. But the breve shouldn't be listed as an accent.
                        // but in order to get the app out, things needed to be done quickly.
                        base = "Other"
                    } else {
                        base = "Tone Marks"
                    }
                } else if base == "√" {
                    base = "\(base)  (press '123' then '#+=')"
                } else {
                    base = base.lowercased()
                }
                
                var item = "\(base): "
                
                for char in extra as! NSArray {
                    item = item + "\(convertAccents(char as! String).lowercased()), "
                }
                
                // Fixing fencepost problem by dropping the last space and comma.
                items.append(item.substring(to: item.index(before: item.index(before: item.endIndex))))
            }

            // Letters should be displayed in alphabetical order
            items = items.sorted {
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
                } else if $0.hasPrefix("Other") {
                    // HACK: This is to get Yugtun working on short notice and should be deleted.
                    return false
                }
                
                return $0 < $1
            }
            
            sections.append(Section(language: names[language]!, items: items))
        }
        
        tableView.backgroundColor = UIColor.clear
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
    
    fileprivate func convertAccents(_ input: String) -> String {
        var letter = input
        if input.uppercased() == "ACUTE" {
            letter = "\u{25cc}\u{0301}"
        } else if input.uppercased() == "CIRCUMFLEX" {
            letter = "\u{25cc}\u{0302}"
        } else if input.uppercased() == "GRAVE" {
            letter = "\u{25cc}\u{0300}"
        } else if input.uppercased() == "CARON" {
            letter = "\u{25cc}\u{030C}"
        } else if input.uppercased() == "DOUBLE_ACUTE" {
            letter = "\u{25cc}\u{030B}"
        } else if input.uppercased() == "COMBINING_DOUBLE_INVERTED_BREVE" {
            letter = "\u{25cc}\u{0361}\u{25cc}"
        }
        return letter
    }
    
    //
    // MARK: - UITableViewDelegate
    //
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (sections[section].collapsed!) ? 0 : sections[section].items.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableCell(withIdentifier: "header") as! CollapsibleTableViewHeader
        
        header.toggleButton.tag = section
        header.titleLabel.text = sections[section].name
        header.toggleButton.rotate(sections[section].collapsed! ? 0.0 : CGFloat(M_PI_2))
        header.toggleButton.addTarget(self, action: #selector(CharactersViewController.toggleCollapse), for: .touchUpInside)
        
        return header.contentView
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as UITableViewCell?
        
        cell?.textLabel?.text = sections[(indexPath as NSIndexPath).section].items[(indexPath as NSIndexPath).row]
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: NSInteger) -> CGFloat {
        // height of the header rows in the table
        return 40.0
    }
    
    //
    // MARK: - Event Handlers
    //
    @objc func toggleCollapse(_ sender: UIButton) {
        let section = sender.tag
        let collapsed = sections[section].collapsed
        
        // Toggle collapse
        sections[section].collapsed = !collapsed!
        
        // Reload section
        tableView.reloadSections(IndexSet(integer: section), with: .automatic)
    }
    
}
