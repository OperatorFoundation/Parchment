//
//  MmapFile.swift
//  
//
//  Created by Dr. Brandon Wiley on 8/13/22.
//

import Darwin.C.errno
import Foundation
import SystemPackage

import Datable
import MmapCDarwin

public class MmapFile
{
    public let fd: FileDescriptor
    public let offset: Int
    public let size: Int
    public let fileSize: Int
    let memory: UnsafeMutableRawPointer

    public init(_ url: URL, offset: Int = 0, size: Int? = nil) throws
    {
        guard offset >= 0 else
        {
            throw MmapFileError.invalidOffset
        }

        self.offset = offset

        let path = url.path
        self.fd = try FileDescriptor.open(path, .readWrite)

        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let result = attrs[.size] else
        {
            throw MmapFileError.noFileSize
        }

        guard let fileSize = result as? Int else
        {
            throw MmapFileError.noFileSize
        }
        self.fileSize = fileSize

        guard offset < fileSize else
        {
            throw MmapFileError.invalidOffset
        }

        if let size = size
        {
            guard offset + size <= fileSize else
            {
                throw MmapFileError.invalidSize
            }

            self.size = size
        }
        else
        {
            self.size = fileSize
        }

        guard let resultPointer = mmap(nil, self.size, PROT_READ | PROT_WRITE, MAP_SHARED, self.fd.rawValue, Int64(self.offset)) else
        {
            throw MmapFileError.mmapFailed
        }

        self.memory = resultPointer
    }

    // Public
    public func set(offset uint64Offset: UInt64, to uint64s: [UInt64]) throws
    {
        for (index, uint64) in uint64s.enumerated()
        {
            let offset = uint64Offset + UInt64(index)
            try self.set(offset: offset, to: uint64)
        }
    }

    public func set(offset uint64Offset: UInt64, to uint64: UInt64) throws
    {
        let byteOffset: Int = Int(uint64Offset) * 8
        try self.set(byteOffset: byteOffset, to: uint64)
    }

    public func get(offset uint64Offset: UInt64, length: UInt64) throws -> [UInt64]
    {
        var results: [UInt64] = []

        for index in 0..<length
        {
            let offset: UInt64 = uint64Offset + index
            let uint64 = try self.get(offset: offset)
            results.append(uint64)
        }

        return results
    }

    public func get(offset uint64Offset: UInt64) throws -> UInt64
    {
        let byteOffset: Int = Int(uint64Offset) * 8
        return try self.get(byteOffset: byteOffset, length: 8)
    }

    // Private
    func set(byteOffset: Int, to uint64: UInt64) throws
    {
        guard byteOffset >= 0, byteOffset < self.size else
        {
            throw MmapFileError.outOfBounds
        }

        guard (byteOffset + 8) >= 0, (byteOffset + 8) <= self.size else
        {
            throw MmapFileError.outOfBounds
        }

        self.memory.storeBytes(of: uint64, toByteOffset: byteOffset, as: UInt64.self)

        let result = msync(self.memory, self.size, MS_SYNC)
        guard result == 0 else
        {
            print(errno)
            throw MmapFileError.msyncFailed
        }
    }

    func get(byteOffset: Int, length: Int) throws -> UInt64
    {
        guard byteOffset >= 0, byteOffset < self.size else
        {
            throw MmapFileError.outOfBounds
        }

        guard (byteOffset + length) >= 0, (byteOffset + length) <= self.size else
        {
            throw MmapFileError.outOfBounds
        }

        return self.memory.load(fromByteOffset: byteOffset, as: UInt64.self)
    }

    deinit
    {
        munmap(self.memory, self.size)

        do
        {
            try self.fd.close()
        }
        catch
        {
            return
        }
    }
}

public enum MmapFileError: Error
{
    case outOfBounds
    case mmapFailed
    case msyncFailed
    case noFileSize
    case invalidOffset
    case invalidSize
}
