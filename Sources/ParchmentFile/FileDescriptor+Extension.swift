//
//  FileDescriptor+Extension.swift
//  Parchment
//
//  Created by Dr. Brandon Wiley on 1/11/23.
//

import Foundation
import SystemPackage

import Datable

extension FileDescriptor
{
    // Public
    public func get(offset uint64Offset: UInt64) throws -> UInt64
    {
        let byteOffset: Int = Int(uint64Offset) * 8
        return try self.get(byteOffset: byteOffset, length: 8)
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

    // Private
    func set(byteOffset: Int, to uint64: UInt64) throws
    {
        guard byteOffset >= 0 else
        {
            throw FileDescriptorError.outOfBounds
        }

        guard let data = uint64.maybeNetworkData else
        {
            throw FileDescriptorError.dataConversionFailed
        }

        try self.storeBytes(of: data, toByteOffset: byteOffset)
    }

    func get(byteOffset: Int, length: Int) throws -> UInt64
    {
        guard byteOffset >= 0 else
        {
            throw FileDescriptorError.outOfBounds
        }

        let data = try self.load(fromByteOffset: byteOffset, length: UInt64.bitWidth / 8)
        guard let uint64 = UInt64(maybeNetworkData: data) else
        {
            throw FileDescriptorError.dataConversionFailed
        }
        
        return uint64
    }

    func storeBytes(of data: Data, toByteOffset: Int) throws
    {
        try self.seek(offset: Int64(toByteOffset), from: .start)
        try self.writeAll(data)
    }

    func load(fromByteOffset: Int, length: Int) throws -> Data
    {
        try self.seek(offset: Int64(fromByteOffset), from: .start)

        var buffer = Data(count: length)
        let _ = try buffer.withUnsafeMutableBytes
        {
            pointer in

            try self.read(into: pointer)
        }

        return buffer
    }
}

public enum FileDescriptorError: Error
{
    case outOfBounds
    case dataConversionFailed
}
