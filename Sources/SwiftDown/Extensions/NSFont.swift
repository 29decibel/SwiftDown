//
//  NSFont.swift
//  SampleApp
//
//  Created by Quentin Eude on 01/02/2021.
//
#if os(macOS)
  import Foundation
  import AppKit

  extension NSFont {
    var bold: NSFont {
      return with(.bold)
    }

    var italic: NSFont {
      return with(.italic)
    }

    var boldItalic: NSFont {
      return with([.bold, .italic])
    }

    func with(_ traits: NSFontDescriptor.SymbolicTraits...) -> NSFont {
      let traitSet: NSFontDescriptor.SymbolicTraits = NSFontDescriptor.SymbolicTraits(traits)
        .union(
          self.fontDescriptor.symbolicTraits)
      let descriptor: NSFontDescriptor = self.fontDescriptor.withSymbolicTraits(traitSet)
      return NSFont(descriptor: descriptor, size: 0) ?? self
    }

    func without(_ traits: NSFontDescriptor.SymbolicTraits...) -> NSFont {
      let traitSet = self.fontDescriptor.symbolicTraits.subtracting(
        NSFontDescriptor.SymbolicTraits(traits))
      let descriptor = self.fontDescriptor.withSymbolicTraits(traitSet)
      return NSFont(descriptor: descriptor, size: 0) ?? self
    }
  }
#endif
