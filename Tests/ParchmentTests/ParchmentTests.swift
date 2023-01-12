import XCTest
import SystemPackage

@testable import ParchmentMmap
import Datable
import Gardener
import Mmap

final class ParchmentTests: XCTestCase
{
    func testMmapFile() throws
    {
        let url = URL(fileURLWithPath: "/Users/dr.brandonwiley/Amethyst/test.data")
        let fd = try FileDescriptor.open(url.path, .readWrite)
        let v1: UInt64 = 1
        let v2: UInt64 = 2
        try fd.writeAll(v1.maybeNetworkData!)
        try fd.writeAll(v2.maybeNetworkData!)
        try fd.close()

        let _ = File.touch(url.path)

        let startdata: UInt64 = 23
        let enddata: UInt64 = 42

        let mapped = try MmapFile(url)

        try mapped.set(offset: 0, to: startdata)

        let result1 = try mapped.get(offset: 0)
        XCTAssertEqual(startdata, result1)

        try mapped.set(offset: 1, to: enddata)

        let result2 = try mapped.get(offset: 1)
        XCTAssertEqual(enddata, result2)

        try mapped.set(offset: 0, to: [3, 4])
        let result3 = try mapped.get(offset: 0, length: 2)
        XCTAssertEqual([3, 4], result3)
    }

    func testParchment() throws
    {
        let url = URL(fileURLWithPath: "/Users/dr.brandonwiley/Amethyst/test.data")

        if File.exists(url.path)
        {
            guard File.delete(atPath: url.path) else
            {
                XCTFail()
                return
            }
        }

        let parchment = try ParchmentMmap(url)

        try parchment.append(1)
        try parchment.append(2)

        let result1 = try parchment.get(offset: 0)
        XCTAssertEqual(1, result1)

        let result2 = try parchment.get(offset: 1)
        XCTAssertEqual(2, result2)
    }

    func testRandomAccessCollection() throws
    {
        let url = URL(fileURLWithPath: "/Users/dr.brandonwiley/Amethyst/test.data")

        if File.exists(url.path)
        {
            guard File.delete(atPath: url.path) else
            {
                XCTFail()
                return
            }
        }

        let parchment = try ParchmentMmap(url)

        try parchment.append(1)
        try parchment.append(2)

        let result1 = parchment[0]
        XCTAssertEqual(1, result1)

        let result2 = parchment[1]
        XCTAssertEqual(2, result2)
    }
}
