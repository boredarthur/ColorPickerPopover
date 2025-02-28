import AppKit

@objc
public protocol PopoverColorWellDelegate {
	@objc(colorWell:didChangeColor:)
    func colorWell(_ colorWell: PopoverColorWell, didChangeColor color: NSColor)
}

@objc(RAPopoverColorWell)
public class PopoverColorWell: NSColorWell {
	private let colorPanelViewController = ColorPanelViewController()

    @objc(delegate)
    public weak var delegate: PopoverColorWellDelegate?
	
	private static var popoverColorWells = [PopoverColorWell]()
	
	deinit {
		Self.popoverColorWells.removeAll { colorWell in colorWell == self }
		
		colorPanelViewController.delegate = nil
	}
	
	public override func viewDidMoveToSuperview() {
		let added = superview != nil
		
		if added {
			Self.popoverColorWells.append(self)
		} else {
			Self.popoverColorWells.removeAll { colorWell in colorWell == self }
		}
	}
	
	@objc
    public override func activate(_ exclusive: Bool) {
		colorPanelViewController.delegate = nil
		
		let deactivateAllColorWellsSelector = NSSelectorFromString("_deactivateAllColorWells")
		
		if NSColorWell.responds(to: deactivateAllColorWellsSelector) {
			NSColorWell.perform(deactivateAllColorWellsSelector)
		}
		
		for colorWell in Self.popoverColorWells {
			colorWell.deactivate()
		}
		
		NSColorPanel.shared.orderOut(self)
		
		presentInPopover()
    }
	
	@objc
	public override func deactivate() {
		colorPanelViewController.delegate = nil
		colorPanelViewController.unembedColorPanel()
		
		super.deactivate()
	}
}

private extension PopoverColorWell {
	func presentInPopover() {
		colorPanelViewController.delegate = nil
		
		let popover = NSPopover()
		
		popover.delegate = self
		popover.behavior = .semitransient
		popover.contentViewController = colorPanelViewController
		
		popover.show(relativeTo: frame,
					 of: self.superview!,
					 preferredEdge: .maxX)
		
		colorPanelViewController.color = color
		colorPanelViewController.delegate = self
	}
}

extension PopoverColorWell: NSPopoverDelegate {
	public func popoverWillClose(_ notification: Notification) {
		deactivate()
	}
}

extension PopoverColorWell: ColorPanelViewControllerDelegate {
	func colorPanelViewController(_ viewController: ColorPanelViewController, didChangeColor color: NSColor) {
		self.color = color
		delegate?.colorWell(self, didChangeColor: color)
	}
}
