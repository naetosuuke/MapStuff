//
//  SearchCell.swift
//  MapStuff
//
//  Created by Daisuke Doi on 2023/02/15.
//

import UIKit
import MapKit

protocol SearchCellDelegate { //delegateメソッド　CLLocationがもつ現在地と引数locationの距離を返す
    func distanceFromUser(location: CLLocation) -> CLLocationDistance?
    func getDirections(forMapItem mapItem: MKMapItem)
}
    
class SearchCell: UITableViewCell {
    
    // MARK: - Proerties

    var delegate: SearchCellDelegate?
    var mapItem: MKMapItem? { //mapItemが入るたび、cellが更新される
        didSet {
            configureCell()
        }
    }
    var selectedMapItem: MKMapItem? {
        didSet{
            print("\(mapItem!.name) is selected in tableview")
        }
    }

    lazy var directionsButton: UIButton = { //goボタン　Viewの中にボタンを設定する場合、lazyをつけないとハンドラーが起動しない(selector)
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitle("Go", for: .normal)
        button.backgroundColor = .directionsGreen()
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(handleGetDirections), for: .touchUpInside)
        button.layer.cornerRadius = 5
        button.alpha = 0
        return button
    }()
    
    
    lazy var imageContainerView: UIView = { //constantにできないから　どゆこと？
        let view = UIView()
        view.backgroundColor = .mainPink()
        view.addSubview(locationImageView)
        locationImageView.center(inView: view) //おく場所　centerとして配置
        locationImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        locationImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        return view
    }()
    
    let locationImageView: UIImageView = {
        let iv = UIImageView()
        iv.clipsToBounds = true
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .mainPink()
        iv.image = #imageLiteral(resourceName: "baseline_location_on_white_24pt_3x") //#imageLiteral( と入力する
        return iv
    }()
    
    let locationTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    
    let locationDistanceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        return label
    }()
    
    
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        
        selectionStyle = .none //.ほにゃらら　と書くものはenum or staticプロパティ
        addSubview(imageContainerView)
        let dimension:CGFloat = 40//アノテーション写真のサイズ
        imageContainerView.anchor(top: nil, left: leftAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: dimension, height: dimension)
        imageContainerView.layer.cornerRadius = dimension / 2 //こうすると完全な球体を作れる
        imageContainerView.centerY(inView: self) //セル自体のY軸　中心に設置
        
        addSubview(locationTitleLabel)
        locationTitleLabel.anchor(top: imageContainerView.topAnchor, left: imageContainerView.rightAnchor, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 8, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)//width heightは文字サイズで自動的に変更されるため、0でよい
        addSubview(locationDistanceLabel)
        locationDistanceLabel.anchor(top: nil, left: imageContainerView.rightAnchor, bottom: imageContainerView.bottomAnchor, right: nil, paddingTop: 0, paddingLeft: 9, paddingBottom: 0, paddingRight: 0, width: 0, height: 0)
        
        addSubview(directionsButton)
        let buttonDimention: CGFloat = 50
        directionsButton.anchor(top: nil, left: nil, bottom: nil, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 8, width: buttonDimention, height: buttonDimention)
        directionsButton.centerY(inView: self)
        
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Selector
    
    @objc func handleGetDirections() {
        print("pushed go")
        guard let selectedMapItem = self.selectedMapItem else {
            
            return
        }
        delegate?.getDirections(forMapItem: selectedMapItem)
    }

    // MARK: - Helper Function
    
    func animateButtonIn() {
        directionsButton.transform = CGAffineTransform(scaleX: 0.25, y: 0.25) //サイズを変える　小さくする
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseInOut, animations: { //0.5秒かけて、下記アニメーション
            self.directionsButton.alpha = 1 //透過を消して表示
            self.directionsButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2) //元のサイズの1.2倍まで大きくする
        }) { (_) in //アニメーションが終わったらクロージャ起動
            self.directionsButton.transform = .identity //元のサイズにもどす
        }
    }
    
    func removeGo() {
        print("removeGo initialized..")
        self.directionsButton.alpha = 0//透過を消して表示
    }
    
    func configureCell() {
        locationTitleLabel.text = mapItem?.name
        
        let distanceFormatter = MKDistanceFormatter()
        distanceFormatter.unitStyle = .abbreviated //省略された　直線距離
        
        guard let mapItemLocation = mapItem?.placemark.location else { return }
        guard let distanceFromUser = delegate?.distanceFromUser(location: mapItemLocation) else { return }
        let distanceAsString = distanceFormatter.string(fromDistance: distanceFromUser) //文字としてキャスト
        locationDistanceLabel.text = distanceAsString //ラベルに投入
    }
    
    
    
}
