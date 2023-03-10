// ParchmentMmap mmaps a file to a [UInt64]. It can either mmap the whole file or any contiguous subset of the file.

import Foundation
import SystemPackage

import Chord
import Datable
import Gardener
import Mmap
import ParchmentTypes

@_exported import ParchmentTypes

// ParchmetUnsafe does not lock
public class ParchmentUnsafe
{
    static public func getFileSizeOfUrl(_ url: URL) throws -> Int // in bytes
    {
        if File.exists(url.path)
        {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            let fileSize = resourceValues.fileSize!
            return fileSize
        }
        else
        {
            throw ParchmentError.fileDoesNotExist
        }
    }

    static public func getFileSizeUInt64OfUrl(_ url: URL) throws -> UInt64
    {
        let sizeInBytes = try self.getFileSizeOfUrl(url)
        guard (sizeInBytes % 8) == 0 else
        {
            throw ParchmentError.invalidSize(sizeInBytes)
        }

        return UInt64(sizeInBytes / 8)
    }

    static public func getOrCreate(_ url: URL, offsetUInt64: UInt64 = 0, sizeUInt64: UInt64) throws -> ParchmentUnsafe
    {
        guard sizeUInt64 > 0 else
        {
            throw ParchmentError.invalidSize(Int(sizeUInt64))
        }

        let oldSize = try ParchmentUnsafe.getFileSizeUInt64OfUrl(url)
        let newSize = offsetUInt64 + sizeUInt64

        if oldSize >= newSize // get
        {
            return try ParchmentUnsafe(url, offsetUInt64: offsetUInt64, sizeUInt64: sizeUInt64)
        }
        else // oldSize < newSize, create
        {
            guard offsetUInt64 == oldSize else
            {
                throw ParchmentError.invalidOffset(offsetUInt64)
            }

            let difference = newSize - oldSize

            let parchment = try ParchmentUnsafe(url)
            try parchment.grow(difference)

            return parchment
        }
    }

    static public func create(_ url: URL, value: UInt64) throws -> ParchmentUnsafe // size is in bytes
    {
        if File.exists(url.path)
        {
            throw ParchmentError.fileExists
        }

        guard value != UInt64.max else
        {
            throw ParchmentError.maxUInt64ValueNotAllowed
        }

        let fd = try FileDescriptor.open(url.path, FileDescriptor.AccessMode.readWrite, options: [.create, .append], permissions: [.ownerReadWrite])

        DatableConfig.endianess = .little
        let data = value.data

        try fd.writeAll(data)
        try fd.close()

        return try ParchmentUnsafe(url, offsetUInt64: 0, sizeUInt64: 1)
    }

    let url: URL
    var mapped: MmapFile? = nil

    public var fileSize: Int
    {
        if let mapped = self.mapped
        {
            return mapped.size
        }
        else
        {
            return 0
        }
    }

    // This is a bad ParchmentUnsafe initializer, only used internally for protocol conformance where a ParchmentUnsafe must be returned even if there is an error, due to function signature type restrictions.
    // Never call this directly.
    public init()
    {
        self.url = URL(fileURLWithPath: "")
    }

    public init(_ url: URL, offsetUInt64: UInt64 = 0, sizeUInt64: UInt64? = nil) throws
    {
        self.url = url

        let offsetBytes = Int(offsetUInt64 * 8)
        let sizeBytes: Int
        if let size = sizeUInt64
        {
            sizeBytes = Int(size * 8)
        }
        else
        {
            sizeBytes = 0
        }

        if File.exists(url.path)
        {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            let fileSize = resourceValues.fileSize!

            if fileSize > 0
            {
                self.mapped = try MmapFile(url, offset: offsetBytes, size: sizeBytes)
            }
        }
    }

    public func getSize() -> UInt64
    {
        return UInt64(self.fileSize / 8)
    }

    public func getFileSize() -> Int
    {
        return self.fileSize
    }

    public func append(_ newElement: UInt64) throws
    {
        guard newElement != UInt64.max else
        {
            throw ParchmentError.maxUInt64ValueNotAllowed
        }

        if let mapped = self.mapped
        {
            guard (mapped.offset + mapped.size) == mapped.fileSize else
            {
                throw ParchmentError.cannotAppend
            }
        }

        self.mapped = nil

        let fd = try FileDescriptor.open(self.url.path, FileDescriptor.AccessMode.readWrite, options: [.create, .append], permissions: [.ownerReadWrite])

        DatableConfig.endianess = .little
        let data = newElement.data

        try fd.seek(offset: 0, from: FileDescriptor.SeekOrigin.end)
        try fd.writeAll(data)
        try fd.close()

        self.mapped = try MmapFile(self.url)
    }

    public func append(_ contentsOf: [UInt64]) throws
    {
        let fd = try FileDescriptor.open(self.url.path, FileDescriptor.AccessMode.readWrite, options: [.create, .append], permissions: [.ownerReadWrite])

        try fd.seek(offset: 0, from: FileDescriptor.SeekOrigin.end)

        for element in contentsOf
        {
            guard element != UInt64.max else
            {
                throw ParchmentError.maxUInt64ValueNotAllowed
            }
        }

        for element in contentsOf
        {
            DatableConfig.endianess = .little
            let data = element.data

            try fd.writeAll(data)
        }

        try fd.close()

        if let mapped = self.mapped
        {
            guard (mapped.offset + mapped.size) == mapped.fileSize else
            {
                throw ParchmentError.cannotAppend
            }
        }
    }

    public func grow(_ size: UInt64) throws
    {
        let fd = try FileDescriptor.open(self.url.path, FileDescriptor.AccessMode.readWrite, options: [.create, .append], permissions: [.ownerReadWrite])

        try fd.seek(offset: 0, from: FileDescriptor.SeekOrigin.end)

        for _ in 0..<Int(size)
        {
            DatableConfig.endianess = .little
            let data = UInt64(0).data

            try fd.writeAll(data)
        }

        try fd.close()

        if let mapped = self.mapped
        {
            guard (mapped.offset + mapped.size) == mapped.fileSize else
            {
                throw ParchmentError.cannotAppend
            }
        }
    }

    public func set(offset uint64Offset: UInt64, to uint64s: [UInt64]) throws
    {
        for element in uint64s
        {
            guard element != UInt64.max else
            {
                throw ParchmentError.maxUInt64ValueNotAllowed
            }
        }

        guard let mapped = self.mapped else
        {
            throw ParchmentError.noMmapFile
        }

        try mapped.set(offset: uint64Offset, to: uint64s)
    }

    public func set(offset uint64Offset: UInt64, to uint64: UInt64) throws
    {
        guard uint64 != UInt64.max else
        {
            throw ParchmentError.maxUInt64ValueNotAllowed
        }

        guard let mapped = self.mapped else
        {
            throw ParchmentError.noMmapFile
        }

        try mapped.set(offset: uint64Offset, to: uint64)
    }

    public func get(offset uint64Offset: UInt64, length: UInt64) throws -> [UInt64]
    {
        guard let mapped = self.mapped else
        {
            throw ParchmentError.noMmapFile
        }

        return try mapped.get(offset: uint64Offset, length: length).filter { $0 != UInt64.max }
    }

    public func get(offset uint64Offset: UInt64) throws -> UInt64
    {
        guard let mapped = self.mapped else
        {
            throw ParchmentError.noMmapFile
        }

        let result = try mapped.get(offset: uint64Offset)
        guard result != UInt64.max else
        {
            throw ParchmentError.maxUInt64ValueNotAllowed
        }

        return result
    }

    public func contains(offset uint64Offset: UInt64) -> Bool
    {
        return uint64Offset < UInt64(self.fileSize)
    }

    public func delete(offset uint64Offset: UInt64) throws
    {
        guard let mapped = self.mapped else
        {
            throw ParchmentError.noMmapFile
        }

        try mapped.set(offset: uint64Offset, to: UInt64.max)
    }

    public func delete(offset uint64Offset: UInt64, length: UInt64) throws
    {
        guard let mapped = self.mapped else
        {
            throw ParchmentError.noMmapFile
        }

        let values = [UInt64](repeating: UInt64.max, count: Int(length))

        try mapped.set(offset: uint64Offset, to: values)
    }

    public func compact() throws
    {
        // FIXME - implement deleted item compaction
    }
}

// ParchmentActor uses actor-based locking and presents an asynchronous API
public actor ParchmentActor
{
    static public func create(_ url: URL, value: UInt64) throws -> ParchmentActor
    {
        let unsafe = try ParchmentUnsafe.create(url, value: value)
        return ParchmentActor(unsafe: unsafe)
    }

    let unsafe: ParchmentUnsafe

    public var fileSize: Int
    {
        return self.unsafe.fileSize
    }

    public init(_ url: URL, offsetUInt64: UInt64 = 0, sizeUInt64: UInt64? = nil) throws
    {
        self.unsafe = try ParchmentUnsafe(url, offsetUInt64: offsetUInt64, sizeUInt64: sizeUInt64)
    }

    init(unsafe: ParchmentUnsafe)
    {
        self.unsafe = unsafe
    }

    public func append(_ newElement: UInt64) throws
    {
        try self.unsafe.append(newElement)
    }

    public func append(_ contentsOf: [UInt64]) throws
    {
        try self.unsafe.append(contentsOf)
    }

    public func set(offset uint64Offset: UInt64, to uint64s: [UInt64]) throws
    {
        try self.unsafe.set(offset: uint64Offset, to: uint64s)
    }

    public func set(offset uint64Offset: UInt64, to uint64: UInt64) throws
    {
        try self.unsafe.set(offset: uint64Offset, to: uint64)
    }

    public func get(offset uint64Offset: UInt64, length: UInt64) throws -> [UInt64]
    {
        return try self.unsafe.get(offset: uint64Offset, length: length)
    }

    public func get(offset uint64Offset: UInt64) throws -> UInt64
    {
        return try self.unsafe.get(offset: uint64Offset)
    }

    public func delete(offset uint64Offset: UInt64) throws
    {
        return try self.unsafe.delete(offset: uint64Offset)
    }

    public func delete(offset uint64Offset: UInt64, length: UInt64) throws
    {
        return try self.unsafe.delete(offset: uint64Offset, length: length)
    }

    public func compact() throws
    {
        return try self.unsafe.compact()
    }
}

// Parchment uses actor-based locking and presents a synchronous API
public class ParchmentMmap: Parchment
{
    static public func create(_ url: URL, value: UInt64) throws -> any Parchment
    {
        let actor = try ParchmentActor.create(url, value: value)
        return ParchmentMmap(actor: actor)
    }

    public var fileSize: Int
    {
        let result: Int = AsyncAwaitSynchronizer<Int>.sync
        {
            return await self.actor.fileSize
        }

        return result
    }

    let actor: ParchmentActor

    public required init(_ url: URL, offsetUInt64: UInt64 = 0, sizeUInt64: UInt64? = nil) throws
    {
        self.actor = try ParchmentActor(url, offsetUInt64: offsetUInt64, sizeUInt64: sizeUInt64)
    }

    init(actor: ParchmentActor)
    {
        self.actor = actor
    }

    public func append(_ newElement: UInt64) throws
    {
        AsyncAwaitThrowingEffectSynchronizer.sync
        {
            try await self.actor.append(newElement)
        }
    }

    public func append(_ contentsOf: [UInt64]) throws
    {
        AsyncAwaitThrowingEffectSynchronizer.sync
        {
            try await self.actor.append(contentsOf)
        }
    }

    public func set(offset uint64Offset: UInt64, to uint64s: [UInt64]) throws
    {
        AsyncAwaitThrowingEffectSynchronizer.sync
        {
            try await self.actor.set(offset: uint64Offset, to: uint64s)
        }
    }

    public func set(offset uint64Offset: UInt64, to uint64: UInt64) throws
    {
        AsyncAwaitThrowingEffectSynchronizer.sync
        {
            try await self.actor.set(offset: uint64Offset, to: uint64)
        }
    }

    public func get(offset uint64Offset: UInt64, length: UInt64) throws -> [UInt64]
    {
        let result: [UInt64] = try AsyncAwaitThrowingSynchronizer<[UInt64]>.sync
        {
            return try await self.actor.get(offset: uint64Offset, length: length)
        }

        return result
    }

    public func get(offset uint64Offset: UInt64) throws -> UInt64
    {
        let result: UInt64 = try AsyncAwaitThrowingSynchronizer<UInt64>.sync
        {
            return try await self.actor.get(offset: uint64Offset)
        }

        return result
    }

    public func delete(offset uint64Offset: UInt64) throws
    {
        AsyncAwaitThrowingEffectSynchronizer.sync
        {
            try await self.actor.delete(offset: uint64Offset)
        }
    }

    public func delete(offset uint64Offset: UInt64, length: UInt64) throws
    {
        AsyncAwaitThrowingEffectSynchronizer.sync
        {
            try await self.actor.delete(offset: uint64Offset, length: length)
        }
    }

    public func compact() throws
    {
        AsyncAwaitThrowingEffectSynchronizer.sync
        {
            try await self.actor.compact()
        }
    }
}

extension ParchmentMmap: Sequence
{
    public typealias Element = UInt64
    public typealias Iterator = ParchmentIterator

    public func makeIterator() -> ParchmentIterator
    {
        return ParchmentIterator(self, 0)
    }
}

extension ParchmentMmap: Collection, MutableCollection
{
    public typealias Index = UInt64

    public var startIndex: UInt64
    {
        return 0
    }

    public var endIndex: UInt64
    {
        return UInt64(self.fileSize) / UInt64(8)
    }

    public subscript(position: Index) -> Element
    {
        get
        {
            do
            {
                return try self.get(offset: position)
            }
            catch
            {
                // This is bad, but what can you do? We must depend on the runtime to never give us a bad index.
                return UInt64.max
            }
        }

        set(newValue)
        {
            do
            {
                try self.set(offset: position, to: newValue)
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

extension ParchmentMmap: BidirectionalCollection
{
    public func index(before i: UInt64) -> UInt64
    {
        return i - UInt64(1)
    }
}

extension ParchmentMmap: RandomAccessCollection
{
}

public class BadIterator: IteratorProtocol
{
    public typealias Element = UInt64

    public init()
    {
    }

    public func next() -> UInt64?
    {
        return nil
    }
}

public class ParchmentIterator: IteratorProtocol
{
    public typealias Element = UInt64

    let parchment: any Parchment
    var index: UInt64

    public init(_ parchment: any Parchment, _ index: UInt64)
    {
        self.parchment = parchment
        self.index = index
    }

    public func next() -> UInt64?
    {
        do
        {
            let result = try self.parchment.get(offset: self.index)
            self.index = self.index + 1
            return result
        }
        catch
        {
            return nil
        }
    }
}

public enum ParchmentError: Error
{
    case fileCouldNotBeCreated(URL)
    case noMmapFile
    case cannotAppend
    case fileDoesNotExist
    case fileSizeNotAligned(Int)
    case invalidSize(Int)
    case invalidOffset(UInt64)
    case fileExists
    case maxUInt64ValueNotAllowed
}
