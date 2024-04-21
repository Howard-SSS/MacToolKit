//
//  MTHotKey.swift
//  MacToolKit
//
//  Created by Howard-Zjun on 2024/04/21.
//

import Cocoa

class MTHotKey: NSObject {

    var sceneType: String
    
    var target: NSObject?
    
    var selector: Selector?
    
    var object: Any?
    
    var task: ((NSEvent) -> Void)?
    
    var keyCode: UInt16
    
    var modifierFlags: UInt
    
    var queue: DispatchQueue?
    
    // 仅注册普通键响应
    convenience init(sceneType: String = .globalScene, target: NSObject, selector: Selector, object: Any?, keyCode: UInt16, queue: DispatchQueue? = nil) {
        self.init(sceneType: sceneType, target: target, selector: selector, object: object, keyCode: keyCode, modifierFlags: .notModifierFlags, queue: queue)
    }
    
    // 仅注册普通键响应
    convenience init(sceneType: String = .globalScene, keyCode: UInt16, queue: DispatchQueue? = nil, task: @escaping ((NSEvent) -> Void)) {
        self.init(sceneType: sceneType, keyCode: keyCode, modifierFlasg: .notModifierFlags, queue: queue, task: task)
    }
    
    // 仅注册功能键响应
    convenience init(sceneType: String = .globalScene, target: NSObject, selector: Selector, object: Any?, modifierFlags: UInt, queue: DispatchQueue? = nil) {
        self.init(sceneType: sceneType, target: target, selector: selector, object: object, keyCode: .notKeyCode, modifierFlags: modifierFlags, queue: queue)
    }
    
    // 仅注册功能键响应
    convenience init(sceneType: String = .globalScene, modifierFlasg: UInt, queue: DispatchQueue? = nil, task: @escaping ((NSEvent) -> Void)) {
        self.init(sceneType: sceneType, keyCode: .notKeyCode, modifierFlasg: modifierFlasg, queue: queue, task: task)
    }
    
    init(sceneType: String = .globalScene, target: NSObject, selector: Selector, object: Any?, keyCode: UInt16, modifierFlags: UInt, queue: DispatchQueue? = nil) {
        self.sceneType = sceneType
        self.target = target
        self.selector = selector
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
    }
    
    init(sceneType: String = .globalScene, keyCode: UInt16, modifierFlasg: UInt, queue: DispatchQueue? = nil, task: @escaping ((NSEvent) -> Void)) {
        self.sceneType = sceneType
        self.task = task
        self.keyCode = keyCode
        self.modifierFlags = modifierFlasg
    }
    
    func invoke(event: NSEvent) {
        let invokeQueue = queue ?? .main
        if let target = target, let selector = selector, target.responds(to: selector) {
            weak var weakSelf = self
            invokeQueue.async {
                target.perform(selector, with: weakSelf?.object)
            }
        } else if let task = task {
            invokeQueue.async {
                task(event)
            }
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let tempObject = object as? MTHotKey else {
            return false
        }
        return keyCode == tempObject.keyCode && modifierFlags == tempObject.modifierFlags
    }
}
