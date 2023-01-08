//
//  Page.swift
//  
//
//  Created by Dr. Brandon Wiley on 8/15/22.
//

import Foundation

public class Page
{
    let number: UInt64
    let manuscript: Manuscript
    let parchment: ParchmentUnsafe
    public let range: Range<UInt64>

    // This is a bad Page initializer, only used internally for protocol conformance where a Page must be returned even if there is an error, due to function signature type restrictions.
    // Never call this directly.
    public init(manuscript: Manuscript)
    {
        self.number = 0
        self.manuscript = manuscript
        self.parchment = ParchmentUnsafe()
        self.range = 0..<1
    }

    public init(number: UInt64, manuscript: Manuscript, location: UInt64, length: UInt64) throws
    {
        self.number = number
        self.manuscript = manuscript
        self.parchment = try ParchmentUnsafe(manuscript.pagesUrl, offsetUInt64: location, sizeUInt64: length)

        self.range = location..<(location + length)

        guard self.parchment.contains(offset: self.range.endIndex) else
        {
            throw PageError.invalidPage
        }
    }
}

extension Page: Equatable
{
    public static func == (lhs: Page, rhs: Page) -> Bool
    {
        return (lhs.manuscript.pagesUrl == rhs.manuscript.pagesUrl) && (lhs.range == rhs.range)
    }
}

extension Page: Hashable
{
    public func hash(into hasher: inout Hasher)
    {
        hasher.combine(manuscript.pagesUrl)
        hasher.combine(range)
    }
}

public enum PageError: Error
{
    case pageDeleted
    case invalidPage
}
