//
//  MorphModalWrapper.swift
//  kawaii
//
//  Created by ai on 7/06/25.
//

import SwiftUI
import UIKit
import MorphModalKit

struct MorphModalTestView: View {
    @State private var showingModal = false
    
    var body: some View {
        ZStack {
            Color.blue.opacity(0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("MorphModalKit Test")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Tap the button below to see the MenuModal with card stacking")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("Show Menu Modal") {
                    presentMenuModal()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .background(ModalHostingView())
    }
    
    private func presentMenuModal() {
        // Find the current UIViewController and present the modal
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            let hostVC = findHostViewController(from: rootVC)
            hostVC?.presentModal(MenuModal())
        }
    }
    
    private func findHostViewController(from viewController: UIViewController) -> UIViewController? {
        if let presented = viewController.presentedViewController {
            return findHostViewController(from: presented)
        }
        
        if let nav = viewController as? UINavigationController {
            return findHostViewController(from: nav.visibleViewController ?? nav)
        }
        
        if let tab = viewController as? UITabBarController {
            return findHostViewController(from: tab.selectedViewController ?? tab)
        }
        
        return viewController
    }
}

// MARK: - Modal Hosting View
private struct ModalHostingView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return UIViewController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    MorphModalTestView()
}
