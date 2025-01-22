import UIKit

public class RequestBuilder {
    // MARK: - Properties
    private var browserView: BrowserView?
    private var injector: Injector?
    private var onManifestConstructed: ((ManifestFile) -> Void)?
    private weak var parentVC: UIViewController?

    private var manifest: ManifestFile?
    private var prepareJS: String?
    private var retainSelf: RequestBuilder?

    // MARK: - Initialization
    public init(parentViewController: UIViewController) {
        self.parentVC = parentViewController
    }

    // MARK: - Builder Methods
    @discardableResult
    public func withManifest(_ manifest: ManifestFile) -> RequestBuilder {
        self.manifest = manifest
        return self
    }

    @discardableResult
    public func withPrepareJS(_ prepareJS: String) -> RequestBuilder {
        self.prepareJS = prepareJS
        return self
    }

    // MARK: - Browser Presentation
    public func showBrowserView(onManifestConstructed: @escaping (ManifestFile) -> Void) throws {
        guard let manifest = self.manifest else {
            throw RequestBuilderError.manifestRequired
        }

        guard let parentVC = parentVC else {
            throw RequestBuilderError.noParentViewController
        }

        retainSelf = self
        self.onManifestConstructed = onManifestConstructed

        let browser = BrowserView()
        self.browserView = browser

        browser.onCapture = { [weak self] cookies, dom in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.didCaptureData(cookies: cookies, dom: dom, manifest: manifest, prepareJS: self.prepareJS)
            }
        }

        browser.onClose = { [weak self] in
            self?.retainSelf = nil
        }

        browser.present(with: manifest, in: parentVC)
    }

    // MARK: - Private Methods
    private func didCaptureData(cookies: [HTTPCookie],
                              dom: String,
                              manifest: ManifestFile,
                              prepareJS: String?) {
        let cookiesDict = self.cookiesDictionary(from: cookies)

        if injector == nil {
            createInjector(manifest: manifest,
                         cookies: cookiesDict,
                         dom: dom,
                         prepareJS: prepareJS)
        } else {
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

        newInjector.onComplete = { [weak self] updatedManifest in
            guard let self = self else { return }
            self.onManifestConstructed?(updatedManifest)
            self.cleanup()
        }

        parentVC.view.addSubview(newInjector)
        newInjector.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newInjector.topAnchor.constraint(equalTo: parentVC.view.topAnchor),
            newInjector.leadingAnchor.constraint(equalTo: parentVC.view.leadingAnchor),
            newInjector.trailingAnchor.constraint(equalTo: parentVC.view.trailingAnchor),
            newInjector.bottomAnchor.constraint(equalTo: parentVC.view.bottomAnchor)
        ])
    }

    private func cookiesDictionary(from cookies: [HTTPCookie]) -> [String: HTTPCookie] {
        var dict = [String: HTTPCookie]()
        for cookie in cookies {
            dict[cookie.name] = cookie
        }
        return dict
    }

    private func cleanup() {
        browserView?.removeFromSuperview()
        browserView = nil
        injector?.close()
        injector = nil
        retainSelf = nil
    }

    // MARK: - Error Types
    public enum RequestBuilderError: Error {
        case manifestRequired
        case noParentViewController
    }
}
