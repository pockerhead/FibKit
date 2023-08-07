//
//  AppDelegate.swift
//  FibExampleApp
//
//  Created by Артём Балашов on 18.07.2023.
//

import FibKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
//		let view = UIView()
//		view.backgroundColor = .black
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
		DispatchQueue.main.async {
			let vc = ViewController()
			let nav = UINavigationController(rootViewController: vc)
			let window = UIWindow(frame: UIScreen.main.bounds)
			window.rootViewController = nav
			nav.view.backgroundColor = .alizarin
			window.makeKeyAndVisible()
		}
		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}


}

