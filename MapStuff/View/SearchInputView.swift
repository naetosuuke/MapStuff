//
//  SearchInputView.swift
//  MapStuff
//
//  Created by Daisuke Doi on 2023/02/15.
//
//  enumeration
//
//
//



import UIKit
import MapKit

private let reuseIdentifier = "SearchCell" //再利用するせるのIdentifierを設定　他と干渉させないためprivate

protocol SearchInputViewDelegate { //InputViewと連動して動くが、描写自体はMapViewにある。⇨ InputViewで実行をし、実際の処理はMapViewで行う。という処理をプロトコルで実装
    func animateCenterMapButton(expansionState: SearchInputView.ExpansionState, hideButton: Bool) //InputViewの状態を記す列挙体を、引数として渡す
    func handleSearch(withSearchText searchText: String)
    func addPolyline(forDestinationMapItem destinationMapItem: MKMapItem)
    func selectedAnnotation(withMapItem mapItem: MKMapItem)
}

class SearchInputView: UIView {
    
    //MARK: - Properties
    
    var searchBar: UISearchBar!
    var tableView: UITableView!
    var expansionState: ExpansionState!
    var selectedCell: SearchCell!
    
    var delegate: SearchInputViewDelegate?
    var mapController: MapController?
    var directionsEnabled = false
    
    
    var searchResults: [MKMapItem]? {//検索結果 MapKitインポートしないと使えないよ
        didSet { //searchResultsにクロージャでdidset構造体を加えることで、この変数が呼び出されるたびにtableViewをリロードするようにする。
            tableView.reloadData()
        }
    }
    
    enum ExpansionState { //モーダル表示領域の列挙体 状態/カスタムタイプによる機能変更を実装する場合は、enumで書くと見やすくてエラーの確率を下げられる
        case NotExpanded //これらは列挙たいExpantionStateのプロパティとして保持される
        case PartiallyExpanded
        case FullyExpanded
    }

    
    let indicatorView: UIView = { // 画面を引っ張れる目印のちょん印
        let view = UIView()
        view.backgroundColor = .lightGray
        view.layer.cornerRadius = 5
        view.alpha = 0.8
        return view
    }()
    
    
    //MARK: - Init
    
    override init(frame: CGRect) { //画面の初期化
        super.init(frame: frame)
        configureViewComponents()
        expansionState = .NotExpanded //デフォルト
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - selectors
    @objc func handleSwipeGesture(sender: UISwipeGestureRecognizer){ //ジェスチャーが行われた際に呼び出される関数
        
        if directionsEnabled == true {
            print("swiping disabled")
            return
        }
        
        if sender.direction == .up { //上にスワイプ
            if expansionState == .NotExpanded { //したの段なら
                delegate?.animateCenterMapButton(expansionState: self.expansionState, hideButton: false) // //ボタン動かす（隠さない）
                animateInputView(targetPosition: self.frame.origin.y - 250) {(_) in
                    self.expansionState = .PartiallyExpanded
                    }
                }
            if expansionState == .PartiallyExpanded { //中段なら
                delegate?.animateCenterMapButton(expansionState: self.expansionState, hideButton: true)  //ボタン動かす（隠す）
                animateInputView(targetPosition: self.frame.origin.y - 460) {(_) in
                    self.expansionState = .FullyExpanded
                    }
                }
        } else { //下にスワイプ
            
            if expansionState == .FullyExpanded { //上段なら
                self.searchBar.endEditing(true)
                self.searchBar.showsCancelButton = false
                animateInputView(targetPosition: self.frame.origin.y + 460) {(_) in
                    self.delegate?.animateCenterMapButton(expansionState: self.expansionState, hideButton: false)  //ボタン動かす（隠さない）
                    self.expansionState = .PartiallyExpanded
                    }
                }
                if expansionState == .PartiallyExpanded { //中段なら
                    delegate?.animateCenterMapButton(expansionState: self.expansionState, hideButton: false) //ボタン動かす（隠さない）
                    animateInputView(targetPosition: self.frame.origin.y + 250) {(_) in
                        self.expansionState = .NotExpanded
                    }
                }
        }
    }
    
    //MARK: - Helper Function
    
    func disableViewInteraction(directionsEnabled: Bool) { //テーブルビュー、検索バーを選択できないようにする
        self.directionsEnabled = directionsEnabled
        
        if directionsEnabled == true {
            tableView.allowsSelection = false
            searchBar.isUserInteractionEnabled = false
        } else {
            tableView.allowsSelection = true
            searchBar.isUserInteractionEnabled = true
        }
    }
    
    func dismissOnSearch() { //入力画面を下げる
        searchBar.endEditing(true)
        searchBar.showsCancelButton = false
        animateInputView(targetPosition: self.frame.origin.y + 460) {(_) in
            self.delegate?.animateCenterMapButton(expansionState: self.expansionState, hideButton: false)
            self.expansionState = .PartiallyExpanded
        }
    }
    
    
    func animateInputView(targetPosition: CGFloat, completion: @escaping(Bool) -> ()){ //アニメーション動作のメソッド @escapingをつけると引数が確定していなくても処理が進む
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.frame.origin.y = targetPosition // モーダルの高さの期限をアニメで調整する
            
        }, completion: completion)
    }
    
    
    
    func configureViewComponents() { //画面の設定
        backgroundColor = .white
        addSubview(indicatorView)
        indicatorView.anchor(top: topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 8, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 40, height: 8)
        indicatorView.centerX(inView: self)

        configureSearchBar()
        configureTableView()
        configureGestureRecognizers()
    }
    
    func configureSearchBar() {
        searchBar = UISearchBar()
        searchBar.placeholder = "Seach for a place or address"
        searchBar.delegate = self
        searchBar.barStyle = .black
        searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default) //
        
        addSubview(searchBar)
        searchBar.anchor(top: indicatorView.bottomAnchor, left: leftAnchor, bottom: nil, right: rightAnchor, paddingTop: 4, paddingLeft: 8, paddingBottom: 0, paddingRight: 8, width: 0, height: 50)
    }
    
    func configureTableView() {
        tableView = UITableView()
        tableView.rowHeight = 72
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(SearchCell.self, forCellReuseIdentifier: reuseIdentifier)
        
        addSubview(tableView)
        tableView.anchor(top: searchBar.bottomAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 8, paddingLeft: 0, paddingBottom: 100, paddingRight: 0, width: 0, height: 0)
    }
    
    func configureGestureRecognizers() { // ジェスチャーを設定
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture)) //アニメーション込みでモーダルの高さを変更
        swipeUp.direction = .up // 動作の方向を指定
        addGestureRecognizer(swipeUp) //senderにジェスチャーを投入する事で、objc funcで分岐可能
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
        swipeDown.direction = .down // 動作の方向を指定
        addGestureRecognizer(swipeDown)

    }
}


// MARK: - UISearchBarDelegate

extension SearchInputView: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { return }
        delegate?.handleSearch(withSearchText: searchText)
        dismissOnSearch()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if expansionState == .NotExpanded {
            delegate?.animateCenterMapButton(expansionState: self.expansionState, hideButton: true)
            animateInputView(targetPosition: self.frame.origin.y - 710) {(_) in
                self.expansionState = .FullyExpanded
            }
        }
        if expansionState == .PartiallyExpanded {
            animateInputView(targetPosition: self.frame.origin.y - 460) {(_) in
                self.expansionState = .FullyExpanded
            }
        }
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismissOnSearch()
    }
}

// MARK: - UITableViewDelegate

extension SearchInputView: UITableViewDelegate, UITableViewDataSource { //TableView列の数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let searchResults = searchResults else {return 0} //検索結果の数 (optionalから変換、nilの時は0を返す)
        return searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { //cellの設定
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for : indexPath) as! SearchCell //searchCell型にキャスト
        if let controller = mapController { //MapControllerクラスを変数として取得できていたら
            cell.delegate = controller //cellのデリゲート通知先はMapController
        }
        if let searchResults = searchResults { //検索結果　オプショナルのためアンラップ
            cell.mapItem = searchResults[indexPath.row] //mapItem配列に結果を渡す
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {//選択した時の関数
        
        guard var searchResults = searchResults else { return }
        let selectedMapItem = searchResults[indexPath.row] //選択したものを変数に入れる
        delegate?.selectedAnnotation(withMapItem: selectedMapItem) //Annotation
        
        //FIXME: Refacter
        
        if expansionState == .FullyExpanded { //検索画面　上段なら
            self.searchBar.endEditing(true)
            self.searchBar.showsCancelButton = false
            animateInputView(targetPosition: self.frame.origin.y + 460) {(_) in
                self.delegate?.animateCenterMapButton(expansionState: self.expansionState, hideButton: true)  //ボタン動かす（隠さない）
                self.expansionState = .PartiallyExpanded
                }
        }
        searchResults.remove(at: indexPath.row)//選択した検索結果を消す
        searchResults.insert(selectedMapItem, at: 0) //消した結果を列のトップに持ってくる
        self.searchResults = searchResults //このクラスの変数に返す
        
        let firstIndexPath = IndexPath(row: 0, section: 0) //テーブル一番上のセルを指定するため一番上にIndexPathを宣言
        let cell = tableView.cellForRow(at:firstIndexPath) as! SearchCell //一番上のセルを変数cellに代入　このときSearchCell型にキャストし、カスタムセルにする

        //FIXME: GOボタン削除
        if let previousCell = self.selectedCell{ //前回選択したセルが存在していたら
            previousCell.removeGo() //goを削除する
        }
        
        self.selectedCell = cell
        cell.animateButtonIn() //cell カスタムセルの型を持つので、メンバー式からアニメーションを呼び出す
        cell.selectedMapItem = selectedMapItem // 選択されたセルのMapItemをSearchCellクラスに渡す
        
        delegate?.addPolyline(forDestinationMapItem: selectedMapItem) //polyLineを引く
    }
}


