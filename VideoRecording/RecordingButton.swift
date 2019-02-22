//
//  RecordingButton.swift
//  VideoRecording
//
//  Created by Stephen Chui on 2018/12/27.
//  Copyright © 2018 Stephen Chui. All rights reserved.
//

import UIKit

public class RecordingButton: UIButton {

    public enum RecordingState {
        case start, stop
    }
    public var recordingState: RecordingState = .stop {
        didSet {
            updateButtonState()
        }
    }
    
    private(set) var circleView: UIView!
    private var circleViewRadius: CGFloat {
        get {
            return circleView.bounds.width / 2
        }
    }
    private var circleViewFrame: CGRect {
        get {
            return CGRect(x: 15, y: 15, width: self.bounds.width - 30, height: self.bounds.height - 30)
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    private func setupViews() {
        self.backgroundColor = .clear
        
        // Circle view
        CircleView: do {
            circleView = UIView(frame: circleViewFrame)
            circleView.backgroundColor = .red
            circleView.layer.cornerRadius = circleViewRadius
            circleView.isUserInteractionEnabled = false
            self.addSubview(circleView)
        }
        
        // Circle path
        CirclePath: do {
            let circlePath = UIBezierPath(arcCenter: self.center, radius: (self.bounds.width - 4) / 2, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
            
            let pathLayer = CAShapeLayer()
            pathLayer.strokeColor = UIColor.white.cgColor
            pathLayer.fillColor = UIColor.clear.cgColor
            pathLayer.lineWidth = 4.0
            pathLayer.path = circlePath.cgPath
            
            layer.addSublayer(pathLayer)
        }
    }
    
    public func updateButtonState() {
        DispatchQueue.main.async {
            switch self.recordingState {
            case .start:
                UIView.animate(withDuration: 0.3, animations: {
                    self.circleView.backgroundColor = .white
                    self.circleView.layer.cornerRadius = 2
                    self.circleView.frame = CGRect(x: 20, y: 20, width: self.bounds.width - 40, height: self.bounds.height - 40)
                })
            case .stop:
                UIView.animate(withDuration: 0.3, animations: {
                    self.circleView.backgroundColor = .red
                    self.circleView.frame = self.circleViewFrame
                    self.circleView.layer.cornerRadius = self.circleViewRadius
                })
            }
        }
    }
}
