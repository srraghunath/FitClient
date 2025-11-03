//
//  OnboardingPageViewController.swift
//  FitClient
//
//  Created by admin41 on 03/11/25.
//

import UIKit

class OnboardingPageViewController: UIPageViewController {
    
    var pages = [UIViewController]()
    let pageControl = UIPageControl()
    let initialPage = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        delegate = self
        
        // Create pages from storyboard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let page1 = storyboard.instantiateViewController(withIdentifier: "OnboardingScreen1") as? OnboardingScreen1ViewController,
           let page2 = storyboard.instantiateViewController(withIdentifier: "OnboardingScreen2") as? OnboardingScreen2ViewController,
           let page3 = storyboard.instantiateViewController(withIdentifier: "OnboardingScreen3") as? OnboardingScreen3ViewController {
            
            pages.append(page1)
            pages.append(page2)
            pages.append(page3)
            
            setViewControllers([pages[initialPage]], direction: .forward, animated: true, completion: nil)
        }
        
        view.backgroundColor = .black
        
        // Setup UIPageControl
        setupPageControl()
    }
    
    private func setupPageControl() {
        pageControl.numberOfPages = pages.count
        pageControl.currentPage = initialPage
        
        // Style the page control to match Figma design
        pageControl.pageIndicatorTintColor = UIColor(red: 128/255, green: 128/255, blue: 128/255, alpha: 0.5)
        pageControl.currentPageIndicatorTintColor = UIColor(red: 174/255, green: 254/255, blue: 20/255, alpha: 1.0) // Lime green
        pageControl.backgroundColor = .clear
        
        // Add to view
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)
        
        // Position it exactly where the indicators are in Figma (below image, above title)
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 503), // 495 + 8
            pageControl.heightAnchor.constraint(equalToConstant: 10)
        ])
    }
}

// MARK: - UIPageViewControllerDataSource
extension OnboardingPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = pages.firstIndex(of: viewController) else { return nil }
        
        if currentIndex == 0 {
            return nil
        } else {
            return pages[currentIndex - 1]
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentIndex = pages.firstIndex(of: viewController) else { return nil }
        
        if currentIndex < pages.count - 1 {
            return pages[currentIndex + 1]
        } else {
            return nil
        }
    }
}

// MARK: - UIPageViewControllerDelegate
extension OnboardingPageViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        guard let viewControllers = pageViewController.viewControllers else { return }
        guard let currentIndex = pages.firstIndex(of: viewControllers[0]) else { return }
        
        // Update page control
        pageControl.currentPage = currentIndex
        
        // Update page control or handle page changes here if needed
    }
}
