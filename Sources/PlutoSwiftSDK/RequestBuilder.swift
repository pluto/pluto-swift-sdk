import UIKit

public class RequestBuilder {
    // UI references
    private var browserView: BrowserView?
    private var injector: Injector?

    // Callback to notify the outside world that the final manifest is constructed
    public var onManifestConstructed: ((ManifestFile) -> Void)?

    // The parent VC in which we show the browser (and hold the injector)
    private weak var parentVC: UIViewController?

    // MARK: - Init
    public init(parentViewController: UIViewController) {
        self.parentVC = parentViewController
    }

    // MARK: - Show Browser
    public func showBrowserView(with manifest: ManifestFile, prepareJS: String? = nil) {
        guard let parentVC = parentVC else { return }

        let browser = BrowserView()
        self.browserView = browser

        // When the BrowserView captures data:
        browser.onCapture = { [weak self] cookies, dom in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.didCaptureData(cookies: cookies, dom: dom, manifest: manifest, prepareJS: prepareJS)
            }
        }

        // Present the BrowserView
        browser.present(with: manifest, in: parentVC)
    }

    // 1) Called once we have initial cookies/DOM/manifest
    // 2) If the Injector doesn’t exist yet, create it now
    // 3) Otherwise, update the existing Injector
    private func didCaptureData(cookies: [HTTPCookie],
                                dom: String,
                                manifest: ManifestFile,
                                prepareJS: String?) {
        // Transform cookies into a dictionary keyed by cookie name
        let cookiesDict = self.cookiesDictionary(from: cookies)

        // If no injector yet, create one
        if injector == nil {
            createInjector(manifest: manifest,
                           cookies: cookiesDict,
                           dom: dom,
                           prepareJS: prepareJS)
        } else {
            // If we already have an injector, just update it
            injector?.updateData(cookies: cookiesDict, dom: dom)
        }
    }

    private func createInjector(manifest: ManifestFile,
                                cookies: [String: HTTPCookie],
                                dom: String,
                                prepareJS: String?) {
        guard let parentVC = parentVC else { return }

        let newInjector = Injector(manifest: manifest,
                                   cookies: cookies,
                                   initialDOM: dom,
                                   prepareJS: prepareJS)
        newInjector.isHidden = true
        newInjector.isUserInteractionEnabled = false
        self.injector = newInjector

        // When the Injector completes, we finalize everything
        newInjector.onComplete = { [weak self] updatedManifest in
            guard let self = self else { return }

            // Pass final manifest up
            self.onManifestConstructed?(updatedManifest)

            // Tear everything down
            self.cleanup()
        }

        // Add the Injector’s view to the parent if needed (hidden or offscreen)
        parentVC.view.addSubview(newInjector)
        newInjector.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newInjector.topAnchor.constraint(equalTo: parentVC.view.topAnchor),
            newInjector.leadingAnchor.constraint(equalTo: parentVC.view.leadingAnchor),
            newInjector.trailingAnchor.constraint(equalTo: parentVC.view.trailingAnchor),
            newInjector.bottomAnchor.constraint(equalTo: parentVC.view.bottomAnchor)
        ])
    }

    // This might be called multiple times whenever the BrowserView updates cookies/DOM
    public func updateInjectorData(cookies: [HTTPCookie], dom: String) {
        let cookiesDict = self.cookiesDictionary(from: cookies)
        injector?.updateData(cookies: cookiesDict, dom: dom)
    }

    // Remove everything from memory
    private func cleanup() {
        // Remove browserView if present
        browserView?.removeFromSuperview()
        browserView = nil

        // Remove injector
        injector?.close()
        injector = nil
    }

    // Helper function to convert [HTTPCookie] -> [String : HTTPCookie]
    private func cookiesDictionary(from cookies: [HTTPCookie]) -> [String: HTTPCookie] {
        var dict = [String: HTTPCookie]()
        for cookie in cookies {
            dict[cookie.name] = cookie
        }
        return dict
    }
}
