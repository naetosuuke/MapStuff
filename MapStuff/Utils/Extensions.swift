//
//  Extensions.swift
//  MapStuff
//
//  Created by Daisuke Doi on 2023/02/11.
//

import UIKit

extension UIColor {
    
    
    static func rgb(red: CGFloat, green:CGFloat, blue: CGFloat) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }
    
    static func mainPink() -> UIColor {
        return UIColor.rgb(red: 221, green: 94, blue: 86)
    }
    
    static func mainBlue() -> UIColor {
        return UIColor.rgb(red: 55, green: 120, blue: 250)
    }
    
    static func directionsGreen() -> UIColor {
        return UIColor.rgb(red: 76, green: 217, blue: 100)
    }
    
}




extension UIView {
    
    func center(inView view: UIView) { //cellに使う
        self.translatesAutoresizingMaskIntoConstraints = false
        self.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant:0).isActive = true
        self.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant:0).isActive = true
    }
    
    func centerX(inView view: UIView) { //中心X座標を取得する
        self.translatesAutoresizingMaskIntoConstraints = false //trueだとAutoresizingMaskでレイアウト構成、falseだとAutoLayoutでレイタウトを構成　IB 使う時は強制的にFalse
        self.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant:0).isActive = true //CenterXAnchorの制約を有効
        //https://stackoverflow.com/questions/40739345/centering-uilabel-not-working
    }

    func centerY(inView view: UIView) { //中心Y座標を取得する
        self.translatesAutoresizingMaskIntoConstraints = false //trueだとAutoresizingMaskでレイアウト構成、falseだとAutoLayoutでレイタウトを構成　IB 使う時は強制的にFalse
        self.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant:0).isActive = true //CenterXAnchorの制約を有効
        //https://stackoverflow.com/questions/40739345/centering-uilabel-not-working
    }

    
    //ビューを全面に拡張する
    func addConstraintsToFillView(view: UIView) {
        self.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
    }
    
    
    //anchor sub views to our main view
    
    func anchor(top: NSLayoutYAxisAnchor?, left:NSLayoutXAxisAnchor? , bottom: NSLayoutYAxisAnchor?, right: NSLayoutXAxisAnchor?,paddingTop: CGFloat, paddingLeft:CGFloat, paddingBottom:CGFloat, paddingRight:CGFloat, width:CGFloat, height:CGFloat) {
        
        translatesAutoresizingMaskIntoConstraints = false
        
        if let top = top {
            self.topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
        }
        
        if let left = left {
            self.leftAnchor.constraint(equalTo: left, constant: paddingLeft).isActive = true
        }
    
        if let bottom = bottom {
            bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true // constantはマイナスの値で入れる
        }
        
        if let right = right {
            rightAnchor.constraint(equalTo: right, constant: -paddingRight).isActive = true // constantはマイナスの値で入れる
        }
        
        if width != 0 {
            self.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
        
        if height != 0 {
            self.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        
        
        
        
        
        
        
    }
    
    
    
    
}
