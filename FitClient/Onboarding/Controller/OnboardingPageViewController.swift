//
//  OnboardingPageViewController.swift
//  FitClient
//

import UIKit

class OnboardingPageViewController: UIPageViewController {

    var pages = [UIViewController]()
    let pageControl = UIPageControl()
    let initialPage = 0

    private var pageControlCenterXConstraint: NSLayoutConstraint?
    private var pageControlTopConstraint: NSLayoutConstraint?
    private var pageControlHeightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = self
        delegate = self

        // Load pages
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let page1 = storyboard.instantiateViewController(withIdentifier: "OnboardingScreen1") as? OnboardingScreen1ViewController,
           let page2 = storyboard.instantiateViewController(withIdentifier: "OnboardingScreen2") as? OnboardingScreen2ViewController,
           let page3 = storyboard.instantiateViewController(withIdentifier: "OnboardingScreen3") as? OnboardingScreen3ViewController {

            pages = [page1, page2, page3]
            setViewControllers([pages[initialPage]], direction: .forward, animated: true, completion: nil)
        }

        view.backgroundColor = .black
        setupPageControl()
    }

    private func setupPageControl() {
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = initialPage
        pageControl.pageIndicatorTintColor = UIColor(white: 1.0, alpha: 0.3)
        pageControl.currentPageIndicatorTintColor = .primaryGreen
        pageControl.translatesAutoresizingMaskIntoConstraints = false

        // respond to dot taps
        pageControl.addTarget(self, action: #selector(pageControlTapped(_:)), for: .valueChanged)

        view.addSubview(pageControl)

        pageControlCenterXConstraint = pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        pageControlHeightConstraint = pageControl.heightAnchor.constraint(equalToConstant: 12)

        NSLayoutConstraint.activate([
            pageControlCenterXConstraint!,
            pageControlHeightConstraint!
        ])

        // temporary constraint to avoid unsatisfied layout until updated later
        pageControlTopConstraint = pageControl.topAnchor.constraint(equalTo: view.topAnchor, constant: 200)
        pageControlTopConstraint?.isActive = true
    }

    @objc private func pageControlTapped(_ sender: UIPageControl) {
        let page = sender.currentPage
        let direction: UIPageViewController.NavigationDirection = (page > (pages.firstIndex(of: viewControllers!.first!) ?? 0)) ? .forward : .reverse
        setViewControllers([pages[page]], direction: direction, animated: true, completion: { [weak self] completed in
            if completed {
                self?.updatePageControlPositionRelativeToImage(of: self?.pages[page])
            }
        })
    }

    private func updatePageControlPositionRelativeToImage(of childVC: UIViewController?) {
        guard let child = childVC else { return }

        var imageView: UIImageView?
        if let vc = child as? OnboardingScreen1ViewController { imageView = vc.imageView }
        else if let vc = child as? OnboardingScreen2ViewController { imageView = vc.imageView }
        else if let vc = child as? OnboardingScreen3ViewController { imageView = vc.imageView }

        if let img = imageView, img.window != nil {
            let imageBottomInParent = img.convert(CGPoint(x: 0, y: img.bounds.maxY), to: self.view).y
            let spacing: CGFloat = 20.0

            if let old = pageControlTopConstraint {
                old.isActive = false
            }

            pageControlTopConstraint = pageControl.topAnchor.constraint(equalTo: view.topAnchor, constant: imageBottomInParent + spacing)
            pageControlTopConstraint?.isActive = true

            view.layoutIfNeeded()
            return
        }

        if let old = pageControlTopConstraint {
            old.isActive = false
        }
        pageControlTopConstraint = pageControl.topAnchor.constraint(equalTo: view.topAnchor, constant: view.safeAreaInsets.top + 300)
        pageControlTopConstraint?.isActive = true
        view.layoutIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePageControlPositionRelativeToImage(of: viewControllers?.first)
    }
}

// MARK: - DataSource
extension OnboardingPageViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let idx = pages.firstIndex(of: viewController), idx > 0 else { return nil }
        return pages[idx - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let idx = pages.firstIndex(of: viewController), idx < pages.count - 1 else { return nil }
        return pages[idx + 1]
    }
}

// MARK: - Delegate
extension OnboardingPageViewController: UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {

        guard completed,
              let current = pageViewController.viewControllers?.first,
              let index = pages.firstIndex(of: current) else { return }

        pageControl.currentPage = index

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updatePageControlPositionRelativeToImage(of: current)
        }
    }
}

