

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        // Show Splash Screen first
        let splashVC = SplashViewController()
        window.rootViewController = splashVC
        window.makeKeyAndVisible()
        
        // Execute app logic after splash delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            Task {
                if let role = try? await AuthService.shared.restoreSession() {
                    await MainActor.run {
                        let rootVC = self.makeRootViewController(for: role)
                        self.transitionFromSplash(to: rootVC)
                    }
                } else {
                    await MainActor.run {
                        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
                        if let initialVC = mainStoryboard.instantiateInitialViewController() {
                            self.transitionFromSplash(to: initialVC)
                        }
                    }
                }
            }
        }
    }
    
    private func transitionFromSplash(to viewController: UIViewController) {
        guard let window = self.window,
              let splashVC = window.rootViewController as? SplashViewController else {
            self.window?.rootViewController = viewController
            return
        }
        
        // Call the cinematic outro first
        splashVC.performOutro {
            window.rootViewController = viewController
            
            // Add a final subtle fade-in for the new root
            viewController.view.alpha = 0
            UIView.animate(withDuration: 0.3) {
                viewController.view.alpha = 1
            }
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    // MARK: - Routing

    private func makeRootViewController(for role: UserRole) -> UIViewController {
        switch role {
        case .trainer:
            return MainTabBarController()
        case .client:
            return ClientTabBarController()
        }
    }


}

