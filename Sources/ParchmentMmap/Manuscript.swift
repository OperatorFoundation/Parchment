//
//  Manuscript.swift
//  
//
//  Created by Dr. Brandon Wiley on 8/15/22.
//

// A Manuscript is a collection of Pages.

import Foundation

import Datable
import Gardener

class PageNumber
{
    let number: UInt64

    public init(_ number: UInt64)
    {
        self.number = number
    }
}

public class ManuscriptIterator: IteratorProtocol
{
    public typealias Element = Page

    let manuscript: Manuscript
    var index: UInt64

    public init(_ manuscript: Manuscript, _ index: UInt64)
    {
        self.manuscript = manuscript
        self.index = index
    }

    public func next() -> Page?
    {
        do
        {
            let result = try self.manuscript.get(number: self.index)
            self.index = self.index + 1
            return result
        }
        catch
        {
            return nil
        }
    }
}

public class Manuscript
{
    let pagesUrl: URL
    let index: ManuscriptIndex
    var recycling: RecyclingBin! = nil
    
    let header: any Parchment
    var pages = NSMapTable<PageNumber, Page>(keyOptions: .copyIn, valueOptions: .weakMemory)

    public init(directory: URL) throws
    {
        if !File.exists(directory.path)
        {
            guard File.makeDirectory(url: directory) else
            {
                throw ManuscriptError.couldNotCreateDirectory
            }
        }

        let indexUrl = directory.appendingPathComponent("index.parchment")
        index = try ManuscriptIndex(indexUrl)

        self.pagesUrl = directory.appendingPathComponent("pages.parchment")

        if File.exists(self.pagesUrl.path)
        {
            self.header = try ParchmentMmap(self.pagesUrl, offsetUInt64: 0, sizeUInt64: 1) // offset and size are in bytes
        }
        else
        {
            let endianness = UInt64(DatableConfig.localEndianness.rawValue)
            self.header = try ParchmentMmap.create(self.pagesUrl, value: endianness)
        }

        let recyclingUrl = directory.appendingPathComponent("recycling.parchment")
        let recyclingIndex = try ManuscriptIndex(recyclingUrl)
        self.recycling = RecyclingBin(manuscript: self, index: recyclingIndex)
    }

    public func get(number: UInt64) throws -> Page
    {
        if let page = self.pages.object(forKey: PageNumber(number))
        {
            if self.recycling.contains(offset: page.range.startIndex)
            {
                throw ManuscriptError.pageDeleted
            }

            return page
        }

        let entry = try self.index.get(number: number)
        if self.recycling.contains(offset: entry.offset)
        {
            throw ManuscriptError.pageDeleted
        }

        guard entry.length > 0 else
        {
            throw ManuscriptError.pageDeleted
        }

        let range = entry.offset..<(entry.offset + entry.length)

        for key in self.pages.keyEnumerator()
        {
            guard let oldPageNumber = key as? PageNumber else
            {
                throw ManuscriptError.badPageNumber
            }

            guard let oldPage = self.pages.object(forKey: oldPageNumber) else
            {
                throw ManuscriptError.badPageNumber
            }

            if oldPage.range.overlaps(range)
            {
                throw ManuscriptError.pageConflict
            }
        }

        let page = try Page(number: number, manuscript: self, location: entry.offset, length: entry.length)
        self.pages.setObject(page, forKey: PageNumber(number))

        return page
    }

    public func append(_ page: NewPage) throws -> Page
    {
        let number = UInt64(self.index.count)

        guard let entry = self.index.last else
        {
            throw ManuscriptError.emptyManuscript
        }
        let offset = entry.offset + entry.length

        let length = UInt64(page.values.count)

        return try Page(number: number, manuscript: self, location: offset, length: length)
    }

    public func delete(page: Page) throws
    {
        // Remove from cache
        self.pages.removeObject(forKey: PageNumber(page.number))

        // Mark as deleted on disk
        try self.recycling.recycle(page: page)
    }
}

extension Manuscript: Sequence
{
    public typealias Element = Page
    public typealias Iterator = ManuscriptIterator

    public func makeIterator() -> ManuscriptIterator
    {
        return ManuscriptIterator(self, 0)
    }
}

extension Manuscript: Collection, MutableCollection
{
    public typealias Index = UInt64

    public var startIndex: UInt64
    {
        return 0
    }

    public var endIndex: UInt64
    {
        return self.index.endIndex / 2
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
                return Page(manuscript: self)
            }
        }

        set(newValue)
        {
            guard newValue.number == position else
            {
                return
            }

            let entry = IndexEntry(number: newValue.number, offset: newValue.range.startIndex, length: newValue.range.endIndex - newValue.range.startIndex)

            do
            {
                try self.index.set(entry: entry)
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


public enum ManuscriptError: Error
{
    case couldNotCreateDirectory
    case pageConflict
    case badPageNumber
    case pageDeleted
    case emptyManuscript
}
