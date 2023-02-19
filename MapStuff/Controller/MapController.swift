//
//  MapController.swift
//  MapStuff
//
//  Created by Daisuke Doi on 2023/02/11.
//

import UIKit
import MapKit
import CoreLocation


class MapController: UIViewController {
    
    // MARK: - Properties
    
    var mapView: MKMapView!
    var locationManager: CLLocationManager!
    var searchInputView: SearchInputView!
    var route: MKRoute?
    var selectedAnnotation: MKAnnotation?
    
    let centerMapButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "location-arrow-flat") .withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleCenterLocation), for: .touchUpInside)
        return button
    } ()
    
    
    let removeOverlaysButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_clear_white_36pt_1x").withRenderingMode(.alwaysOriginal), for: .normal)
        button.backgroundColor = .red
        button.alpha = 0
        button.addTarget(self, action: #selector(handleRemoveOverlays), for: .touchUpInside)
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
        centerMapOnUserLocation(shouldLoadAnnotaitons: true)
    }
    
    
    
    // MARK: selector
    
    @objc func handleRemoveOverlays() {
        
        guard let selectedAnno = self.selectedAnnotation else { return } //アノテーションが選択されているか
        searchInputView.directionsEnabled = false //経路　非表示
        UIView.animate(withDuration: 0.5){ //バツボタンをけし、現在地ボタンを表示
            self.removeOverlaysButton.alpha = 0
            self.centerMapButton.alpha = 1
        }
        
        if mapView.overlays.count > 0 { //経路が1以上ある時
            self.mapView.removeOverlay(mapView.overlays[0]) //経路を削除
            centerMapOnUserLocation(shouldLoadAnnotaitons: false)
        }
        searchInputView.disableViewInteraction(directionsEnabled: false) //操作可能にする
        mapView.deselectAnnotation(selectedAnno, animated:true) //選択したアノテーション　取り消し
    }
    
    @objc func handleCenterLocation() {
        centerMapOnUserLocation(shouldLoadAnnotaitons: false)
    }

    
    // MARK: - Helper Functions
    
    func configureViewComponents() {
        view.backgroundColor = .white
        configureMapView()
        
        searchInputView = SearchInputView() //インスタンス化
        searchInputView.delegate = self
        searchInputView.mapController = self //searchInputViewがもつ変数mapController(MapController型)はこのクラスのことだよ、と宣言してる
        
        view.addSubview(searchInputView)
        searchInputView.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: -(view.frame.height - 88), paddingRight: 0, width: 0, height: view.frame.height)

        // y軸のアンカー　negative(マイナス表記)にしている。これは二次元座標の原点が左上だから
        view.addSubview(centerMapButton)
        centerMapButton.anchor(top: nil, left: nil, bottom: searchInputView.topAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 16, paddingRight: 16, width: 50, height: 50)
        
        view.addSubview(removeOverlaysButton)
        let dimension: CGFloat = 50
        removeOverlaysButton.anchor(top: nil, left: view.leftAnchor, bottom: searchInputView.topAnchor, right: nil, paddingTop: 0, paddingLeft: 16, paddingBottom: 268, paddingRight: 0, width: dimension, height: dimension)
        removeOverlaysButton.layer.cornerRadius = dimension / 2
    }
    
    func configureMapView() {
        mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
        view.addSubview(mapView)
        mapView.addConstraintsToFillView(view: view)
    }
    
}

// MARK: - SearchCellDelegate

extension MapController: SearchCellDelegate {
    
    func getDirections(forMapItem mapItem: MKMapItem) {
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking]) //純正アプリ　マップを開き、MKMapItemまでの経路を書く
    }
    
    func distanceFromUser(location: CLLocation) -> CLLocationDistance? {
        guard let userLocation = locationManager.location else {return nil} //CLLocationが持つ位置情報
        return userLocation.distance(from: location) //変数　locaitonから現在地までの距離を返す(CLLocationを返す)
    }
}

//MARK: - SearchInputViewDelegate
extension MapController: SearchInputViewDelegate {
    
    func selectedAnnotation(withMapItem mapItem: MKMapItem) {
        mapView.annotations.forEach{(annotation) in
            if annotation.title == mapItem.name {
                self.mapView.selectAnnotation(annotation, animated: true) //tableViewで選択した内容のannotataionを選択する
                self.zoomToFit(selectedAnnotation: annotation)
                self.selectedAnnotation = annotation //選択したアノテーションをクラスのプロパティとして返す
                
                UIView.animate(withDuration: 0.5, animations: {
                self.removeOverlaysButton.alpha = 1
                self.centerMapButton.alpha = 0
                })
            }
        }
    }
    
    func addPolyline(forDestinationMapItem destinationMapItem: MKMapItem) {
        searchInputView.disableViewInteraction(directionsEnabled: true) //現在　経路があり、画面に触らせたくない
        generatePolyline(forDestinationMaItem: destinationMapItem)
    }
    
    func handleSearch(withSearchText searchText: String) {
        removeAnnotarions()//アノテーション情報を初期化
        loadAnnotations(withSearchQuery: searchText)
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
            if !hideButton {
                UIView.animate(withDuration: 0.25) {
                    self.centerMapButton.alpha = 1
                }
            }
        }
    }
        
}

extension MapController: MKMapViewDelegate { //
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer { //デリゲートメソッド
        if let route = self.route { //実行するクラスがルート情報を持っていたら
            let polyline = route.polyline //経路を変数に入れる
            let lineRenderer = MKPolylineRenderer(overlay: polyline) //レンダラーをインスタンス化
            lineRenderer.strokeColor = .mainBlue() //色　mainBlue(クロージャ内なのでインスタンス化)
            lineRenderer.lineWidth = 3 //線の太さ
            return lineRenderer //レンダラーを返す
        }
        return MKOverlayRenderer() //
    }
}


//MARK: -  MapKit Helper Function

extension MapController {

    func zoomToFit(selectedAnnotation: MKAnnotation?) { //ズーム機能　丸コピーでOK(動画の主もロジック分かってなかった)
        if mapView.annotations.count == 0 { //アノテーションがなければ
            return
        }
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180) //左上の座標
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180) //右下の座標
        if let selectedAnnotation = selectedAnnotation { //選択されたアノテーションが存在する時
            for annotation in mapView.annotations { //各アノテーションに対して
                if let userAnno = annotation as? MKUserLocation { //アノテーションをMKUserLocation型にキャスト
                    topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, userAnno.coordinate.longitude) //左上の座標　緯度 fmin(double, double) -> double = 引数2つのうち、小さい方を返す
                    topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, userAnno.coordinate.latitude) //左上の座標　経度
                    bottomRightCoordinate.longitude = fmax(topLeftCoordinate.longitude, userAnno.coordinate.longitude) //右下の座標　緯度
                    bottomRightCoordinate.latitude = fmin(topLeftCoordinate.latitude, userAnno.coordinate.latitude) //右下の座標　経度
                }
                
                if annotation.title == selectedAnnotation.title {
                    topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                    topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                    bottomRightCoordinate.longitude = fmax(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                    bottomRightCoordinate.latitude = fmin(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                }
            }
            
            var region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(topLeftCoordinate.latitude - (topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 0.65, topLeftCoordinate.longitude + (bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.65), span: MKCoordinateSpan(latitudeDelta: fabs(topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 3.0, longitudeDelta: fabs(bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 3.0))
            region = mapView.regionThatFits(region)
            mapView.setRegion(region, animated:true)
        }
    }
    
    
    func generatePolyline(forDestinationMaItem destinationMapItem: MKMapItem) {
        let request = MKDirections.Request() //リクエスト
        
        request.source = MKMapItem.forCurrentLocation() // 出発地点
        request.destination = destinationMapItem //到着地点
        request.transportType = .walking //移動手段

        let directions = MKDirections(request: request) //ルート作成
        directions.calculate { (response, error) in
            
            guard let response = response else { return }
            self.route = response.routes[0]//ルート　検索結果の上から１番目を返す
            guard let polyline = self.route?.polyline else {return}
            self.mapView.addOverlay(polyline)
        }
    }
    
    
    func centerMapOnUserLocation(shouldLoadAnnotaitons: Bool) { //マップ中心に自分の座標を表示
        
        guard let coordinates = locationManager.location?.coordinate else {return}
        let coordinateRegion = MKCoordinateRegion(center: coordinates, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(coordinateRegion, animated: true)
        if shouldLoadAnnotaitons{
            loadAnnotations(withSearchQuery: "Coffee Shop")
        }
    }
    
    func searchBy(naturalLanguageQuery: String, region: MKCoordinateRegion, coordinates: CLLocationCoordinate2D, completion: @escaping(_ response: MKLocalSearch.Response?, _ error: NSError?) -> ()) { //検索
        
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
    
    
    func removeAnnotarions(){ //アノテーション削除
        mapView.annotations.forEach {(annotation) in //mapViewがもってるannotationに繰り返し処理　処理はまたクロージャで記載
            if let annotation = annotation as? MKPointAnnotation { //MKPointAnnotation方のアノテーションのみ選択（こうしないと現在地も消える）
                mapView.removeAnnotation(annotation) //mapViewから削除
            }
        }
    }
    
    func loadAnnotations(withSearchQuery query :String) { //起動時の検索条件、検索実行
        guard let coordinate = locationManager.location?.coordinate else {return}
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000) //検索範囲
        searchBy(naturalLanguageQuery: query, region: region, coordinates: coordinate) {(response, error) in
            guard let response = response else { return }
            response.mapItems.forEach ({(mapItem) in //mapItemsはforEachメソッドを持ってる　引数にクロージャでアノテーションを入れてる
                let annotation = MKPointAnnotation()
                annotation.title = mapItem.name
                annotation.coordinate = mapItem.placemark.coordinate // placemarkオブジェクトの中にある
                self.mapView.addAnnotation(annotation)
            })
            
            self.searchInputView.searchResults = response.mapItems //searchInputViewのインスタンスは、このswiftファイル上にある
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
