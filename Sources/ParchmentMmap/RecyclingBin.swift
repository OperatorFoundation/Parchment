//
//  RecyclingBin.swift
//  
//
//  Created by Dr. Brandon Wiley on 8/22/22.
//

import Foundation

import SortedArray

public class RecyclingBin
{
    let manuscript: Manuscript
    let index: ManuscriptIndex
    let ids: Set<UInt64> = Set<UInt64>()
    let sortedArray: SortedArray<IndexEntry> = SortedArray<IndexEntry>()

    public init(manuscript: Manuscript, index: ManuscriptIndex)
    {
        self.manuscript = manuscript
        self.index = index
    }

    public func contains(offset: UInt64) -> Bool
    {
        return self.ids.contains(offset)
    }

    public func recycle(page: Page) throws
    {
        if self.contains(offset: page.range.startIndex)
        {
            return
        }

        try self.index.append(page: page)
    }

    // FIXME
//    public func reuse(page: NewPage) throws -> Page
//    {
//        for (item, entry) in self.sortedArray.enumerated()
//        {
//            if entry.length == page.values.count
//            {
//
//            }
//        }
//    }
}
