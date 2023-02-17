//
//  LocationRequest.swift
//  MapStuff
//
//  Created by Daisuke Doi on 2023/02/11.
//

import UIKit
import CoreLocation

class LocationRequestController: UIViewController {
        
    
    
    //MARK: - Properties
    
    var locationManager: CLLocationManager?
    
    let imageView: UIImageView = { //クロージャ使ってイニシャライズしてる
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.image = UIImage(named: "blue-pin")
        return iv
    }()
    
    let allowLocationLabel: UILabel = {
        let label = UILabel()
        
        let attributedText = NSMutableAttributedString(string: "Allow Location\n", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)])
        
        attributedText.append(NSAttributedString(string: "Please enable location services so that we  can track your movements", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize:16)]))
                              
        label.numberOfLines = 0 //ラベルの表示行数　0だと無制限
        label.textAlignment = .center
        label.attributedText = attributedText
        
        
        return label
    }()
    
    let enableLocationButton: UIButton = {
        let button = UIButton(type:  .system)
        button.setTitle("Enable Location", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.backgroundColor = .mainBlue() //UIColor型のstaticメソッドとして宣言しているので、型記載およびイニシャライズを省略できる
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(handleRequestLocation), for: .touchUpInside)
        
        return button
    }()
    
    
    
    //MARK: - Init
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViewComponents()
        if locationManager != nil { //MapControllerがもつlocationManagerのインスタンスをLocationRequestに渡せていれば
            print ("Did set location manager..")
        } else {
            print("Error setting locatin manager..")
        }
    }
    
    
    
    //MARK: - Selector
    @objc func handleRequestLocation() {
        guard let locationManager = self.locationManager else { return } //locationManagerを自クラスで取得できていれば
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

    }
    
    //MARK: - Helper Function
    func configureViewComponents() {
        view.backgroundColor = .white
     
        view.addSubview(imageView)
        imageView.anchor(top: view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 140, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 200, height: 200) //anchorメソッドでサイズを決められる
        imageView.centerX(inView: view)
        
        view.addSubview(allowLocationLabel)
        allowLocationLabel.anchor(top: imageView.bottomAnchor, left: view.leftAnchor , bottom: nil, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0) //  ラベルの高さ、幅を0にすると自動でサイズが決められる
        allowLocationLabel.centerX(inView: view)
        
        
        
        view.addSubview(enableLocationButton)
        enableLocationButton.anchor(top: allowLocationLabel.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 24, paddingLeft: 32, paddingBottom: 0, paddingRight: 32, width: 0, height: 50)
    }
    
    
    
}



extension LocationRequestController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard locationManager?.location != nil else {
            print("error setting location")
            return
        }
        
        dismiss(animated: true)
    }
    
    
    
}
