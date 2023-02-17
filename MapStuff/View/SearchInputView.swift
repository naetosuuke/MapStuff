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

private let reuseIdentifier = "SearchCell" //再利用するせるのIdentifierを設定　他と干渉させないためprivate

protocol SearchInputViewDelegate { //InputViewと連動して動くが、描写自体はMapViewにある。⇨ InputViewで実行をし、実際の処理はMapViewで行う。という処理をプロトコルで実装
    func animateCenterMapButton(expansionState: SearchInputView.ExpansionState, hideButton: Bool) //InputViewの状態を記す列挙体を、引数として渡す
    func handleSearch(withSearchText searchText: String)
}


class SearchInputView: UIView {
    
    //MARK: - Properties
    
    var searchBar: UISearchBar!
    var tableView: UITableView!
    var expansionState: ExpansionState!
    var delegate: SearchInputViewDelegate?
    
    enum ExpansionState { //モーダル表示領域の列挙体 状態/カスタムタイプによる機能変更を実装する場合は、enumで書くと見やすくてエラーの確率を下げられる
        case NotExpanded //これらは列挙たいExpantionStateのプロパティとして保持される
        case PartiallyExpanded
        case FullyExpanded
    }

    
    let indicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.layer.cornerRadius = 5
        view.alpha = 0.8
        return view
    }()
    
    
    //MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .red
        configureViewComponents()
        expansionState = .NotExpanded //デフォルト
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - selectors
    @objc func handleSwipeGesture(sender: UISwipeGestureRecognizer){ //引数にジェスチャーを取得
        
        if sender.direction == .up {
            print("did swipe up")
            
            if expansionState == .NotExpanded {
                delegate?.animateCenterMapButton(expansionState: self.expansionState, hideButton: false)
                animateInputView(targetPosition: self.frame.origin.y - 250) {(_) in
                    self.expansionState = .PartiallyExpanded
                    }
                }
            if expansionState == .PartiallyExpanded {
                delegate?.animateCenterMapButton(expansionState: self.expansionState, hideButton: true)
                animateInputView(targetPosition: self.frame.origin.y - 460) {(_) in
                    self.expansionState = .FullyExpanded
                    }
                }
        } else {
            
            if expansionState == .FullyExpanded {
                self.searchBar.endEditing(true)
                self.searchBar.showsCancelButton = false
                animateInputView(targetPosition: self.frame.origin.y + 460) {(_) in
                    self.delegate?.animateCenterMapButton(expansionState: self.expansionState, hideButton: false)
                    self.expansionState = .PartiallyExpanded
                    }
                }
                if expansionState == .PartiallyExpanded {
                    delegate?.animateCenterMapButton(expansionState: self.expansionState, hideButton: false)
                    
                    animateInputView(targetPosition: self.frame.origin.y + 250) {(_) in
                        self.expansionState = .NotExpanded
                    }
                }
        }
    }
    
    //MARK: - Helper Function
    

    func animateInputView(targetPosition: CGFloat, completion: @escaping(Bool) -> ()){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.frame.origin.y = targetPosition // モーダルの高さの期限をアニメで調整する
            
        }, completion: completion)
    }
    
    
    
    func configureViewComponents() {
        backgroundColor = .white
        addSubview(indicatorView) //
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
    
    func configureGestureRecognizers() { //senderにジェスチャーを投入する事で、objc funcで分岐可能
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture)) //アニメーション込みでモーダルの高さを変更
        swipeUp.direction = .up // 動作の方向を指定
        addGestureRecognizer(swipeUp)
        
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
        searchBar.endEditing(true)
        searchBar.showsCancelButton = false
        
        animateInputView(targetPosition: self.frame.origin.y + 460) {(_) in
            self.delegate?.animateCenterMapButton(expansionState: self.expansionState, hideButton: false)
            self.expansionState = .PartiallyExpanded
            
            
        }

    }


}


extension SearchInputView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for : indexPath) as! SearchCell
        return cell
    }
}


