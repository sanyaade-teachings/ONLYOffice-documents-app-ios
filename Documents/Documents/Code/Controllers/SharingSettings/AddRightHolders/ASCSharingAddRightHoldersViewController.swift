//
//  ASCSharingAddRightHoldersViewController.swift
//  Documents
//
//  Created by Павел Чернышев on 09.07.2021.
//  Copyright (c) 2021 Ascensio System SIA. All rights reserved.
//

import UIKit
import MBProgressHUD

protocol ASCSharingAddRightHoldersDisplayLogic: AnyObject {
    func displayData(viewModelType: ASCSharingAddRightHolders.Model.ViewModel.ViewModelData)
}

class ASCSharingAddRightHoldersViewController: UIViewController, ASCSharingAddRightHoldersDisplayLogic {
    
    var interactor: ASCSharingAddRightHoldersBusinessLogic?
    var router: (NSObjectProtocol & ASCSharingAddRightHoldersRoutingLogic & ASCSharingAddRightHoldersDataPassing)?
    var dataStore: ASCSharingAddRightHoldersRAMDataStore?
    
    var sharingAddRightHoldersView: ASCSharingAddRightHoldersView?
    var defaultSelectedTable: RightHoldersTableType = .users
    
    var hud: MBProgressHUD?
    var usersCurrentlyLoading = false {
        didSet {
            if oldValue == true && !usersCurrentlyLoading && getSelectedTableType() == .users {
                stopLoadingHud()
            }
        }
    }
    
    var groupsCurrentlyLoading = false {
        didSet {
            if oldValue == true && !groupsCurrentlyLoading && getSelectedTableType() == .groups {
                stopLoadingHud()
            }
        }
    }
    
    let defaultAccess: ASCShareAccess = .read
    var accessProvider: ASCSharingSettingsAccessProvider = ASCSharingSettingsAccessDefaultProvider() {
        didSet {
            sharingAddRightHoldersView?.updateToolbars()
        }
    }
    lazy var selectedAccess: ASCShareAccess = self.defaultAccess
    var countOfSelectedRows: Int {
        (usersModels + groupsModels).reduce(0) { result, selectedModel in
            guard selectedModel.isSelected else { return result }
            return result + 1
        }
    }
    
    private var isSearchBarEmpty: Bool {
        guard let text = sharingAddRightHoldersView?.searchController.searchBar.text else {
            return false
        }
        return text.isEmpty
    }
    
    private lazy var usersTableViewDataSourceAndDelegate = ASCSharingAddRightHoldersTableViewDataSourceAndDelegate<ASCSharingRightHolderTableViewCell>(models: self.usersModels)
    private lazy var groupsTableViewDataSourceAndDelegate = ASCSharingAddRightHoldersTableViewDataSourceAndDelegate<ASCSharingRightHolderTableViewCell>(models: self.groupsModels)
    
    private lazy var searchResultsTableViewDataSourceAndDelegate: ASCSharingAddRightHoldersSearchResultsTableViewDataSourceAndDelegate = {
        guard let usersTableView = sharingAddRightHoldersView?.usersTableView,
              let groupsTableView = sharingAddRightHoldersView?.groupsTableView
        else {
            return ASCSharingAddRightHoldersSearchResultsTableViewDataSourceAndDelegate(tables: [:])
        }
        return ASCSharingAddRightHoldersSearchResultsTableViewDataSourceAndDelegate(tables: [ .users: usersTableView, .groups: groupsTableView])
    }()
    
    private var usersModels: [(model: ASCSharingRightHolderViewModel, isSelected: IsSelected)] = []
    private var groupsModels: [(model: ASCSharingRightHolderViewModel, isSelected: IsSelected)] = []
    
    private lazy var onCellTapped: (ASCSharingRightHolderViewModel, IsSelected) -> Void = { [weak self] model, isSelected in
        guard let self = self else { return }
        self.selectedRow(model: model, isSelected: isSelected)
    }
    
    // MARK: Object lifecycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // MARK: Setup
    
    private func setup() {
        let viewController        = self
        let interactor            = ASCSharingAddRightHoldersInteractor()
        let presenter             = ASCSharingAddRightHoldersPresenter()
        let router                = ASCSharingAddRightHoldersRouter()
        let dataStore             = ASCSharingAddRightHoldersRAMDataStore()
        viewController.interactor = interactor
        viewController.router     = router
        viewController.dataStore  = dataStore
        interactor.presenter      = presenter
        interactor.dataStore      = dataStore
        presenter.viewController  = viewController
        router.viewController     = viewController
        router.dataStore          = dataStore
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sharingAddRightHoldersView = ASCSharingAddRightHoldersView(
            view: view,
            navigationItem: navigationItem,
            navigationController: navigationController,
            searchControllerDelegate: self,
            searchResultsUpdating: self,
            searchBarDelegate: self)
        sharingAddRightHoldersView?.delegate = self
        sharingAddRightHoldersView?.load()
        
        usersTableViewDataSourceAndDelegate.onCellTapped = onCellTapped
        groupsTableViewDataSourceAndDelegate.onCellTapped = onCellTapped
        
        sharingAddRightHoldersView?.usersTableView.dataSource = usersTableViewDataSourceAndDelegate
        sharingAddRightHoldersView?.usersTableView.delegate = usersTableViewDataSourceAndDelegate
        sharingAddRightHoldersView?.groupsTableView.dataSource = groupsTableViewDataSourceAndDelegate
        sharingAddRightHoldersView?.groupsTableView.delegate = groupsTableViewDataSourceAndDelegate
        sharingAddRightHoldersView?.searchResultsTable.dataSource = searchResultsTableViewDataSourceAndDelegate
        sharingAddRightHoldersView?.searchResultsTable.delegate = searchResultsTableViewDataSourceAndDelegate
        
        sharingAddRightHoldersView?.usersTableView.register(usersTableViewDataSourceAndDelegate.type, forCellReuseIdentifier: usersTableViewDataSourceAndDelegate.type.reuseId)
        sharingAddRightHoldersView?.groupsTableView.register(groupsTableViewDataSourceAndDelegate.type, forCellReuseIdentifier: groupsTableViewDataSourceAndDelegate.type.reuseId)
        
        sharingAddRightHoldersView?.showTable(tableType: defaultSelectedTable)
        
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !(sharingAddRightHoldersView?.searchController.isActive ?? false) {
            navigationController?.isToolbarHidden = false
        }
    }
    
    func reset() {
        usersCurrentlyLoading = false
        groupsCurrentlyLoading = false
        selectedAccess = defaultAccess
        usersModels = []
        groupsModels = []
        usersTableViewDataSourceAndDelegate.set(models: [])
        groupsTableViewDataSourceAndDelegate.set(models: [])
        
        sharingAddRightHoldersView?.reset()
        
        dataStore?.clear()
    }
    
    private func getSelectedTableView() -> UITableView {
        let type = getSelectedTableType()
        return sharingAddRightHoldersView?.getTableView(byRightHoldersTableType: type) ?? UITableView()
    }
    
    private func getSelectedTableType() -> RightHoldersTableType {
        guard let sharingAddRightHoldersView = sharingAddRightHoldersView, let tableType = RightHoldersTableType(rawValue: sharingAddRightHoldersView.searchController.searchBar.selectedScopeButtonIndex) else {
            let segmentedControlIndex = sharingAddRightHoldersView?.searchController.searchBar.selectedScopeButtonIndex ?? -1
            fatalError("Couldn't find a table type for segment control index: \(segmentedControlIndex)")
        }
        return tableType
    }
    
    /// when the screen is reused
    func start() {
        sharingAddRightHoldersView?.navigationItem = navigationItem
        sharingAddRightHoldersView?.navigationController = navigationController
        sharingAddRightHoldersView?.configureNavigationBar()
        sharingAddRightHoldersView?.configureToolBar()
        loadData()
    }
    
    // MARK: - Requests
    func loadData() {
        if !usersCurrentlyLoading {
            if getSelectedTableType() == .users {
                runLoadingHud()
            }
            usersCurrentlyLoading = true
            interactor?.makeRequest(requestType: .loadUsers)
        }
        
        if !groupsCurrentlyLoading {
            if getSelectedTableType() == .groups {
                runLoadingHud()
            }
            groupsCurrentlyLoading = true
            interactor?.makeRequest(requestType: .loadGroups)
        }
    }
    
    func selectedRow(model: ASCSharingRightHolderViewModel, isSelected: IsSelected) {
        if isSelected {
            self.interactor?.makeRequest(requestType: .selectViewModel(.init(selectedViewModel: model, access: self.getCurrentAccess())))
        } else {
            self.interactor?.makeRequest(requestType: .deselectViewModel(.init(deselectedViewModel: model)))
        }
    }
    
    // MARK: - Display logic
    
    func displayData(viewModelType: ASCSharingAddRightHolders.Model.ViewModel.ViewModelData) {
        switch viewModelType {
        case .displayUsers(viewModel: let viewModel):
            self.usersModels = viewModel.users
            usersTableViewDataSourceAndDelegate.set(models: viewModel.users)
            sharingAddRightHoldersView?.usersTableView.reloadData()
            usersCurrentlyLoading = false
        case .displayGroups(viewModel: let viewModel):
            self.groupsModels = viewModel.groups
            groupsTableViewDataSourceAndDelegate.set(models: groupsModels)
            sharingAddRightHoldersView?.groupsTableView.reloadData()
            groupsCurrentlyLoading = false
        case .displaySelected(viewModel: let viewModel):
            switch viewModel.type {
            case .users:
                if let index = usersModels.firstIndex(where: { $0.0.id == viewModel.selectedModel.id }) {
                    usersModels[index].1 = viewModel.isSelect
                }
            case .groups:
                if let index = groupsModels.firstIndex(where: { $0.0.id == viewModel.selectedModel.id }) {
                    groupsModels[index].1 = viewModel.isSelect
                }
            }
        }
        
        sharingAddRightHoldersView?.updateTitle(withSelectedCount: countOfSelectedRows)
    }
    
    private func runLoadingHud() {
        hud = MBProgressHUD.showTopMost()
        hud?.label.text = NSLocalizedString("Loading", comment: "Caption of the process")
    }
    
    private func stopLoadingHud() {
        hud?.hide(animated: false)
        hud = nil
    }
    
    // MARK: Routing
    private func routeToVerifyRightHolders() {
        router?.routeToVerifyRightHoldersViewController(segue: nil)
    }
}

// MARK: - View Delegate
extension ASCSharingAddRightHoldersViewController: ASCSharingAddRightHoldersViewDelegate {
    func getAccessList() -> ([ASCShareAccess]) {
        return accessProvider.get()
    }
    
    func getCurrentAccess() -> ASCShareAccess {
        return selectedAccess
    }
    
    @available(iOS 14.0, *)
    func onAccessMenuSelectAction(action: UIAction, shareAccessRaw: Int) {
        onAccessSheetSelectAction(shareAccessRaw: shareAccessRaw)
    }
    
    func onAccessSheetSelectAction(shareAccessRaw: Int) {
        guard let access = ASCShareAccess(rawValue: shareAccessRaw) else { return }
        self.selectedAccess = access
    }
    
    func onUpdateToolbarItems(_ items: [UIBarButtonItem]?) {
        toolbarItems = items
    }
    
    func present(sheetAccessController: UIViewController) {
        present(sheetAccessController, animated: true, completion: nil)
    }
    
    func onNextButtonTapped() {
        routeToVerifyRightHolders()
    }
    
    func onCancelBurronTapped() {
        navigationController?.dismiss(animated: true)
    }
    
    func onSelectAllButtonTapped() {
        guard let sharingAddRightHoldersView = sharingAddRightHoldersView else {
            return
        }
        
        selectAllRows(in: sharingAddRightHoldersView.usersTableView)
        selectAllRows(in: sharingAddRightHoldersView.groupsTableView)
    }
    
    private func selectAllRows(in tableView: UITableView) {
        for section in 0..<tableView.numberOfSections {
            for row in 0..<tableView.numberOfRows(inSection: section) {
                let indexPath = IndexPath(row: row, section: section)
                _ = tableView.delegate?.tableView?(tableView, willSelectRowAt: indexPath)
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                tableView.delegate?.tableView?(tableView, didSelectRowAt: indexPath)
            }
        }
    }

}

// MARK: - UI Search results updating
extension ASCSharingAddRightHoldersViewController: UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        
        guard !searchText.isEmpty else {
            groupsTableViewDataSourceAndDelegate.set(models: groupsModels)
            usersTableViewDataSourceAndDelegate.set(models: usersModels)
            sharingAddRightHoldersView?.groupsTableView.reloadData()
            sharingAddRightHoldersView?.usersTableView.reloadData()
            sharingAddRightHoldersView?.searchResultsTable.reloadData()
            return
        }
        
        let foundGroupsModels = groupsModels.filter({ $0.0.name.lowercased().contains(searchText.lowercased()) })
        let foundUsersModels = usersModels.filter({ $0.0.name.lowercased().contains(searchText.lowercased()) })
        
        groupsTableViewDataSourceAndDelegate.set(models: foundGroupsModels)
        usersTableViewDataSourceAndDelegate.set(models: foundUsersModels)
        
        sharingAddRightHoldersView?.groupsTableView.reloadData()
        sharingAddRightHoldersView?.usersTableView.reloadData()
        
        if sharingAddRightHoldersView?.searchResultsTable.superview == nil {
            getSelectedTableView().removeFromSuperview()
            sharingAddRightHoldersView?.removeDarkenFromScreen()
            sharingAddRightHoldersView?.showSearchResultTable()
        }
        sharingAddRightHoldersView?.searchResultsTable.reloadData()
        
        if foundUsersModels.isEmpty && foundGroupsModels.isEmpty {
            sharingAddRightHoldersView?.showEmptyView(true)
        } else {
            sharingAddRightHoldersView?.showEmptyView(false)
        }
    }
    
    func willPresentSearchController(_ searchController: UISearchController) {
        if UIDevice.phone {
            navigationController?.isToolbarHidden = true
        }
        DispatchQueue.main.async {
            self.sharingAddRightHoldersView?.darkenScreen()
        }
        sharingAddRightHoldersView?.hideTablesSegmentedControl()
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        if UIDevice.phone {
            navigationController?.isToolbarHidden = false
        }
        sharingAddRightHoldersView?.removeDarkenFromScreen()
        
        groupsTableViewDataSourceAndDelegate.set(models: groupsModels)
        usersTableViewDataSourceAndDelegate.set(models: usersModels)
        
        sharingAddRightHoldersView?.groupsTableView.reloadData()
        sharingAddRightHoldersView?.usersTableView.reloadData()
        
        if getSelectedTableView().superview == nil {
            sharingAddRightHoldersView?.showTable(tableType: self.getSelectedTableType())
        }
        
        sharingAddRightHoldersView?.showTablesSegmentedControl()
        
        sharingAddRightHoldersView?.searchResultsTable.removeFromSuperview()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if UIDevice.phone {
            navigationController?.isToolbarHidden = false
        }
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        guard let tableType = RightHoldersTableType(rawValue: selectedScope) else { return }
        sharingAddRightHoldersView?.showTable(tableType: tableType)
        switch tableType {
        case .users:
            usersCurrentlyLoading ? runLoadingHud() : stopLoadingHud()
        case .groups:
            groupsCurrentlyLoading ? runLoadingHud() : stopLoadingHud()
        }
    }
}

// MARK: - Describe uses tables in enum
extension ASCSharingAddRightHoldersViewController {
    enum RightHoldersTableType: Int, CaseIterable {
        case users
        case groups
        
        func getTitle() -> String {
            switch self {
            case .users:
                return NSLocalizedString("Users", comment: "")
            case .groups:
                return NSLocalizedString("Groups", comment: "")
            }
        }
    }
}
