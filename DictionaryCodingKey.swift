//
//  DictionaryCodingKey.swift
//  Consumer
//
//  Created by Artem Kuprijanets on 6/13/19.
//  Copyright © 2019 RedTeam. All rights reserved.
//

internal struct DictionaryCodingKey : CodingKey {
  public var stringValue: String
  public var intValue: Int?
  
  public init?(stringValue: String) {
    self.stringValue = stringValue
    self.intValue = nil
  }
  
  public init?(intValue: Int) {
    self.stringValue = "\(intValue)"
    self.intValue = intValue
  }
  
  public init(stringValue: String, intValue: Int?) {
    self.stringValue = stringValue
    self.intValue = intValue
  }
  
  internal init(index: Int) {
    self.stringValue = "Index \(index)"
    self.intValue = index
  }
  
  internal static let `super` = DictionaryCodingKey(stringValue: "super")!
}

