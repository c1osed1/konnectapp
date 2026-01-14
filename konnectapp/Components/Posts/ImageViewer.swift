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
    private var toastLabel: UILabel?
    private var topShadeView: UIView!
    private var topShadeGradient: CAGradientLayer?
    
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topShadeGradient?.frame = topShadeView.bounds
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

        // Плавное затемнение в зоне статус-бара/верхней safe-area (чтобы часы/батарея читались лучше)
        setupTopShade()
        
        if !imageURLs.isEmpty && initialIndex < imageURLs.count {
            let initialVC = SingleImageViewController(imageURL: imageURLs[initialIndex])
            pageViewController.setViewControllers([initialVC], direction: .forward, animated: false)
        }
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        setupTopBar()
    }

    private func setupTopShade() {
        topShadeView = UIView()
        topShadeView.backgroundColor = .clear
        topShadeView.isUserInteractionEnabled = false
        view.addSubview(topShadeView)
        topShadeView.translatesAutoresizingMaskIntoConstraints = false

        // Высота включает safe-area + верхнюю панель
        NSLayoutConstraint.activate([
            topShadeView.topAnchor.constraint(equalTo: view.topAnchor),
            topShadeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topShadeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topShadeView.heightAnchor.constraint(equalToConstant: 140)
        ])

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.black.withAlphaComponent(0.55).cgColor,
            UIColor.black.withAlphaComponent(0.0).cgColor
        ]
        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradient.frame = topShadeView.bounds
        topShadeView.layer.insertSublayer(gradient, at: 0)
        topShadeGradient = gradient
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

        let saveButton = UIButton(type: .system)
        saveButton.setImage(UIImage(systemName: "arrow.down.to.line"), for: .normal)
        saveButton.tintColor = UIColor.label
        saveButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        saveButton.layer.cornerRadius = 20
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        topBar.addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            saveButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            saveButton.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            saveButton.widthAnchor.constraint(equalToConstant: 40),
            saveButton.heightAnchor.constraint(equalToConstant: 40)
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

    @objc private func saveTapped() {
        Task { [weak self] in
            await self?.saveCurrentImage()
        }
    }

    @MainActor
    private func showToast(_ text: String) {
        toastLabel?.removeFromSuperview()
        
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.layer.cornerRadius = 12
        label.clipsToBounds = true
        
        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            label.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.85),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])
        
        toastLabel = label
        
        UIView.animate(withDuration: 0.2, delay: 1.4, options: [.curveEaseInOut]) {
            label.alpha = 0
        } completion: { _ in
            label.removeFromSuperview()
        }
    }

    private func currentImageFromVisibleController() -> UIImage? {
        guard let currentVC = pageViewController.viewControllers?.first as? SingleImageViewController else {
            return nil
        }
        return currentVC.imageView.image
    }

    private func currentImageURL() -> URL? {
        guard currentIndex >= 0, currentIndex < imageURLs.count else { return nil }
        return imageURLs[currentIndex]
    }

    private func saveCurrentImage() async {
        guard let url = currentImageURL() else { return }
        
        // 1) Пытаемся взять уже отображаемую картинку
        if let img = currentImageFromVisibleController() {
            await saveToPhotos(img)
            return
        }
        
        // 2) Пытаемся из кеша
        if let cachedData = CacheManager.shared.getCachedPostImage(url: url),
           let img = UIImage(data: cachedData) {
            await saveToPhotos(img)
            return
        }
        
        // 3) Качаем
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let img = UIImage(data: data) {
                CacheManager.shared.cachePostImage(url: url, data: data)
                await saveToPhotos(img)
            } else {
                await MainActor.run { showToast("Не удалось сохранить") }
            }
        } catch {
            await MainActor.run { showToast("Ошибка загрузки") }
        }
    }

    private func saveToPhotos(_ image: UIImage) async {
        await MainActor.run {
            // Важно: многие картинки приходят как WebP (.webp). UIImage может отрисовываться,
            // но при сохранении iOS иногда пытается писать в исходном формате (org.webmproject.webp),
            // и Photos падает с "unsupported output file format".
            // Поэтому перед сохранением принудительно "перерисовываем" в bitmap (PNG/JPEG-совместимый).
            let safeImage = self.makeBitmapImage(from: image)
            UIImageWriteToSavedPhotosAlbum(safeImage, self, #selector(imageSaveFinished(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }

    private func makeBitmapImage(from image: UIImage) -> UIImage {
        let targetSize = image.size
        guard targetSize.width > 0, targetSize.height > 0 else { return image }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    @objc private func imageSaveFinished(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let _ = error {
            Task { @MainActor in
                showToast("Не удалось сохранить")
            }
        } else {
            Task { @MainActor in
                showToast("Сохранено в Фото")
            }
        }
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
