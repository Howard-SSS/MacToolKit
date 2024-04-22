//
//  MTHotKey.swift
//  MacToolKit
//
//  Created by Howard-Zjun on 2024/04/21.
//

import Cocoa

class MTHotKey: NSObject {
    
    let sceneType: String
    
    let uuid: String
    
    var target: NSObject?
    
    var selector: Selector?
    
    var object: Any?
    
    var task: (() -> Void)?
    
    var keyCodes: [UInt16]!
    
    var modifierFlags: UInt
    
    var queue: DispatchQueue?
    
    // 仅注册普通键响应
    convenience init(sceneType: String = .globalScene, target: NSObject, selector: Selector, object: Any?, keyCodes: [UInt16], queue: DispatchQueue? = nil) {
        self.init(sceneType: sceneType, target: target, selector: selector, object: object, keyCodes: keyCodes, modifierFlags: .notModifierFlags, queue: queue)
    }
    
    // 仅注册普通键响应
    convenience init(sceneType: String = .globalScene, keyCodes: [UInt16], queue: DispatchQueue? = nil, task: @escaping (() -> Void)) {
        self.init(sceneType: sceneType, keyCodes: keyCodes, modifierFlasg: .notModifierFlags, queue: queue, task: task)
    }
    
    // 仅注册功能键响应
    convenience init(sceneType: String = .globalScene, target: NSObject, selector: Selector, object: Any?, modifierFlags: UInt, queue: DispatchQueue? = nil) {
        self.init(sceneType: sceneType, target: target, selector: selector, object: object, keyCodes: [], modifierFlags: modifierFlags, queue: queue)
    }
    
    // 仅注册功能键响应
    convenience init(sceneType: String = .globalScene, modifierFlasg: UInt, queue: DispatchQueue? = nil, task: @escaping (() -> Void)) {
        self.init(sceneType: sceneType, keyCodes: [], modifierFlasg: modifierFlasg, queue: queue, task: task)
    }
    
    init(sceneType: String = .globalScene, target: NSObject, selector: Selector, object: Any?, keyCodes: [UInt16], modifierFlags: UInt, queue: DispatchQueue? = nil) {
        self.sceneType = sceneType
        self.uuid = UUID().uuidString
        self.target = target
        self.selector = selector
        self.keyCodes = keyCodes
        self.modifierFlags = modifierFlags
    }
    
    init(sceneType: String = .globalScene, keyCodes: [UInt16], modifierFlasg: UInt, queue: DispatchQueue? = nil, task: @escaping (() -> Void)) {
        self.sceneType = sceneType
        self.uuid = UUID().uuidString
        self.task = task
        self.keyCodes = keyCodes
        self.modifierFlags = modifierFlasg
    }
    
    func invoke() {
        let invokeQueue = queue ?? .main
        if let target = target, let selector = selector, target.responds(to: selector) {
            weak var weakSelf = self
            invokeQueue.async {
                target.perform(selector, with: weakSelf?.object)
            }
        } else if let task = task {
            invokeQueue.async {
                task()
            }
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let tempObject = object as? MTHotKey else {
            return false
        }
        return keyCodes == tempObject.keyCodes && modifierFlags == tempObject.modifierFlags
    }
}
