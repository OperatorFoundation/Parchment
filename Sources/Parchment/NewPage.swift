//
//  NewPage.swift
//  
//
//  Created by Dr. Brandon Wiley on 8/18/22.
//

import Foundation

public class NewPage
{
    let values: [UInt64]

    public convenience init(value: UInt64)
    {
        self.init(values: [value])
    }

    public init(values: [UInt64])
    {
        self.values = values
    }
}
