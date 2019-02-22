//
//  RecordingLabel.swift
//  VideoRecording
//
//  Created by Stephen Chui on 2018/12/27.
//  Copyright © 2018 Stephen Chui. All rights reserved.
//

import UIKit

open class RecordingLabel: UIView {

    // Red dot view
    private(set) var flashView: FlashView! {
        didSet {
            flashView.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    // Count label
    private(set) var countLabel: UILabel! {
        didSet {
            countLabel.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
            countLabel.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            countLabel.textAlignment = .center
            countLabel.text = "00 : 00 : 00"
            countLabel.font = UIFont(name: "Menlo-Bold", size: 16)
            countLabel.layer.cornerRadius = 10
            countLabel.layer.masksToBounds = true
            countLabel.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private var timer: Timer?
    private var startDate: Date!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }
    
    private func setupViews() {
        countLabel = UILabel()
        self.addSubview(countLabel)
        countLabel.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        countLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        countLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        countLabel.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.9).isActive = true
        
        flashView = FlashView()
        self.addSubview(flashView)
        flashView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        flashView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        flashView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        flashView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.1).isActive = true
    }
    
    
    // MARK: - Start / stop counting
    
    public func start() {
        startDate = Date()
        reset()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(startCounting), userInfo: nil, repeats: true)
    }
    
    @objc private func startCounting() {
        flashView.startFlash()
        
        let currentDate = Date()
        
        let difference = currentDate.timeIntervalSince(startDate)
        print(difference)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH : mm : ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        let date = Date(timeIntervalSinceReferenceDate: difference)
        print(formatter.string(from: date))

        countLabel.text = ("\(formatter.string(from: date))")
    }
    
    public func stop() {
        flashView.startFlash()
        timer?.invalidate()
        timer = nil
    }

    private func reset() {
        countLabel.text = "00 : 00 : 00"
        flashView.stopFlash()
    }
}

protocol Flashable {
    func startFlash()
    func stopFlash()
}

public class FlashView: UIView {
    
    private(set) var redView: UIView = {
        var _view = UIView()
        _view.backgroundColor = .red
        _view.layer.cornerRadius = 5
        _view.layer.masksToBounds = true
        _view.translatesAutoresizingMaskIntoConstraints = false
        return _view
    }()
    
    
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
        self.addSubview(redView)
        redView.widthAnchor.constraint(equalToConstant: 10).isActive = true
        redView.heightAnchor.constraint(equalToConstant: 10).isActive = true
        redView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        redView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
    }
}

extension Flashable where Self: FlashView {
    
    func startFlash() {
        redView.alpha = 1.0
        UIView.animate(withDuration: 1.0, delay: 0.0, options: [.repeat, .autoreverse], animations: {
            self.redView.alpha = 0.0
        }, completion: nil)
    }
    
    func stopFlash() {
        redView.alpha = 1.0
    }
}

extension FlashView: Flashable { }
