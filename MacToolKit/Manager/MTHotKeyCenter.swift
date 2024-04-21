//
//  MTHotKeyCenter.swift
//  MacToolKit
//
//  Created by Howard-Zjun on 2024/04/21.
//

import Cocoa
import Carbon

class MTHotKeyCenter: NSObject {

    static let `default`: MTHotKeyCenter = .init()
    
    var registerHotKeyDict: [String : [MTHotKey]] = [:]
    
    var lock: NSLock = .init()
    
    private var queue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    private var monitor: Any?
    
    private var flagMonitor: Any?
    
    private override init() {
        super.init()
        addSceneListen()
    }
    
    func register(sceneType: String = .globalScene, hotkeys: [MTHotKey]) {
        weak var weakSelf = self
        queue.addOperation {
            weakSelf?.registerInQeueu(sceneType: sceneType, hotkeys: hotkeys)
        }
    }
    
    func unregister(sceneType: String = .globalScene, hotkeys: [MTHotKey]) {
        weak var weakSelf = self
        queue.addOperation {
            weakSelf?.unregisterInQueue(sceneType: sceneType, hotkeys: hotkeys)
        }
    }
    
    private func registerGlobal(hotkey: MTHotKey) {
//        let keyCode: UInt32 = UInt32(hotkey.keyCode)
//        let modifierFlags = appkitModifiersToCarbonModifiers(modifierFlags: hotkey.modifierFlags)
//        let hotkeyId = EventHotKeyID(signature: 11, id: 1)
//        var pointer: UnsafeMutablePointer<EventHotKeyRef?>
//        RegisterEventHotKey(keyCode, modifierFlags, hotkeyId, GetEventDispatcherTarget(), 0, pointer)
    }
    
    private func unregisterGlobal(hotkey: MTHotKey) {

    }
    
    private func registerInQeueu(sceneType: String, hotkeys: [MTHotKey]) {
        lock.lock()
        if sceneType == .globalScene {
            for hotkey in hotkeys {
                registerGlobal(hotkey: hotkey)
            }
        } else {
            var registerHotKeys = registerHotKeyDict[sceneType] ?? []
            for hotkey in hotkeys {
                if let index: Int = registerHotKeys.firstIndex(of: hotkey) {
                    registerHotKeys[index] = hotkey
                } else {
                    registerHotKeys.append(hotkey)
                }
            }
            registerHotKeyDict[sceneType] = registerHotKeys
        }
        lock.unlock()
    }
    
    private func unregisterInQueue(sceneType: String, hotkeys: [MTHotKey]) {
        lock.lock()
        if sceneType == .globalScene {
            for hotkey in hotkeys {
                unregisterGlobal(hotkey: hotkey)
            }
        } else {
            var registerHotKeyArr = registerHotKeyDict[sceneType] ?? []
            for hotkey in hotkeys {
                if let index = registerHotKeyArr.firstIndex(of: hotkey) {
                    registerHotKeyArr.remove(at: index)
                    break
                }
            }
            registerHotKeyDict[sceneType] = registerHotKeyArr
        }
        lock.unlock()
    }
    
    func addSceneListen() {
        weak var weakSelf = self
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            weakSelf?.handleCommonEvent(event: event)
            return event
        }
        flagMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged, handler: { event in
            weakSelf?.handleFlagEvent(event: event)
            return event
        })
    }
    
    // 响应功能键
    @discardableResult
    func handleFlagEvent(event: NSEvent) -> Bool {
        guard let viewController = topMostViewController() as? MTViewController else {
            return false
        }
        guard let hotkeyArr = registerHotKeyDict[viewController.sceneId] else {
            return false
        }
        for hotkey in hotkeyArr {
            if hotkey.keyCode == .notKeyCode && hotkey.modifierFlags == event.modifierFlags.rawValue {
                hotkey.invoke(event: event)
                break
            }
        }
        return true
    }
    
    // 响应功能键+普通键
    @discardableResult
    func handleCommonEvent(event: NSEvent) -> Bool {
        guard let viewController = topMostViewController() as? MTViewController else {
            return false
        }
        guard let hotkeyArr = registerHotKeyDict[viewController.sceneId] else {
            return false
        }
        for hotkey in hotkeyArr {
            if event.modifierFlags.rawValue == 256 { // 不包含功能键
                if hotkey.keyCode == event.keyCode {
                    hotkey.invoke(event: event)
                    break
                }
            } else {
                if hotkey.keyCode == event.keyCode && event.modifierFlags.contains(.init(rawValue: hotkey.modifierFlags)) {
                    hotkey.invoke(event: event)
                    break
                }
            }
        }
        return true
    }
    
    func appkitModifiersToCarbonModifiers(modifierFlags: UInt) -> UInt32 {
        var ret: UInt32 = 0
        let arr: [(NSEvent.ModifierFlags, Int)] = [
            (.shift, shiftKey),
            (.control, controlKey),
            (.command, cmdKey),
            (.option, optionKey)
        ]
        for tuple in arr {
            if (modifierFlags & tuple.0.rawValue) > 0 {
                ret |= UInt32(tuple.1)
            }
        }
        return ret
    }
}

extension MTHotKeyCenter {
    
    func topMostViewController() -> NSViewController? {
        guard let contentView = NSApplication.shared.keyWindow?.contentView else { return nil }
          
        // 如果 contentView 是一个 NSViewController 的视图，则直接返回该控制器
        if let viewController = contentView.nextResponder as? NSViewController {
            return viewController
        }
          
        // 否则，遍历 subviews 来找到视图控制器
        for subview in contentView.subviews {
            if let viewController = subview.nextResponder as? NSViewController {
                return viewController
            }
        }
          
        return nil
    }
}
