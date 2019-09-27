//
//  KeyboardModel.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 7/10/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import Foundation

var counter = 0

enum ShiftState {
    case disabled
    case enabled
    case locked

    func uppercase() -> Bool {
        switch self {
        case .disabled:
            return false
        case .enabled:
            return true
        case .locked:
            return true
        }
    }
}

class Keyboard {
    let PLACEHOLDER = "___"

    var pages: [Page] = []

    func add(key: Key, row: Int, page: Int) {
        if self.pages.count <= page {
            for _ in self.pages.count...page {
                self.pages.append(Page())
            }
        }

        self.pages[page].add(key: key, row: row)
    }

    func placeKey(_ key: Key, row: Int, page: Int, col: Int) {
        if self.pages.count <= page {
            for _ in self.pages.count...page {
                self.pages.append(Page())
            }
        }

        self.pages[page].placeKey(key, row: row, col: col)
    }

    // removes all instances PLACEHOLDER in the keyboard
    func removePlaceHolder() {
        for page in self.pages {
            for (i, row) in page.rows.enumerated() {
                for key in row {
                    if key.outputForCase(false) == PLACEHOLDER {
                        page.rows[i] = row.filter({$0.outputForCase(false) != PLACEHOLDER})
                    }
                }
            }
        }
    }

    func getKey(_ outputForKey: String) -> Key? {
        for page in self.pages {
            for row in page.rows {
                for key in row {
                    if key.outputForCase(false) == outputForKey.lowercased() {
                        return key
                    }
                }
            }
        }
        return nil
    }

    func getLongHoldKeys() -> Set<String> {
        var keys = Set<String>()
        for page in self.pages {
            for row in page.rows {
                for key in row {
                    if key.isLongHold() {
                        keys.insert(key.outputForCase(false))
                    }
                }
            }
        }
        return keys
    }
}

class Page {
    var rows: [[Key]] = []

    func add(key: Key, row: Int) {
        if self.rows.count <= row {
            for _ in self.rows.count...row {
                self.rows.append([])
            }
        }

        self.rows[row].append(key)
    }


    func placeKey(_ key: Key, row: Int, col: Int) {
        if self.rows.count <= row {
            for _ in self.rows.count...row {
                self.rows.append([])
            }
        }

        self.rows[row].insert(key, at: col)
    }
}

class Key: Hashable {
    static let LINGIT_SLASHED_O = "∅"
    static let NUMBER_CHANGE_STRING = "123"
    static let LETTER_CHANGE_STRING = "ABC"
    static let SPEC_CHARS_CHANGE_STRING = "#+="

    enum KeyType: String {
        case character
        case specialCharacter
        case shift
        case backspace
        case modeChange
        case keyboardChange
        case period
        case space
        case `return`
        case settings
        case other
    }

    var type: KeyType
    var uppercaseKeyCap: String?
    var lowercaseKeyCap: String?
    var uppercaseOutput: String?
    var lowercaseOutput: String?
    var extraCharacters: [String] = []
    var uppercaseExtraCharacters: [String] = []
    var toMode: Int? //if the key is a mode button, this indicates which page it links to

    var isCharacter: Bool {
        get {
            switch self.type {
            case
            .character,
            .specialCharacter,
            .period:
                return true
            default:
                return false
            }
        }
    }

    var isSpecial: Bool {
        get {
            switch self.type {
            case .shift:
                return true
            case .backspace:
                return true
            case .modeChange:
                return true
            case .keyboardChange:
                return true
            case .return:
                return true
            case .settings:
                return true
            default:
                return false
            }
        }
    }

    var hasOutput: Bool {
        get {
            return (self.uppercaseOutput != nil) || (self.lowercaseOutput != nil)
        }
    }

    // TODO: this is kind of a hack
    var hashValue: Int

    init(_ type: KeyType) {
        self.type = type
        self.hashValue = counter
        counter += 1
    }

    func hash(into hasher: inout Hasher)
    {
        hasher.combine(self.hashValue)
    }

    convenience init(_ key: Key) {
        self.init(key.type)

        self.uppercaseKeyCap = key.uppercaseKeyCap
        self.lowercaseKeyCap = key.lowercaseKeyCap
        self.uppercaseOutput = key.uppercaseOutput
        self.lowercaseOutput = key.lowercaseOutput
        self.toMode = key.toMode
    }

    func setExtraCharacters(_ letters: [String]) {
        self.extraCharacters = []
        self.uppercaseExtraCharacters = []
        for letter in letters {
            self.extraCharacters.append((letter as NSString).lowercased)
            self.uppercaseExtraCharacters.append((letter as NSString).uppercased)
        }
    }

    // appends extra letters to key, doesn't include duplicates
    func appendExtraCharacters(_ letters: [String]) {
        for var letter in letters {
            letter = convertAccents(letter)
            if (!self.extraCharacters.contains(letter.lowercased())) {
                self.extraCharacters.append((letter as NSString).lowercased)
                self.uppercaseExtraCharacters.append((letter as NSString).uppercased)
            }
        }
    }

    func getExtraCharacters() -> [String] {
        return self.extraCharacters;
    }

    func hasExtraCharacters() -> Bool {
        return getExtraCharacters().count > 0
    }

    func setLetter(_ letter: String) {
        self.lowercaseOutput = letter.lowercased()
        self.uppercaseOutput = letter.uppercased()
        self.lowercaseKeyCap = self.lowercaseOutput
        self.uppercaseKeyCap = self.uppercaseOutput
    }

    fileprivate func convertAccents(_ input: String) -> String {
        var letter = input
        if input.uppercased() == "ACUTE" {
            letter = "\u{0301}"
        } else if input.uppercased() == "CIRCUMFLEX" {
            letter = "\u{0302}"
        } else if input.uppercased() == "GRAVE" {
            letter = "\u{0300}"
        } else if input.uppercased() == "CARON" {
            letter = "\u{030C}"
        } else if input.uppercased() == "DOUBLE_ACUTE" {
            letter = "\u{030B}"
        } else if input.uppercased() == "COMBINING_DOUBLE_INVERTED_BREVE" {
            letter = "\u{0361}"
        }
        return letter
    }

    func isAccent() -> Bool {
        // NOTE: The combined double inverted breve is not technically an accent
        return self.uppercaseOutput == "\u{0301}" ||
            self.uppercaseOutput == "\u{0302}" ||
            self.uppercaseOutput == "\u{0300}" ||
            self.uppercaseOutput == "\u{030C}" ||
            self.uppercaseOutput == "\u{030B}"
    }

    func isLongHold() -> Bool {
        return self.extraCharacters.count > 1
    }

    func outputForCase(_ uppercase: Bool) -> String {
        if uppercase {
            return uppercaseOutput ?? lowercaseOutput ?? ""
        }
        else {
            return lowercaseOutput ?? uppercaseOutput ?? ""
        }
    }

    func keyCapForCase(_ uppercase: Bool) -> String {
        if uppercase {
            return uppercaseKeyCap ?? lowercaseKeyCap ?? ""
        }
        else {
            return lowercaseKeyCap ?? uppercaseKeyCap ?? ""
        }
    }
}

func ==(lhs: Key, rhs: Key) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
