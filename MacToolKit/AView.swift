//
//  AView.swift
//  MacToolKit
//
//  Created by Howard-Zjun on 2024/04/22.
//

import Cocoa
import Carbon

class AView: MTView {

    override func registerHotkey() -> [MTHotKey] {
        [
            .init(keyCodes: [UInt16(kVK_ANSI_R)], task: { [unowned self] in
                frame.origin.x += 10
            })
        ]
    }
}
