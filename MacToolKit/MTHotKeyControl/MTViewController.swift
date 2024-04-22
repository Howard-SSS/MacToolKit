//
//  MTViewController.swift
//  MacToolKit
//
//  Created by Howard-Zjun on 2024/04/19.
//

import Cocoa

open class MTViewController: NSViewController, MTHotKeyControlProtocol {
    
    final var sceneId: String {
        NSStringFromClass(Self.self)
    }
    
    var hotkeyIdArr: [String] = []
    
    func registerHotkey() -> [MTHotKey] {
        fatalError("需要实现 MTViewController")
    }
    
    open override func viewDidAppear() {
        super.viewDidAppear()
        let hotkeys = registerHotkey()
        hotkeyIdArr = hotkeys.map({$0.sceneType + .divisionPart + $0.uuid})
        MTHotKeyCenter.default.register(sceneType: sceneId, hotkeys: hotkeys)
    }
    
    open override func viewDidDisappear() {
        super.viewDidDisappear()
        MTHotKeyCenter.default.unregister(sceneType: sceneId)
    }
}
