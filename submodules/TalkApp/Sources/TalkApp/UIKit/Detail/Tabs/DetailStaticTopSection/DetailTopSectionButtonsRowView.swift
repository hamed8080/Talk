//
//  DetailTopSectionButtonsRowView.swift
//  TalkApp
//
//  Created by Hamed Hosseini on 12/29/25.
//

import UIKit
import TalkViewModels

public class DetailTopSectionButtonsRowView: UIStackView {
    /// Views
    private let btnExit = DetailViewButtonItem(asssetImageName: "ic_exit")
    private let btnTrash = DetailViewButtonItem(systemName: "trash")
    private let btnAddContact = DetailViewButtonItem(systemName: "person.badge.plus")
    private let btnMute = DetailViewButtonItem(systemName: "bell.slash.fill")
    private let btnExportMessages = DetailViewButtonItem(asssetImageName: "ic_export")
    private let btnShowMore = DetailViewButtonItem(systemName: "ellipsis")
    
    /// Models
    public weak var detailVM: ThreadDetailViewModel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
        register()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureViews() {        
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
        alignment = .center
        distribution = .equalSpacing
        
        btnExit.onTap = { [weak self] in
            
        }
        
        btnTrash.onTap = { [weak self] in
            
        }
        
        btnAddContact.onTap = { [weak self] in
            
        }
        
        btnMute.onTap = { [weak self] in
            
        }
        
        btnExportMessages.onTap = { [weak self] in
            
        }
        
        btnShowMore.onTap = { [weak self] in
            
        }
        
        addArrangedSubviews([btnExit,
                             btnTrash,
                             btnAddContact,
                             btnMute,
                             btnExportMessages,
                             btnShowMore])
    }
    
    private func register() {
        
    }
}
