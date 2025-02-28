import AppKit

internal protocol ColorPanelViewControllerDelegate: AnyObject {
	func colorPanelViewController(_ viewController: ColorPanelViewController, didChangeColor color: NSColor)
}

internal class ColorPanelViewController: NSViewController {
	weak var delegate: ColorPanelViewControllerDelegate?
	
	private var isObserving = false
	
	private let colorKeyPath = (\NSColorPanel.color)._kvcKeyPathString ?? "color"
	private let updateSwatchSelector = NSSelectorFromString("updateSwatch")
	private let colorSwatchClassName = "NSColorSwatch"
	
	private let toolbarHeight: CGFloat = 20
	private let toolbarXMargin: CGFloat = 6
	private let toolbarTopYMargin: CGFloat = 10
	private let toolbarBottomYMargin: CGFloat = 2
	
	private var colorPanel: NSColorPanel { .shared }
	private var colorPanelToolbar: NSToolbar? { colorPanel.toolbar }
	private var colorView: NSView?
	private var toolbarView: NSSegmentedControl?
	
	var showsAlpha: Bool {
		get { colorPanel.showsAlpha }
		set { colorPanel.showsAlpha = newValue }
	}
	
	var mode: NSColorPanel.Mode {
		get { colorPanel.mode }
		set { colorPanel.mode = newValue }
	}
	
	var color: NSColor {
		get { colorPanel.color }
		set { colorPanel.color = newValue }
	}
	
	var alpha: CGFloat {
		colorPanel.alpha
	}
	
	deinit {
		unembedColorPanel()
	}
    
    override func loadView() {
		if !isViewLoaded {
			view = NSView()
		}
		
		guard let colorView = colorPanel.contentView else { return }
		
		let frame = NSRect(x: 0,
						   y: 0,
						   width: colorView.bounds.width,
						   height: colorView.bounds.height + toolbarTopYMargin + toolbarBottomYMargin + toolbarHeight)
		
		view.frame = frame
    }
	
	override func viewWillAppear() {
        NSColorPanel.setPickerMask([
            .wheelModeMask,
            .rgbModeMask,
            .cmykModeMask,
            .hsbModeMask,
            .grayModeMask
        ])
        
		embedColorPanel()
	}
	
	override func viewWillDisappear() {
		unembedColorPanel()
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
		switch keyPath {
		case colorKeyPath:
			guard let panel = object as? NSColorPanel,
				  panel == colorPanel else {
				return
			}
			
			delegate?.colorPanelViewController(self, didChangeColor: color)
		default:
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}
}

extension ColorPanelViewController {
	func unembedColorPanel() {
		stopObservingColor()
		
		if let toolbarView = toolbarView {
			toolbarView.removeFromSuperview()
			self.toolbarView = nil
		}
		
		if let colorView = colorView {
			colorView.removeFromSuperview()
			colorPanel.contentView = colorView
			self.colorView = nil
		}
	}
}

private extension ColorPanelViewController {
	func embedColorPanel() {
		if NSColorPanel.sharedColorPanelExists && colorPanel.isVisible {
			colorPanel.orderOut(self)
		}
		
		guard let colorView = colorPanel.contentView else {
			self.colorView = nil
			
			return
		}
		
		view.addSubview(colorView)
		self.colorView = colorView
		
		if let swatch = locateColorSwatch() {
			swatch.perform(updateSwatchSelector)
		}
		
		let toolbarView = createToolbarView()
		view.addSubview(toolbarView)
		self.toolbarView = toolbarView
		
		startObservingColor()
	}
	
	func createToolbarView() -> NSSegmentedControl {
		var toolbarImages = [NSImage]()
		var toolbarTooltips = [String]()
		
		var selectedToolbarItemIndex = -1
		
		if let toolbar = colorPanelToolbar {
			var index = 0
			
			for toolbarItem in toolbar.items {
				let identifier = toolbarItem.itemIdentifier
				let toolTip = toolbarItem.toolTip
				let icon = toolbarItem.image
				let isSelected = identifier == toolbar.selectedItemIdentifier
				
				if let icon = icon {
					if isSelected {
						selectedToolbarItemIndex = index
					}
					
					toolbarImages.append(icon)
					toolbarTooltips.append(toolTip ?? "")
				}
				
				index += 1
			}
		}
		
		let segmentedControl = NSSegmentedControl(images: toolbarImages,
												  trackingMode: .selectOne,
												  target: self,
												  action: #selector(toolbarSegment_action(_:)))
		
		segmentedControl.selectedSegment = selectedToolbarItemIndex
		
		for (idx, toolbarTooltip) in toolbarTooltips.enumerated() {
			segmentedControl.setAlignment(.right, forSegment: idx)
			segmentedControl.setToolTip(toolbarTooltip, forSegment: idx)
		}
		
		let toolbarSize = segmentedControl.fittingSize
		let toolbarFrame = NSRect(x: toolbarXMargin,
								  y: view.bounds.maxY - toolbarSize.height - toolbarTopYMargin,
								  width: view.bounds.width - (toolbarXMargin * 2.0),
								  height: toolbarSize.height)
		
		segmentedControl.frame = toolbarFrame
		
		return segmentedControl
	}
	
	@objc
	func toolbarSegment_action(_ sender: NSSegmentedControl) {
		guard let toolbar = colorPanelToolbar else { return }
		
		let selectedIndex = sender.selectedSegment
		
		guard selectedIndex >= 0,
			  selectedIndex < toolbar.items.count else { return }
		
		let toolbarItem = toolbar.items[selectedIndex]

		if let target = toolbarItem.target {
			if let action = toolbarItem.action {
				_ = target.perform(action, with: toolbarItem)
			}
		}
	}
	
	func startObservingColor() {
		colorPanel.addObserver(self,
							   forKeyPath: colorKeyPath,
							   options: .new,
							   context: nil)
		
		isObserving = true
	}
	
	func stopObservingColor() {
		guard isObserving else { return }
		
		colorPanel.removeObserver(self,
								  forKeyPath: colorKeyPath)
		
		isObserving = false
	}
	
    func locateColorSwatch() -> NSView? {
		guard let rootView = colorPanel.contentView else { return nil }
		
		return findSwatchInSubviews(view: rootView)
    }
    
    func findSwatchInSubviews(view: NSView) -> NSView? {
        for subview in view.subviews {
            if subview.className == colorSwatchClassName {
                return subview
            } else if let foundView = findSwatchInSubviews(view: subview) {
                return foundView
            }
        }
        
        return nil
    }
}
