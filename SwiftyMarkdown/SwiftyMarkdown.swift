//
//  SwiftyMarkdown.swift
//  SwiftyMarkdown
//
//  Created by Simon Fairbairn on 05/03/2016.
//  Copyright © 2016 Voyage Travel Apps. All rights reserved.
//

import UIKit


/**
 Represents a dictionary of NSAttributedString attributes, to be applied to the parsed Markdown. If the attribute for a style is not set then the system default's Dynamic Type attributes will be used.
 */

public typealias AttributesDictionary = [String: Any]


enum LineType : Int {
    case h1, h2, h3, h4, h5, h6, body

    var textStyle: UIFontTextStyle {
        switch self {
        case .h1:
            if #available(iOS 9, *) {
                return .title1
            } else {
                return .headline
            }
        case .h2:
            if #available(iOS 9, *) {
                return .title2
            } else {
                return .headline
            }
        case .h3:
            if #available(iOS 9, *) {
                return .title2
            } else {
                return .subheadline
            }
        case .h4:
            return .headline
        case .h5:
            return .subheadline
        case .h6:
            return .footnote
        default:
            return .body
        }
    }
    var fontName: String? {
        return UIFont.preferredFont(forTextStyle: textStyle).fontName
    }

    var fontSize: CGFloat {
        let font = UIFont.preferredFont(forTextStyle: textStyle)
        let styleDescriptor = font.fontDescriptor
        return styleDescriptor.fontAttributes[UIFontDescriptorSizeAttribute] as! CGFloat
    }
}

enum LineStyle : Int {
    case none
    case italic
    case bold
    case code
    case link

    static func styleFromString(_ string : String ) -> LineStyle {
        if string == "**" || string == "__" {
            return .bold
        } else if string == "*" || string == "_" {
            return .italic
        } else if string == "`" {
            return .code
        } else if string == "["  {
            return .link
        } else {
            return .none
        }
    }

    var fontName: String? {
        let descriptor = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body).fontDescriptor

        switch self {
        case .italic:
            let italicFontDescriptor = descriptor.withSymbolicTraits(.traitItalic)
            return UIFont(descriptor: italicFontDescriptor!, size: 0).fontName
        case .bold:
            let boldFontDescriptor = descriptor.withSymbolicTraits(.traitBold)
            return UIFont(descriptor: boldFontDescriptor!, size: 0).fontName
        default:
            return nil
        }
    }
}





/// A class that takes a [Markdown](https://daringfireball.net/projects/markdown/) string or file and returns an NSAttributedString. It will use the system default Dynamic Type attributes unless style attributes are explicitly set.
open class SwiftyMarkdown {

    fileprivate var currentUserAttributesDictionary: AttributesDictionary? {
        switch currentType {
        case .h1:
            return h1
        case .h2:
            return h2
        case .h3:
            return h3
        case .h4:
            return h4
        case .h5:
            return h5
        case .h6:
            return h6
        case .body:
            switch currentStyle {
            case .none:
                return body
            case .code:
                return code
            case .italic:
                return italic
            case .link:
                return link
            case .bold:
                return bold
            }
        }
    }

    /// The attributes to apply to any H1 headers found in the Markdown
    open var h1: AttributesDictionary?

    /// The attributes to apply to any H2 headers found in the Markdown
    open var h2: AttributesDictionary?

    /// The attributes to apply to any H3 headers found in the Markdown
    open var h3: AttributesDictionary?

    /// The attributes to apply to any H4 headers found in the Markdown
    open var h4: AttributesDictionary?

    /// The attributes to apply to any H5 headers found in the Markdown
    open var h5: AttributesDictionary?

    /// The attributes to apply to any H6 headers found in the Markdown
    open var h6: AttributesDictionary?

    /// The default body styles. These are the base styles and will be used for e.g. headers if no other styles override them.
    open var body: AttributesDictionary?

    /// The attributes to apply to any links found in the Markdown
    open var link: AttributesDictionary?

    /// The attributes to apply to any bold text found in the Markdown
    open var bold: AttributesDictionary?

    /// The attributes to apply to any italic text found in the Markdown
    open var italic: AttributesDictionary?

    /// The attributes to apply to any code blocks or inline code text found in the Markdown
    open var code: AttributesDictionary?


    var currentType : LineType = .body
    var currentStyle: LineStyle = .none


    let string : String
    let instructionSet = CharacterSet(charactersIn: "[\\*_`")

    /**

     - parameter string: A string containing [Markdown](https://daringfireball.net/projects/markdown/) syntax to be converted to an NSAttributedString

     - returns: An initialized SwiftyMarkdown object
     */
    public init(string : String ) {
        self.string = string
    }

    /**
     A failable initializer that takes a URL and attempts to read it as a UTF-8 string

     - parameter url: The location of the file to read

     - returns: An initialized SwiftyMarkdown object, or nil if the string couldn't be read
     */
    public init?(url : URL ) {

        do {
            self.string = try NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue) as String

        } catch {
            self.string = ""
            fatalError("Couldn't read string")
            return nil
        }
    }

    /**
     Generates an NSAttributedString from the string or URL passed at initialisation. Custom fonts or styles are applied to the appropriate elements when this method is called.

     - returns: An NSAttributedString with the styles applied
     */
    open func attributedString() -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: "")

        let lines = self.string.components(separatedBy: CharacterSet.newlines)

        var lineCount = 0

        let headings = ["# ", "## ", "### ", "#### ", "##### ", "###### "]

        var skipLine = false
        for theLine in lines {
            lineCount += 1
            if skipLine {
                skipLine = false
                continue
            }
            var line = theLine
            for heading in headings {

                if let range =  line.range(of: heading) , range.lowerBound == line.startIndex {

                    let startHeadingString = line.replacingCharacters(in: range, with: "")

                    // Remove ending
                    let endHeadingString = heading.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    line = startHeadingString.replacingOccurrences(of: endHeadingString, with: "").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                    currentType = LineType(rawValue: headings.index(of: heading)!)!

                    // We found a heading so break out of the inner loop
                    break
                }
            }

            // Look for underlined headings
            if lineCount  < lines.count {
                let nextLine = lines[lineCount]

                if let range = nextLine.range(of: "=") , range.lowerBound == nextLine.startIndex {
                    // Make H1
                    currentType = .h1
                    // We need to skip the next line
                    skipLine = true
                }

                if let range = nextLine.range(of: "-") , range.lowerBound == nextLine.startIndex {
                    // Make H2
                    currentType = .h2
                    // We need to skip the next line
                    skipLine = true
                }
            }

            // If this is not an empty line...
            if line.characters.count > 0 {

                // ...start scanning
                let scanner = Scanner(string: line)

                // We want to be aware of spaces
                scanner.charactersToBeSkipped = nil

                while !scanner.isAtEnd {
                    var string : NSString?

                    // Get all the characters up to the ones we are interested in
                    if scanner.scanUpToCharacters(from: instructionSet, into: &string) {

                        if let hasString = string as? String {
                            let bodyString = attributedStringFromString(hasString, withStyle: .none)
                            attributedString.append(bodyString)

                            let location = scanner.scanLocation

                            let matchedCharacters = tagFromScanner(scanner).foundCharacters
                            // If the next string after the characters is a space, then add it to the final string and continue

                            let set = NSMutableCharacterSet.whitespace()
                            set.formUnion(with: CharacterSet.punctuationCharacters)
                            if scanner.scanUpToCharacters(from: set as CharacterSet, into: nil) {
                                scanner.scanLocation = location
                                attributedString.append(self.attributedStringFromScanner(scanner))

                            } else if matchedCharacters == "[" {
                                scanner.scanLocation = location
                                attributedString.append(self.attributedStringFromScanner(scanner))
                            } else {
                                let charAtts = attributedStringFromString(matchedCharacters, withStyle: .none)
                                attributedString.append(charAtts)
                            }
                        }
                    } else {
                        attributedString.append(self.attributedStringFromScanner(scanner, atStartOfLine: true))
                    }
                }
            }

            // Append a new line character to the end of the processed line
            attributedString.append(NSAttributedString(string: "\n"))
            currentType = .body
        }

        return attributedString
    }

    func attributedStringFromScanner( _ scanner : Scanner, atStartOfLine start : Bool = false) -> NSAttributedString {
        var followingString : NSString?

        let results = self.tagFromScanner(scanner)

        currentStyle = LineStyle.styleFromString(results.foundCharacters)

        var attributes = [String : Any]()
        if currentStyle == .link {

            var linkText : NSString?
            var linkURL : NSString?
            let linkCharacters = CharacterSet(charactersIn: "]()")

            scanner.scanUpToCharacters(from: linkCharacters, into: &linkText)
            scanner.scanCharacters(from: linkCharacters, into: nil)
            scanner.scanUpToCharacters(from: linkCharacters, into: &linkURL)
            scanner.scanCharacters(from: linkCharacters, into: nil)


            if let hasLink = linkText, let hasURL = linkURL {
                followingString = hasLink
                attributes[NSLinkAttributeName] = hasURL
            } else {
                currentStyle = .none
            }
        } else {
            scanner.scanUpToCharacters(from: instructionSet, into: &followingString)
        }

        let attributedString = attributedStringFromString(results.escapedCharacters, withStyle: currentStyle).mutableCopy() as! NSMutableAttributedString
        if let hasString = followingString as? String {

            let prefix = ( currentStyle == .code && start ) ? "\t" : ""
            let attString = attributedStringFromString(prefix + hasString, withStyle: currentStyle, attributes: attributes)
            attributedString.append(attString)
        }
        let suffix = self.tagFromScanner(scanner)
        attributedString.append(attributedStringFromString(suffix.escapedCharacters, withStyle: currentStyle))

        currentStyle = .none

        return attributedString
    }

    func tagFromScanner( _ scanner : Scanner ) -> (foundCharacters : String, escapedCharacters : String) {
        var matchedCharacters : String = ""
        var tempCharacters : NSString?

        // Scan the ones we are interested in
        while scanner.scanCharacters(from: instructionSet, into: &tempCharacters) {
            if let chars = tempCharacters as? String {
                matchedCharacters = matchedCharacters + chars
            }
        }
        var foundCharacters : String = ""

        while matchedCharacters.contains("\\") {
            if let hasRange = matchedCharacters.range(of: "\\") {

                // FIXME: Possible error in range
                let newRange  = hasRange.lowerBound..<matchedCharacters.index(hasRange.upperBound, offsetBy: 1)
                foundCharacters = foundCharacters + matchedCharacters.substring(with: newRange)

                matchedCharacters.removeSubrange(newRange)
            }
        }

        return (matchedCharacters, foundCharacters.replacingOccurrences(of: "\\", with: ""))
    }

    func attributedStringFromString(_ string: String, withStyle style: LineStyle, attributes: AttributesDictionary = [:]) -> NSAttributedString {
        
        if var currentUserAttributesDictionary = currentUserAttributesDictionary {
            for (key, value) in attributes {
                currentUserAttributesDictionary.updateValue(value, forKey: key)
            }
            return NSAttributedString(string: string, attributes: currentUserAttributesDictionary)
        }
        
        var dynamicTypeAttributes = attributes
        dynamicTypeAttributes[NSFontAttributeName] = UIFont(name: currentStyle.fontName ?? currentType.fontName!, size: currentType.fontSize)
        
        return NSAttributedString(string: string, attributes: dynamicTypeAttributes)
    }
}
