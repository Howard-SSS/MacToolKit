//
//  BViewController.swift
//  MacToolKit
//
//  Created by Howard-Zjun on 2024/04/21.
//

import Cocoa
import Carbon

class BViewController: MTViewController {

    var index: Int = 0
    
    var colorArr: [NSColor] = [.white, .blue, .green]
    
    lazy var lab: NSTextField = {
        let lab = NSTextField(frame: .init(x: 0, y: 0, width: 200, height: 50))
        lab.isEditable = false
        lab.stringValue = "BViewController"
        lab.textColor = .black
        lab.alignment = .center
        return lab
    }()
    
    lazy var nextColorHintLab: NSTextField = {
        let whiteHintLab = NSTextField(frame: .init(x: 0, y: 50, width: 200, height: 50))
        whiteHintLab.isEditable = false
        whiteHintLab.stringValue = "next color hotkey: N"
        whiteHintLab.textColor = .black
        whiteHintLab.alignment = .center
        return whiteHintLab
    }()
    
    lazy var rotationHintLab: NSTextField = {
        let rotationHintLab = NSTextField(frame: .init(x: 0, y: 100, width: 200, height: 50))
        rotationHintLab.isEditable = false
        rotationHintLab.stringValue = "rotation hotkey: ⌃ + Q"
        rotationHintLab.textColor = .black
        rotationHintLab.alignment = .center
        return rotationHintLab
    }()
    
    lazy var popVCBtn: NSButton = {
        let popVCBtn = NSButton(frame: .init(x: 200, y: 200, width: 100, height: 50))
        popVCBtn.target = self
        popVCBtn.action = #selector(popVC)
        popVCBtn.title = "上一个控制器"
        popVCBtn.contentTintColor = .black
        return popVCBtn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer?.backgroundColor = .white
        view.addSubview(lab)
        view.addSubview(nextColorHintLab)
        view.addSubview(rotationHintLab)
        view.addSubview(popVCBtn)
    }
    
    override func registerHotkey() -> [MTHotKey] {
        [
            .init(sceneType: sceneId, target: self, selector: #selector(nextBackgroundColor), object: nil, keyCodes: [UInt16(kVK_ANSI_N)]),
            .init(sceneType: sceneId, keyCodes: [UInt16(kVK_ANSI_Q)], modifierFlasg: NSEvent.ModifierFlags.control.rawValue, task: { [unowned self] in
                guard let transform = popVCBtn.layer?.transform else {
                    return
                }
                popVCBtn.layer?.transform = CATransform3DTranslate(transform, 50, 0, 0)
            })
        ]
    }
    
    @objc func nextBackgroundColor() {
        index = (index + 1) % colorArr.count
        view.layer?.backgroundColor = colorArr[index].cgColor
    }
    
    @objc func popVC() {
        NSApplication.shared.keyWindow?.contentViewController = avc
    }
}
