//
//  SceneDelegate.swift
//  FibExampleApp
//
//  Created by Артём Балашов on 18.07.2023.
//

import FibKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?


	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

		guard let windowScene = (scene as? UIWindowScene) else { return }
		
		FibViewController.defaultConfiguration = .init(viewConfiguration: .init(roundedShutterBackground: .black.withAlphaComponent(0.2), shutterBackground: .black.withAlphaComponent(0.4), viewBackgroundColor: .white, shutterType: .rounded, backgroundView: nil))
		RoundedCell.defaultRoundedCellAppearance.shadowClosure = { view in
			view.layer.shadowColor = UIColor.black.cgColor
			view.layer.shadowRadius = 10
			view.layer.shadowOpacity = 1
		}
		let appearance = UINavigationBarAppearance()
		appearance.configureWithTransparentBackground()
		appearance.backgroundColor = UIColor.clear
		appearance.backgroundEffect = UIBlurEffect(style: .dark) // or dark
		appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
		
		let scrollingAppearance = UINavigationBarAppearance()
		scrollingAppearance.configureWithTransparentBackground()
		//		scrollingAppearance.backgroundColor = .white // your view (superview) color
		
		UINavigationBar.appearance().standardAppearance = appearance
		UINavigationBar.appearance().scrollEdgeAppearance = appearance
		UINavigationBar.appearance().compactAppearance = appearance
		let vc = ViewController()
		let nav = UINavigationController(rootViewController: vc)
		window = UIWindow(windowScene: windowScene)
		window?.rootViewController = nav
		nav.view.backgroundColor = .alizarin
		window?.makeKeyAndVisible()
		
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


}

