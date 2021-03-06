//
//  SearchViewController.swift
//  MyMVVMProject
//
//  Created by bro on 2022/06/22.
//

import UIKit

import Toast

class SearchViewController: BaseViewController {
    
    let searchView = SearchView()
    let viewModel = SearchViewModel()
    
    private var requestSearchWorkItem: DispatchWorkItem?
    
    override func loadView() {
        self.view = searchView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func configure() {
        super.configure()
        
        searchBarConfig()
        tableViewConfig()
        bind()
        
    }

    private func tableViewConfig() {
        searchView.searchCollectionView.delegate = self
        searchView.searchCollectionView.dataSource = self
        searchView.searchCollectionView.prefetchDataSource = self
    }
    
    private func searchBarConfig() {
        self.navigationController?.navigationBar.topItem?.titleView = searchView.searchBar
        searchView.searchBar.delegate = self
    }
    
    private func bind() {
        viewModel.kakaoImages.bind { images in
            self.searchView.noDataLabel.isHidden = self.viewModel.kakaoImages.value.isEmpty ? false : true
            self.searchView.searchCollectionView.reloadData()
        }
        
        viewModel.isLoading.bind { isLoading in
            isLoading ? self.searchView.showProgress() : self.searchView.dissmissProgress()
        }
        
        searchView.noDataLabel.isHidden = true
    }
        
    private func fetchImage() {
        if (checkNetworkValue && !viewModel.kakaoResponse.value.meta.isEnd && !viewModel.isLoading.value) {
            viewModel.currentPage += 1
            hideKeyboard()
            viewModel.fetchImage()
        } else {
            view.makeToast("더 이상 문서가 없습니다.")
        }
    }
    
    private func searchImage(query: String) {
        // 검색어 입력이 들어왔을때 이전 검색이 있으면, 검색 호출을 cancel
        requestSearchWorkItem?.cancel()
        if (checkNetworkValue && !query.isEmpty && viewModel.query != query && !viewModel.isLoading.value) {
            viewModel.currentPage = 1
            requestSearchWorkItem = DispatchWorkItem { [weak self] in
                self?.hideKeyboard()
                self?.viewModel.searchImage(query: query)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: requestSearchWorkItem!)
        }
    }
    
    private func hideKeyboard() {
        view.endEditing(true)
    }
    
}

// MARK: - CollectionView
extension SearchViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.kakaoImages.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UICollectionViewCell.reuseIdentifier, for: indexPath) as! SearchCollectionViewCell
        
        let kakaoImage = viewModel.kakaoImages.value[indexPath.row]
        cell.configureImage(kakoImage: kakaoImage)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = DetailViewController()
        vc.viewModel.kakaoImage.value = viewModel.kakaoImages.value[indexPath.row]
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
    
}

// MARK: - CollectionView FlowLayout
extension SearchViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
       
        let width = collectionView.bounds.width
        let numberOfItemsPerRow: CGFloat = CGFloat(CollectionSize.numberOfItemsPerRow.rawValue)
        let spacing: CGFloat = CGFloat(CollectionSize.spacing.rawValue)
        let availableWidth = width - spacing * (numberOfItemsPerRow + 1)
        let itemDimension = floor(availableWidth / numberOfItemsPerRow)
        return CGSize(width: itemDimension, height: itemDimension)
    }
    
}

// MARK: - CollectionView Prefetcing
extension SearchViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    
        for indexPath in indexPaths {
            if viewModel.kakaoImages.value.count - 1 == indexPath.row && viewModel.kakaoImages.value.count < viewModel.kakaoResponse.value.meta.totalCount {
                fetchImage()
            }
        }

    }
   
    
}

// MARK: - SearchView
extension SearchViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchImage(query: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let searchText = searchBar.text ?? ""
        searchImage(query: searchText)
    }
    
}
