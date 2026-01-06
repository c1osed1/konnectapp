//
//  SearchBar.swift
//  konnectapp
//
//  Default UIKit search bar component
//

import SwiftUI
import UIKit

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Поиск"
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        
        // Make background completely transparent
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .clear
        searchBar.barTintColor = .clear
        searchBar.isTranslucent = true
        searchBar.searchTextField.backgroundColor = .clear
        
        // Remove all backgrounds from search text field
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .clear
            textField.background = UIImage()
            textField.borderStyle = .none
            // Remove background from text field's subviews
            for subview in textField.subviews {
                subview.backgroundColor = .clear
            }
        }
        
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
        
        // Keep background completely transparent on update
        uiView.backgroundImage = UIImage()
        uiView.backgroundColor = .clear
        uiView.barTintColor = .clear
        uiView.isTranslucent = true
        uiView.searchTextField.backgroundColor = .clear
        
        if let textField = uiView.value(forKey: "searchField") as? UITextField {
            textField.backgroundColor = .clear
            textField.background = UIImage()
            textField.borderStyle = .none
            for subview in textField.subviews {
                subview.backgroundColor = .clear
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UISearchBarDelegate {
        let parent: SearchBar
        
        init(_ parent: SearchBar) {
            self.parent = parent
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            parent.text = searchText
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
        
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            // Optional: can add logic here if needed
        }
        
        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
    }
}

