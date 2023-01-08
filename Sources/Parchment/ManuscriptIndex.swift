//
//  ManuscriptIndex.swift
//  
//
//  Created by Dr. Brandon Wiley on 8/18/22.
//

// The ManuscriptIndex is an index into a collection of Pages.

import Foundation

public class IndexEntry
{
    public let number: UInt64
    public let offset: UInt64
    public let length: UInt64

    public init(number: UInt64, offset: UInt64, length: UInt64)
    {
        self.number = number
        self.offset = offset
        self.length = length
    }
}

// IndexEntry: Comparable is implemented this way for the RecyclingBin
extension IndexEntry: Comparable
{
    public static func < (lhs: IndexEntry, rhs: IndexEntry) -> Bool
    {
        if lhs.length == rhs.length
        {
            if lhs.number == rhs.number
            {
                return lhs.offset < rhs.offset
            }
            else
            {
                return lhs.number < rhs.number
            }
        }
        else
        {
            return lhs.length < rhs.length
        }
    }

    public static func == (lhs: IndexEntry, rhs: IndexEntry) -> Bool
    {
        if lhs.length == rhs.length
        {
            if lhs.offset == rhs.offset
            {
                return lhs.number == rhs.number
            }
            else
            {
                return false
            }
        }
        else
        {
            return false
        }
    }
}

public class IndexIterator: IteratorProtocol
{
    public typealias Element = IndexEntry

    let index: ManuscriptIndex
    var number: UInt64

    public init(_ index: ManuscriptIndex, _ number: UInt64)
    {
        self.index = index
        self.number = number
    }

    public func next() -> Element?
    {
        do
        {
            let result = try self.index.get(number: self.number)
            self.number = self.number + 1
            return result
        }
        catch
        {
            return nil
        }
    }
}

public class ManuscriptIndex
{
    let parchment: Parchment

    public init(_ url: URL) throws
    {
        self.parchment = try Parchment(url)
    }

    public func get(number: UInt64) throws -> IndexEntry
    {
        let offset = try self.parchment.get(offset: number * 2)
        let length = try self.parchment.get(offset: (number * 2) + 1)

        return IndexEntry(number: number, offset: offset, length: length)
    }

    public func set(entry: IndexEntry) throws
    {
        try self.parchment.set(offset: entry.number * 2, to: entry.offset)
        try self.parchment.set(offset: (entry.number * 2) + 1, to: entry.length)
    }

    public func append(page: Page) throws
    {
        let length = page.range.endIndex - page.range.startIndex
        let entry = IndexEntry(number: page.number, offset: page.range.startIndex, length: length)
        try self.append(entry: entry)
    }

    public func append(entry: IndexEntry) throws
    {
        try self.parchment.append([entry.offset, entry.length])
    }
}

extension ManuscriptIndex: Sequence
{
    public typealias Element = IndexEntry
    public typealias Iterator = IndexIterator

    public func makeIterator() -> IndexIterator
    {
        return IndexIterator(self, 0)
    }
}

extension ManuscriptIndex: Collection, MutableCollection
{
    public typealias Index = UInt64

    public var startIndex: UInt64
    {
        return 0
    }

    public var endIndex: UInt64
    {
        return self.parchment.endIndex / 2 // Convert from UInt64 to pairs of UInt64
    }

    public subscript(position: Index) -> Element
    {
        get
        {
            do
            {
                return try self.get(number: position)
            }
            catch
            {
                // This is bad, but what can you do? We must depend on the runtime to never give us a bad index.
                return IndexEntry(number: 0, offset: 0, length: 0)
            }
        }

        set(newValue)
        {
            do
            {
                try self.set(entry: newValue)
            }
            catch
            {
                return
            }
        }
    }

    public func index(after i: UInt64) -> UInt64
    {
        return i + UInt64(1)
    }
}

extension ManuscriptIndex: BidirectionalCollection
{
    public func index(before i: UInt64) -> UInt64
    {
        return i - UInt64(1)
    }
}

extension ManuscriptIndex: RandomAccessCollection
{
}
