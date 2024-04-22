//
//  MTView.swift
//  MacToolKit
//
//  Created by Howard-Zjun on 2024/04/22.
//

import Cocoa

open class MTView: NSView, MTHotKeyControlProtocol {
    
    var hotkeyIdArr: [String] = []
    
    func registerHotkey() -> [MTHotKey] {
        fatalError("需要实现 MTView")
    }
    
    open override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        if let newWindow = newWindow { // 添加到窗口上
            if let mtViewController = newWindow.contentViewController as? MTViewController {
                let hotkeys = registerHotkey()
                hotkeyIdArr = hotkeys.map({$0.sceneType + .divisionPart + $0.uuid})
                MTHotKeyCenter.default.register(sceneType: mtViewController.sceneId, hotkeys: hotkeys)
            } else {
                print("基于 ViewController 所以需要在 MTViewController 上使用")
            }
        } else { // 从窗口移除
            if let mtViewController = window?.contentViewController as? MTViewController {
                MTHotKeyCenter.default.unregister(sceneType: mtViewController.sceneId)
            }
        }
    }
}
