//
//  MTHotKeyCenter.swift
//  MacToolKit
//
//  Created by Howard-Zjun on 2024/04/21.
//

import Cocoa
import Carbon

public class MTHotKeyCenter: NSObject {

    static let `default`: MTHotKeyCenter = .init()
    
    var registerHotKeyDict: [String : [MTHotKey]] = [:]
    
//    var lock: NSLock = .init()
    
    private var operationQueue: OperationQueue = .init()
    
    private var monitor: Any?
    
    private var flagMonitor: Any?
    
    // 延迟响应模型，处理多个普通键连击
    private var lazyHandleModel: LazyHotKeyModel?
    
    private override init() {
        super.init()
        operationQueue.maxConcurrentOperationCount = 1
        addSceneListen()
    }
    
    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
        if let flagMonitor = flagMonitor {
            NSEvent.removeMonitor(flagMonitor)
        }
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
    
    // MARK: - 账号查找
    func findHotKey(hotkeyIdArr: [String], block: @escaping (([String : MTHotKey]) -> Void)) {
        weak var weakSelf = self
        operationQueue.addOperation {
            guard let strongSelf = weakSelf else {
                return
            }
            var result: [String : MTHotKey] = [:]
            for hotkeyId in hotkeyIdArr {
                let parts = hotkeyId.components(separatedBy: String.divisionPart)
                if parts.count != 2 {
                    continue
                }
                let sceneType = parts[0]
                let uuid = parts[1]
                let registerHotKeys = strongSelf.registerHotKeyDict[sceneType] ?? []
                for hotkey in registerHotKeys {
                    if hotkey.sceneType + .divisionPart + hotkey.uuid == hotkeyId {
                        result[hotkeyId] = hotkey
                        break
                    }
                }
            }
            block(result)
        }
    }
    
    // MARK: - 队列调度
    func register(sceneType: String = .globalScene, hotkeys: [MTHotKey]) {
        weak var weakSelf = self
        operationQueue.addOperation {
            guard let strongSelf = weakSelf else {
                return
            }
//            strongSelf.lock.lock()
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
//            strongSelf.lock.unlock()
        }
    }
    
    func unregister(sceneType: String = .globalScene, hotkeys: [MTHotKey]) {
        weak var weakSelf = self
        operationQueue.addOperation {
            guard let strongSelf = weakSelf else {
                return
            }
//            strongSelf.lock.lock()
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
//            strongSelf.lock.unlock()
        }
    }
    
    func unregister(sceneType: String = .globalScene) {
        weak var weakSelf = self
        operationQueue.addOperation {
            guard let strontSelf = weakSelf else {
                return
            }
            strontSelf.registerHotKeyDict[sceneType] = nil
        }
    }
    
    // MARK: - 响应
    func addSceneListen() {
        weak var weakSelf = self
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // 取消上一个延迟多键响应
            NSObject.cancelPreviousPerformRequests(withTarget: self)

            // 能够响应则直接返回
            if weakSelf?.handleCommonEvent(event: event) ?? false {
                return event
            }
            
            // 延时多键响应
            var lazyHandleModel = weakSelf?.lazyHandleModel ?? .init(modifierFlags: event.modifierFlags.rawValue, keyCodes: [])
            lazyHandleModel.modifierFlags = event.modifierFlags.rawValue
            lazyHandleModel.keyCodes.append(event.keyCode)
            weakSelf?.lazyHandleModel = lazyHandleModel
            weakSelf?.perform(#selector(weakSelf?.lazyHandleMoreEvent), with: nil, afterDelay: 0.2)
            
            return event
        }
        flagMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged, handler: { event in
            weakSelf?.handleFlagEvent(event: event)
            return event
        })
    }
    
    // 响应多普通键
    @discardableResult
    @objc func lazyHandleMoreEvent() -> Bool {
        guard let viewController = topMostViewController() as? MTViewController else {
            return false
        }
        guard let hotkeyArr = registerHotKeyDict[viewController.sceneId], let lazyHandleModel = lazyHandleModel else {
            return false
        }
        var handleResult = false
        let keyCodes = lazyHandleModel.keyCodes.sorted()
        let modifierFlags = lazyHandleModel.modifierFlags
        let temp = NSEvent.ModifierFlags(rawValue: lazyHandleModel.modifierFlags)
        for hotkey in hotkeyArr {
            if modifierFlags == 256 { // 不包含功能键
                if hotkey.modifierFlags == 256 && hotkey.keyCodes == keyCodes {
                    hotkey.invoke()
                    handleResult = true
                    break
                }
            } else {
                if hotkey.modifierFlags != 256 && temp.contains(.init(rawValue: hotkey.modifierFlags)) && hotkey.keyCodes == keyCodes {
                    hotkey.invoke()
                    handleResult = true
                    break
                }
            }
        }
        self.lazyHandleModel = nil
        return handleResult
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
        var handleResult = false
        for hotkey in hotkeyArr {
            if hotkey.keyCodes.isEmpty && event.modifierFlags.contains(.init(rawValue: hotkey.modifierFlags)) {
                hotkey.invoke()
                handleResult = true
                break
            }
        }
        return handleResult
    }
    
    // 响应功能键+单普通键
    @discardableResult
    func handleCommonEvent(event: NSEvent) -> Bool {
        guard let viewController = topMostViewController() as? MTViewController else {
            return false
        }
        guard let hotkeyArr = registerHotKeyDict[viewController.sceneId] else {
            return false
        }
        var handleResult = false
        for hotkey in hotkeyArr {
            if event.modifierFlags.rawValue == 256 { // 不包含功能键
                if hotkey.modifierFlags == 256 && hotkey.keyCodes.count == 1 && hotkey.keyCodes[0] == event.keyCode {
                    hotkey.invoke()
                    handleResult = true
                    break
                }
            } else {
                if hotkey.modifierFlags != 256 && event.modifierFlags.contains(.init(rawValue: hotkey.modifierFlags)) && hotkey.keyCodes.count == 1 && hotkey.keyCodes[0] == event.keyCode {
                    hotkey.invoke()
                    handleResult = true
                    break
                }
            }
        }
        return handleResult
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
    
    struct LazyHotKeyModel {
        
        var modifierFlags: UInt
        
        var keyCodes: [UInt16]
    }
    
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
