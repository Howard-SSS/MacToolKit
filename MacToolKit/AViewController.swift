//
//  AViewController.swift
//  MacToolKit
//
//  Created by Howard-Zjun on 2024/04/21.
//

import Cocoa
import Carbon
import AppKit

var avc: AViewController!

class AViewController: MTViewController {

    var index: Int = 0
    
    var colorArr: [NSColor] = [.white, .red, .orange]
    
    lazy var lab: NSTextField = {
        let lab = NSTextField(frame: .init(x: 0, y: 0, width: 200, height: 50))
        lab.isEditable = false
        lab.stringValue = "AViewController"
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
    
    lazy var presentVCBtn: NSButton = {
        let presentVCBtn = NSButton(frame: .init(x: 200, y: 200, width: 100, height: 50))
        presentVCBtn.target = self
        presentVCBtn.action = #selector(presentVC)
        presentVCBtn.title = "下一个控制器"
        presentVCBtn.contentTintColor = .black
        return presentVCBtn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer?.backgroundColor = .white
        view.addSubview(lab)
        view.addSubview(nextColorHintLab)
        view.addSubview(rotationHintLab)
        view.addSubview(presentVCBtn)
        avc = self
    }
    
    override func registerHotkey() -> [MTHotKey] {
        [
            .init(sceneType: sceneId, target: self, selector: #selector(nextBackgroundColor), object: nil, keyCode: UInt16(kVK_ANSI_N)),
            .init(sceneType: sceneId, keyCode: UInt16(kVK_ANSI_Q), modifierFlasg: NSEvent.ModifierFlags.control.rawValue, task: { [unowned self] event in
                guard let transform = presentVCBtn.layer?.transform else {
                    return
                }
                presentVCBtn.layer?.transform = CATransform3DRotate(transform, 0.5 * Double.pi, 0, 0, 1)
            })
        ]
    }
    
    @objc func nextBackgroundColor() {
        index = (index + 1) % colorArr.count
        view.layer?.backgroundColor = colorArr[index].cgColor
    }
    
    @objc func presentVC() {
        NSApplication.shared.keyWindow?.contentViewController = BViewController()
    }
}

class PresentationAnimator: NSObject, NSViewControllerPresentationAnimator {
    
    func animatePresentation(of viewController: NSViewController, from fromViewController: NSViewController) {
        
    }
    
    func animateDismissal(of viewController: NSViewController, from fromViewController: NSViewController) {
        
    }
}
