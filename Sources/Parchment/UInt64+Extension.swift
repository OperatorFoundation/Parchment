//
//  UInt64+Extension.swift
//  
//
//  Created by Dr. Brandon Wiley on 8/13/22.
//

import Foundation

extension UInt64
{
    init(_ tuple: (UInt32, UInt32))
    {
        let (i0, i1) = tuple
        let result = (UInt64(i0) << 32) + UInt64(i1)
        self = result
    }

    init(_ tuple: (UInt16, UInt16, UInt16, UInt16))
    {
        let (i0, i1, i2, i3) = tuple
        let r0 = (UInt64(i0) << (16*3))
        let r1 = (UInt64(i1) << (16*2))
        let r2 = (UInt64(i2) << 16)
        let r3 =  UInt64(i3)
        let result = r0 + r1 + r2 + r3
        self = result
    }

    init(_ tuple: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8))
    {
        let (i0, i1, i2, i3, i4, i5, i6, i7) = tuple
        let r0 = (UInt64(i0) << (8*7))
        let r1 = (UInt64(i1) << (8*6))
        let r2 = (UInt64(i2) << (8*5))
        let r3 = (UInt64(i3) << (8*4))
        let r4 = (UInt64(i4) << (8*3))
        let r5 = (UInt64(i5) << (8*2))
        let r6 = (UInt64(i6) << 8)
        let r7 =  UInt64(i7)
        let result =  r0 + r1 + r2 + r3 + r4 + r5 + r6 + r7
        self = result
    }

    init(int64: Int64)
    {
        self.init(bitPattern: int64)
    }

    func split() -> (UInt32, UInt32)
    {
        let i0 = UInt32(self >> 32)
        let i1 = UInt32((self << 32) >> 32)
        return (i0, i1)
    }

    func split() -> (UInt16, UInt16, UInt16, UInt16)
    {
        let i0 = UInt16(self >> (16*3))
        let i1 = UInt16((self << 16) >> (16*3))
        let i2 = UInt16((self << (16*2)) >> (16*3))
        let i3 = UInt16((self << (16*3)) >> (16*3))
        return (i0, i1, i2, i3)
    }

    func split() -> (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)
    {
        let i0 = UInt8(self >> (8*7))
        let i1 = UInt8((self << 8) >> (8*7))
        let i2 = UInt8((self << (8*2)) >> (8*7))
        let i3 = UInt8((self << (8*3)) >> (8*7))
        let i4 = UInt8((self << (8*4)) >> (8*7))
        let i5 = UInt8((self << (8*5)) >> (8*7))
        let i6 = UInt8((self << (8*6)) >> (8*7))
        let i7 = UInt8((self << (8*7)) >> (8*7))
        return (i0, i1, i2, i3, i4, i5, i6, i7)
    }

    var int64: Int64
    {
        return Int64(bitPattern: self)
    }
}
