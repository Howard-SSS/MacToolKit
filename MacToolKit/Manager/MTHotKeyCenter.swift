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
    
    private var queue: OperationQueue = .init()
    
    private var monitor: Any?
    
    private var flagMonitor: Any?
    
    private override init() {
        super.init()
        queue.maxConcurrentOperationCount = 1
        addSceneListen()
    }
    
    private func registerGlobal(hotkey: MTHotKey) {
//        let keyCode: UInt32 = UInt32(hotkey.keyCode)
//        let modifierFlags = appkitModifiersToCarbonModifiers(modifierFlags: hotkey.modifierFlags)
//        let hotkeyId = EventHotKeyID(signature: 11, id: 1)
//        var pointer: UnsafeMutablePointer<EventHotKeyRef?>!
//        RegisterEventHotKey(keyCode, modifierFlags, hotkeyId, GetEventDispatcherTarget(), 0, pointer)
//        hotkey.hotkeyRef = pointer.pointee
    }
    
    private func unregisterGlobal(hotkey: MTHotKey) {
//        guard let hotkeyRef = hotkey.hotkeyRef else {
//            return
//        }
//        UnregisterEventHotKey(hotkeyRef)
    }
    
    // MARK: - 队列调度
    func register(sceneType: String = .globalScene, hotkeys: [MTHotKey]) {
        register(sceneType: sceneType, hotkeys: hotkeys, operationQueue: queue)
    }
    
    func unregister(sceneType: String = .globalScene, hotkeys: [MTHotKey]) {
        unregister(sceneType: sceneType, hotkeys: hotkeys, operationQueue: queue)
    }
    
    // 指定队列调度注册快捷键
    private func register(sceneType: String, hotkeys: [MTHotKey], operationQueue: OperationQueue) {
        weak var weakSelf = self
        operationQueue.addOperation {
            guard let strongSelf = weakSelf else {
                return
            }
            strongSelf.lock.lock()
            if sceneType == .globalScene {
                for hotkey in hotkeys {
                    strongSelf.registerGlobal(hotkey: hotkey)
                }
            } else {
                var registerHotKeys = strongSelf.registerHotKeyDict[sceneType] ?? []
                for hotkey in hotkeys {
                    if let index: Int = registerHotKeys.firstIndex(of: hotkey) {
                        registerHotKeys[index] = hotkey
                    } else {
                        registerHotKeys.append(hotkey)
                    }
                }
                strongSelf.registerHotKeyDict[sceneType] = registerHotKeys
            }
            strongSelf.lock.unlock()
        }
    }
    
    // 指定队列注销快捷键
    private func unregister(sceneType: String, hotkeys: [MTHotKey], operationQueue: OperationQueue) {
        weak var weakSelf = self
        operationQueue.addOperation {
            guard let strongSelf = weakSelf else {
                return
            }
            strongSelf.lock.lock()
            if sceneType == .globalScene {
                for hotkey in hotkeys {
                    strongSelf.unregisterGlobal(hotkey: hotkey)
                }
            } else {
                var registerHotKeyArr = strongSelf.registerHotKeyDict[sceneType] ?? []
                for hotkey in hotkeys {
                    if let index = registerHotKeyArr.firstIndex(of: hotkey) {
                        registerHotKeyArr.remove(at: index)
                        break
                    }
                }
                strongSelf.registerHotKeyDict[sceneType] = registerHotKeyArr
            }
            strongSelf.lock.unlock()
        }
    }
    
    // MARK: - 响应
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
