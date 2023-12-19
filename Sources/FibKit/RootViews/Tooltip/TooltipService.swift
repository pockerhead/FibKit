//
//  TooltipService.swift
//  SmartStaff
//
//  Created by Orlov Maxim on 19.10.2022.
//  Copyright © 2022 DIT. All rights reserved.
//

import UIKit

open class ToolTipService {
	
	private var currentAppWindow: UIWindow?? {
		if let delegate = UIApplication.shared.connectedScenes.first?.delegate as? UIWindowSceneDelegate {
			return delegate.window
		}
		else {
			return UIApplication.shared.delegate?.window
		}
	}
	
	private final class TooltipViewController: UIViewController {
		override var preferredStatusBarStyle: UIStatusBarStyle {
			_preferredStatusBarStyle
		}
		var _preferredStatusBarStyle: UIStatusBarStyle = .default {
			didSet {
				setNeedsStatusBarAppearanceUpdate()
			}
		}
		
		init(_preferredStatusBarStyle: UIStatusBarStyle) {
			self._preferredStatusBarStyle = _preferredStatusBarStyle
			super.init(nibName: nil, bundle: nil)
		}
		
		required init?(coder: NSCoder) {
			super.init(coder: coder)
		}
	}
	
	private final class ToolTipWindow: UIWindow {
		
		var isAnimatingHide = false
		var completion: (() -> Void)?
		
		var _rootViewController: TooltipViewController? {
			rootViewController as? TooltipViewController
		}
		
		override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
			delay {
				self.hideSelf(animated: true)
			}
			return nil
		}
		
		func hideSelf(animated: Bool) {
			completion?()
			if !animated {
				isHidden = true
				resignKey()
			} else {
				isAnimatingHide = true
				withFibSpringAnimation {
					self.alpha = 0
				} completion: {[weak self] _ in
					guard self?.isAnimatingHide != false else { return }
					self?.isHidden = true
					self?.resignKey()
				}
			}
			
		}
	}
	
	public static let shared = ToolTipService()
	
	private let toolTipWindow: ToolTipWindow

	private var currentScene: UIWindowScene? {
		UIApplication.shared.connectedScenes.first as? UIWindowScene
	}
	private init() {
		self.toolTipWindow = ToolTipWindow()
		UIView.performWithoutAnimation {
			self.toolTipWindow.rootViewController = TooltipViewController(_preferredStatusBarStyle: .default)
			self.toolTipWindow.windowLevel = .alert
			toolTipWindow.backgroundColor = .clear
			self.toolTipWindow.isHidden = true
		}
	}
	
	public func hideTooltip(animated: Bool = true) {
		self.toolTipWindow.hideSelf(animated: animated)
	}
	
	public func showToolTip(for view: UIView, text: String, completion: (() -> Void)? = nil) {
		showToolTip(for: view, tooltipViewModel: TooltipLabel.ViewModel(text: text), markerView: TriangleView.ViewModel(), completion: completion)
	}
	
	public func showToolTip(for view: UIView, tooltipViewModel: FibCoreViewModel, markerView: TooltipMarkerViewModel?, completion: (() -> Void)? = nil) {
		let markerView: TooltipMarkerViewModel = markerView ?? TriangleView.ViewModel()
		guard let toolTipLabel = tooltipViewModel.getView() else { return }
		guard let marker = markerView.getView() as? FibCoreView else { return }
		UIView.performWithoutAnimation {
			self.toolTipWindow._rootViewController?._preferredStatusBarStyle = currentAppWindow??.windowScene?.statusBarManager?.statusBarStyle ?? .default
			self.toolTipWindow.alpha = 0
			toolTipWindow.subviews.forEach { $0.removeFromSuperview() }
			let viewFrame = view.superview?.convert(view.frame, to: nil) ?? .init(center: self.toolTipWindow.frame.center, size: CGSize(width: 10, height: 10))
			toolTipWindow.addSubview(marker)
			toolTipWindow.addSubview(toolTipLabel)
			toolTipWindow.completion = completion
			let screenWidth = UIScreen.main.bounds.width - 48
			let screenHeight = UIScreen.main.bounds.height
			var width =  toolTipLabel.sizeWith(.init(width: screenWidth, height: screenHeight), data: tooltipViewModel, horizontal: .fittingSizeLevel, vertical: .fittingSizeLevel)?.width ?? 0
			width = width > screenWidth ? screenWidth : width
			let height = toolTipLabel.sizeWith(.init(width: screenWidth, height: screenHeight), data: tooltipViewModel, horizontal: .fittingSizeLevel, vertical: .fittingSizeLevel)?.height ?? 0
			
			toolTipLabel.frame.size = .init(width: width, height: height)
			toolTipLabel.configure(with: tooltipViewModel)
			
			marker.frame.size = marker.sizeWith(.init(width: screenWidth, height: screenHeight), data: markerView, horizontal: .fittingSizeLevel, vertical: .fittingSizeLevel) ?? CGSize(width: 10, height: 10)
			let triangleX = viewFrame.center.x - 5
			
			if viewFrame.minY > screenHeight / 2 {
				toolTipLabel.frame.origin.y = viewFrame.minY - (height + marker.frame.height - 4)
				markerView.orientation = .down
				marker.frame.origin = .init(x: triangleX, y: toolTipLabel.frame.maxY)
			} else if viewFrame.maxY < screenHeight / 2 {
				toolTipLabel.frame.origin.y = viewFrame.maxY + 4
				markerView.orientation = .up
				marker.frame.origin = .init(x: triangleX, y: toolTipLabel.frame.minY - 4)
			} else {
				toolTipLabel.frame.origin.y = viewFrame.maxY + 4
				marker.frame.origin = .init(x: triangleX, y: toolTipLabel.frame.minY - 4)
				markerView.orientation = .up
			}
			marker.configure(with: markerView)
			let idealX = viewFrame.maxX - toolTipLabel.bounds.width + 12
			toolTipLabel.frame.origin.x = idealX.clamp(16, UIScreen.main.bounds.width - toolTipLabel.bounds.width - 16)
			marker.frame.origin.x = triangleX.clamp(toolTipLabel.frame.origin.x + 4, toolTipLabel.frame.maxX - 14)
			
			toolTipWindow.makeKeyAndVisible()
			toolTipWindow.windowScene = currentScene
			toolTipWindow.isAnimatingHide = false
			delay {
				withFibSpringAnimation {
					self.toolTipWindow.alpha = 1
				}
			}
		}
		
	}
}
