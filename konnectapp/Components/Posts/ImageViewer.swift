import SwiftUI

struct ImageViewer: View {
    let imageURLs: [String]
    let initialIndex: Int
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    init(imageURLs: [String], initialIndex: Int = 0) {
        self.imageURLs = imageURLs
        self.initialIndex = initialIndex
        _currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .opacity(1.0 - abs(dragOffset) / 1000)
            
            PageViewController(
                pages: imageURLs.compactMap { URL(string: $0) },
                currentPage: $currentIndex
            )
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            isDragging = true
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 150 {
                            dismiss()
                        } else {
                            withAnimation {
                                dragOffset = 0
                                isDragging = false
                            }
                        }
                    }
            )
            
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                            )
                    }
                    .padding()
                    
                    Spacer()
                    
                    Text("\(currentIndex + 1) / \(imageURLs.count)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.5))
                        )
                        .padding()
                }
                
                Spacer()
            }
        }
    }
}

struct PageViewController: UIViewControllerRepresentable {
    let pages: [URL]
    @Binding var currentPage: Int
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        
        if !pages.isEmpty && currentPage < pages.count {
            let initialViewController = ImageViewController(imageURL: pages[currentPage])
            pageViewController.setViewControllers(
                [initialViewController],
                direction: .forward,
                animated: false
            )
        }
        
        return pageViewController
    }
    
    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        if !pages.isEmpty && currentPage < pages.count {
            let currentViewController = ImageViewController(imageURL: pages[currentPage])
            let direction: UIPageViewController.NavigationDirection = currentPage > context.coordinator.lastPage ? .forward : .reverse
            pageViewController.setViewControllers(
                [currentViewController],
                direction: direction,
                animated: true
            )
            context.coordinator.lastPage = currentPage
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PageViewController
        var lastPage: Int = 0
        
        init(_ parent: PageViewController) {
            self.parent = parent
            self.lastPage = parent.currentPage
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let imageViewController = viewController as? ImageViewController,
                  let currentIndex = parent.pages.firstIndex(of: imageViewController.imageURL),
                  currentIndex > 0 else {
                return nil
            }
            return ImageViewController(imageURL: parent.pages[currentIndex - 1])
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let imageViewController = viewController as? ImageViewController,
                  let currentIndex = parent.pages.firstIndex(of: imageViewController.imageURL),
                  currentIndex < parent.pages.count - 1 else {
                return nil
            }
            return ImageViewController(imageURL: parent.pages[currentIndex + 1])
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed,
               let currentViewController = pageViewController.viewControllers?.first as? ImageViewController,
               let index = parent.pages.firstIndex(of: currentViewController.imageURL) {
                parent.currentPage = index
                lastPage = index
            }
        }
    }
}

class ImageViewController: UIViewController {
    let imageURL: URL
    private var imageView: UIImageView?
    private var scrollView: UIScrollView?
    
    init(imageURL: URL) {
        self.imageURL = imageURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        let scrollView = UIScrollView()
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        view.addSubview(scrollView)
        self.scrollView = scrollView
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)
        self.imageView = imageView
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTap)
        
        loadImage()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateImageViewFrame()
    }
    
    private func updateImageViewFrame() {
        guard let imageView = imageView, let image = imageView.image, let scrollView = scrollView else { return }
        
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
        guard let scrollView = scrollView else { return }
        
        if scrollView.zoomScale > 1.0 {
            scrollView.setZoomScale(1.0, animated: true)
        } else {
            let point = gesture.location(in: imageView)
            let zoomRect = zoomRectForScale(scale: 2.0, center: point)
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        guard let scrollView = scrollView else { return .zero }
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
                    imageView?.image = image
                    updateImageViewFrame()
                }
                return
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                if let image = UIImage(data: data) {
                    CacheManager.shared.cachePostImage(url: imageURL, data: data)
                    await MainActor.run {
                        imageView?.image = image
                        updateImageViewFrame()
                    }
                }
            } catch {
                print("❌ Error loading image: \(error)")
            }
        }
    }
}

extension ImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard let imageView = imageView else { return }
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


