//
//  MapController.swift
//  MapStuff
//
//  Created by Daisuke Doi on 2023/02/11.
//

import UIKit
import MapKit
import CoreLocation

class MapController: UIViewController{
    
    // MARK: - Properties
    
    var mapView: MKMapView!
    var locationManager: CLLocationManager!
    var searchInputView: SearchInputView!
    
    let centerMapButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "location-arrow-flat") .withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleCenterLocation), for: .touchUpInside)
        return button
    } ()
    
    
       
    
    // MARK: - Init
    
    override func viewDidLoad() { //初回実行時しか起動しない
        super.viewDidLoad()
        configureViewComponents()
        enableLocationService()
    }
    
    override func viewWillAppear(_ animated: Bool) { //画面が開くたびに動く
        super.viewWillAppear(animated)
        centerMapOnUserLocation()
    }
    
    
    
    // MARK: selector
    
    @objc func handleCenterLocation() {
        print("handle center..")
    }

    
    
    
    // MARK: - Helper Functions
    
    func configureViewComponents() {
        view.backgroundColor = .white
        configureMapView()
        
        searchInputView = SearchInputView() //インスタンス化
        searchInputView.delegate = self
        view.addSubview(searchInputView)
        searchInputView.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: -(view.frame.height - 88), paddingRight: 0, width: 0, height: view.frame.height)
        // y軸のアンカー　negative(マイナス表記)にしている。これは二次元座標の原点が左上だから
        view.addSubview(centerMapButton)
        centerMapButton.anchor(top: nil, left: nil, bottom:searchInputView.topAnchor , right: view.rightAnchor, paddingTop: 0  , paddingLeft: 0, paddingBottom: 16, paddingRight: 16, width: 50, height: 50)
        
    }
    
    func configureMapView() {
        mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        view.addSubview(mapView)
        mapView.addConstraintsToFillView(view: view)
    }
    
}


//MARK: - SearchInputViewDelegate
extension MapController: SearchInputViewDelegate{
    
    func handleSearch(withSearchText searchText: String) {
        
        guard let coordinate = locationManager.location?.coordinate else {return}
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000) //検索範囲
        
        
        searchBy(naturalLanguageQuery: searchText, region: region, coordinates: coordinate) {(response, error) in
            
            response?.mapItems.forEach {(mapItem) in
                print(mapItem.name)
                
                
            }

            
        }
        
        
        
        
        
        
        
        
        
    }
    
    
    func animateCenterMapButton(expansionState: SearchInputView.ExpansionState, hideButton: Bool) {
        
        switch expansionState { //enumにswich分岐を使う 引数の内容で分岐される
        case .NotExpanded:
            
            UIView.animate(withDuration: 0.25) {
                self.centerMapButton.frame.origin.y -= 250 //searchInputViewの状態に合わせてアニメーション
            }
            if hideButton{
                self.centerMapButton.alpha = 0
            } else {
                self.centerMapButton.alpha = 1
            }
            
        case .PartiallyExpanded:
            if hideButton {
                self.centerMapButton.alpha = 0
            } else {
                UIView.animate(withDuration: 0.25){
                    self.centerMapButton.frame.origin.y += 250
                }
                
            }
            
        case .FullyExpanded:
            UIView.animate(withDuration: 0.25) {
                self.centerMapButton.alpha = 1
            }
            
        }
    
        
        
        
        
    }
    
    
}



//MARK: -  MapKit Helper FUnction

extension MapController {
    
    func centerMapOnUserLocation() {
        
        guard let coordinates = locationManager.location?.coordinate else {return}
        let coordinateRegion = MKCoordinateRegion(center: coordinates, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(coordinateRegion, animated: true)
        
    }
    
    func searchBy(naturalLanguageQuery: String, region: MKCoordinateRegion, coordinates: CLLocationCoordinate2D, completion: @escaping(_ response: MKLocalSearch.Response?, _ error: NSError?) -> ()) {
        
        let request = MKLocalSearch.Request()//検索リクエストのインスタンス
        request.naturalLanguageQuery = naturalLanguageQuery //検索ワード
        request.region = region
        
        let search = MKLocalSearch(request: request) //検索インスタンス
        search.start { (response, error) in //検索開始
            
            guard let response = response else { //何も得られなかったら
                completion(nil, error! as NSError) //Completionに返す
                return
            }
            completion(response, nil)
        }
    }
    
    
}

    
//MARK: -  CLLocationManagerDelegate
                            
                            
extension MapController: CLLocationManagerDelegate {
    
    func enableLocationService() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            print("Location auth status is NOT DETERMINED")
            DispatchQueue.main.async{
                
                let controller = LocationRequestController() //インスタンス生成
                controller.locationManager = self.locationManager //インスタンスに自クラスのlocationManager情報を代入
                
                self.present(controller, animated: true)//自クラスの情報をもったRocationRequestControllerを起動
                
            }
        case .restricted:
            print("Location auth status is RESTRICTED")
        case .denied:
            print("Location auth status is DENIED")
        case .authorizedAlways:
            print("Location auth status is AUTHORIZED ALWAYS")
        case .authorizedWhenInUse:
            print("Location auth status is AUTHORIZED WHEN IN USE")
        }
        
    }
    
    
    
}
