import SwiftUI
import UIKit

struct ImageViewer: View {
    let imageURLs: [String]
    let initialIndex: Int
    @Environment(\.dismiss) private var dismiss
    
    init(imageURLs: [String], initialIndex: Int = 0) {
        self.imageURLs = imageURLs
        self.initialIndex = initialIndex
    }
    
    var body: some View {
        ImageViewerController(
            imageURLs: imageURLs,
            initialIndex: initialIndex,
            onDismiss: { dismiss() }
        )
        .ignoresSafeArea()
    }
}

struct ImageViewerController: UIViewControllerRepresentable {
    let imageURLs: [String]
    let initialIndex: Int
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> ImageViewerViewController {
        let controller = ImageViewerViewController(
            imageURLs: imageURLs.compactMap { URL(string: $0) },
            initialIndex: initialIndex
        )
        controller.onDismiss = onDismiss
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ImageViewerViewController, context: Context) {}
}

class ImageViewerViewController: UIViewController {
    let imageURLs: [URL]
    let initialIndex: Int
    var onDismiss: (() -> Void)?
    
    private var pageViewController: UIPageViewController!
    private var currentIndex: Int = 0
    private var panGesture: UIPanGestureRecognizer!
    private var dragOffset: CGFloat = 0
    private var backgroundView: UIView!
    
    init(imageURLs: [URL], initialIndex: Int) {
        self.imageURLs = imageURLs
        self.initialIndex = initialIndex
        self.currentIndex = initialIndex
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        backgroundView = UIView()
        backgroundView.backgroundColor = .black
        view.addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        if !imageURLs.isEmpty && initialIndex < imageURLs.count {
            let initialVC = SingleImageViewController(imageURL: imageURLs[initialIndex])
            pageViewController.setViewControllers([initialVC], direction: .forward, animated: false)
        }
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        setupTopBar()
    }
    
    private func setupTopBar() {
        let topBar = UIView()
        topBar.backgroundColor = .clear
        view.addSubview(topBar)
        topBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = UIColor.label
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 20
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        topBar.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            closeButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        let counterLabel = UILabel()
        counterLabel.text = "\(currentIndex + 1) / \(imageURLs.count)"
        counterLabel.textColor = .white
        counterLabel.font = .systemFont(ofSize: 16, weight: .medium)
        counterLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        counterLabel.textAlignment = .center
        counterLabel.layer.cornerRadius = 16
        counterLabel.clipsToBounds = true
        topBar.addSubview(counterLabel)
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            counterLabel.centerXAnchor.constraint(equalTo: topBar.centerXAnchor),
            counterLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            counterLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            counterLabel.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        updateCounter = { [weak counterLabel, weak self] in
            guard let self = self else { return }
            counterLabel?.text = "\(self.currentIndex + 1) / \(self.imageURLs.count)"
        }
    }
    
    private var updateCounter: (() -> Void)?
    
    @objc private func closeTapped() {
        onDismiss?()
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let currentVC = pageViewController.viewControllers?.first as? SingleImageViewController,
              currentVC.scrollView.zoomScale <= 1.0 else {
            return
        }
        
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began, .changed:
            if translation.y > 0 {
                dragOffset = translation.y
                let progress = min(dragOffset / 300.0, 1.0)
                backgroundView.alpha = 1.0 - progress * 0.8
                currentVC.view.transform = CGAffineTransform(translationX: 0, y: dragOffset)
            }
        case .ended, .cancelled:
            if dragOffset > 150 || velocity.y > 500 {
                UIView.animate(withDuration: 0.3, animations: {
                    self.backgroundView.alpha = 0
                    currentVC.view.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
                }) { _ in
                    self.onDismiss?()
                }
            } else {
                UIView.animate(withDuration: 0.2) {
                    self.backgroundView.alpha = 1.0
                    currentVC.view.transform = .identity
                }
            }
            dragOffset = 0
        default:
            break
        }
    }
}

extension ImageViewerViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let imageVC = viewController as? SingleImageViewController,
              let index = imageURLs.firstIndex(of: imageVC.imageURL),
              index > 0 else {
            return nil
        }
        return SingleImageViewController(imageURL: imageURLs[index - 1])
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let imageVC = viewController as? SingleImageViewController,
              let index = imageURLs.firstIndex(of: imageVC.imageURL),
              index < imageURLs.count - 1 else {
            return nil
        }
        return SingleImageViewController(imageURL: imageURLs[index + 1])
    }
}

extension ImageViewerViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed,
           let currentVC = pageViewController.viewControllers?.first as? SingleImageViewController,
           let index = imageURLs.firstIndex(of: currentVC.imageURL) {
            currentIndex = index
            updateCounter?()
        }
    }
}

extension ImageViewerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer,
              let currentVC = pageViewController.viewControllers?.first as? SingleImageViewController else {
            return false
        }
        
        if currentVC.scrollView.zoomScale > 1.0 {
            return false
        }
        
        let translation = panGesture.translation(in: view)
        return abs(translation.y) > abs(translation.x) && translation.y > 0
    }
}

class SingleImageViewController: UIViewController {
    let imageURL: URL
    let scrollView: UIScrollView
    let imageView: UIImageView
    
    init(imageURL: URL) {
        self.imageURL = imageURL
        self.scrollView = UIScrollView()
        self.imageView = UIImageView()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)
        
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTap)
        
        loadImage()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateImageViewFrame()
    }
    
    private func updateImageViewFrame() {
        guard let image = imageView.image else { return }
        
        let imageSize = image.size
        let viewSize = view.bounds.size
        
        let widthScale = viewSize.width / imageSize.width
        let heightScale = viewSize.height / imageSize.height
        let scale = min(widthScale, heightScale)
        
        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        
        imageView.frame = CGRect(
            x: (viewSize.width - scaledSize.width) / 2,
            y: (viewSize.height - scaledSize.height) / 2,
            width: scaledSize.width,
            height: scaledSize.height
        )
        
        scrollView.contentSize = scaledSize
    }
    
    @objc private func doubleTapped(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > 1.0 {
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            let zoomRect = zoomRectForScale(scale: 2.0, center: point)
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = scrollView.frame.size.height / scale
        zoomRect.size.width = scrollView.frame.size.width / scale
        zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    private func loadImage() {
        Task {
            if let cachedData = CacheManager.shared.getCachedPostImage(url: imageURL),
               let image = UIImage(data: cachedData) {
                await MainActor.run {
                    imageView.image = image
                    updateImageViewFrame()
                }
                return
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                if let image = UIImage(data: data) {
                    CacheManager.shared.cachePostImage(url: imageURL, data: data)
                    await MainActor.run {
                        imageView.image = image
                        updateImageViewFrame()
                    }
                }
            } catch {
                print("❌ Error loading image: \(error)")
            }
        }
    }
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let boundsSize = scrollView.bounds.size
        var frameToCenter = imageView.frame
        
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        
        imageView.frame = frameToCenter
    }
}
