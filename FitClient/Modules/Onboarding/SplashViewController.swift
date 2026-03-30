
import UIKit

class SplashViewController: UIViewController {
    
    // MARK: - Properties
    private var characterLabels: [UILabel] = []
    private let fitText = "Fit"
    private let bondText = "Bond"
    
    private let hapticFeedback = UIImpactFeedbackGenerator(style: .medium)
    private let successFeedback = UINotificationFeedbackGenerator()
    
    // MARK: - UI Components
    private let bgGlowView: UIView = {
        let view = UIView()
        view.backgroundColor = .primaryGreen.withAlphaComponent(0.15)
        view.layer.cornerRadius = 100
        view.alpha = 0
        view.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        return view
    }()
    
    private let logoContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 0
        stack.alignment = .center
        return stack
    }()
    
    
    private let shimmerOverlay = UIView()
    private let emitterLayer = CAEmitterLayer()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        prepareAnimations()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startPremiumAnimation()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(bgGlowView)
        view.addSubview(logoContainer)
        bgGlowView.centerInSuperview(size: .init(width: 200, height: 200))
        logoContainer.centerInSuperview()
        
        setupCharacterLabels()
        setupParticles()
    }
    
    private func setupCharacterLabels() {
        // Create letters for Fit (Green)
        for char in fitText {
            let label = createLetterLabel(char: String(char), color: .primaryGreen)
            logoContainer.addArrangedSubview(label)
            characterLabels.append(label)
        }
        
        // Create letters for Bond (White)
        for char in bondText {
            let label = createLetterLabel(char: String(char), color: .white)
            logoContainer.addArrangedSubview(label)
            characterLabels.append(label)
        }
    }
    
    private func createLetterLabel(char: String, color: UIColor) -> UILabel {
        let label = UILabel()
        label.text = char
        label.font = .systemFont(ofSize: 52, weight: .black)
        label.textColor = color
        label.alpha = 0
        label.transform = CGAffineTransform(scaleX: 0.5, y: 0.5).translatedBy(x: 0, y: 20)
        return label
    }
    
    private func setupParticles() {
        emitterLayer.emitterPosition = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        emitterLayer.emitterShape = .circle
        emitterLayer.emitterSize = CGSize(width: 100, height: 100)
        
        let cell = CAEmitterCell()
        cell.birthRate = 0
        cell.lifetime = 1.5
        cell.velocity = 60
        cell.velocityRange = 30
        cell.emissionRange = .pi * 2
        cell.spin = 2
        cell.scale = 0.05
        cell.scaleRange = 0.02
        cell.alphaSpeed = -0.5
        cell.contents = createParticleImage()?.cgImage
        cell.color = UIColor.primaryGreen.withAlphaComponent(0.6).cgColor
        
        emitterLayer.emitterCells = [cell]
        view.layer.insertSublayer(emitterLayer, below: logoContainer.layer)
    }
    
    private func createParticleImage() -> UIImage? {
        let size = CGSize(width: 10, height: 10)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.white.cgColor)
        context?.fillEllipse(in: CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    private func prepareAnimations() {
        hapticFeedback.prepare()
        successFeedback.prepare()
    }
    
    // MARK: - Premium Animation Logic
    private func startPremiumAnimation() {
        // 1. Initial Glow Pulse
        UIView.animate(withDuration: 1.5, delay: 0, options: [.curveEaseInOut, .autoreverse, .repeat], animations: {
            self.bgGlowView.alpha = 0.4
            self.bgGlowView.transform = CGAffineTransform(scaleX: 1.8, y: 1.8)
        }, completion: nil)
        
        // 2. Staggered Character Entrance
        for (index, label) in characterLabels.enumerated() {
            let delay = 0.3 + (Double(index) * 0.08)
            
            UIView.animate(withDuration: 0.6, delay: delay, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: .curveEaseOut, animations: {
                label.alpha = 1
                label.transform = .identity
            }) { _ in
                self.hapticFeedback.impactOccurred(intensity: 0.4)
                if index == self.characterLabels.count - 1 {
                    self.showShimmerEffect()
                    self.burstParticles()
                }
            }
        }
    }
    
    private func burstParticles() {
        emitterLayer.birthRate = 12
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.emitterLayer.birthRate = 0
        }
    }
    
    private func showShimmerEffect() {
        // Final Shimmer Polish
        applyShimmerEffect()
    }
    
    private func applyShimmerEffect() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.3).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.locations = [0, 0.5, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = logoContainer.bounds
        
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = -logoContainer.bounds.width
        animation.toValue = logoContainer.bounds.width
        animation.duration = 1.2
        animation.repeatCount = 1
        
        logoContainer.layer.mask = gradientLayer // Temporary mask for shimmer simulation
        // Note: For a true shimmer we'd use a dedicated top layer but this is a clean native trick
        
        // Reverting to a more robust shimmer view
        let shimmerView = UIView(frame: logoContainer.frame)
        shimmerView.backgroundColor = .clear
        view.addSubview(shimmerView)
        shimmerView.layer.addSublayer(gradientLayer)
        
        gradientLayer.add(animation, forKey: "shimmerAnimation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            shimmerView.removeFromSuperview()
        }
    }
    
    // MARK: - Outro Animation
    func performOutro(completion: @escaping () -> Void) {
        successFeedback.notificationOccurred(.success)
        
        // Elegant logo shrink + fade to black
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
            self.logoContainer.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            self.logoContainer.alpha = 0
            self.bgGlowView.alpha = 0
        }) { _ in
            UIView.animate(withDuration: 0.3, animations: {
                self.view.alpha = 0
            }) { _ in
                completion()
            }
        }
    }
}

// MARK: - Layout Helpers
extension UIView {
    func centerInSuperview(size: CGSize? = nil) {
        guard let superview = self.superview else { return }
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.centerXAnchor.constraint(equalTo: superview.centerXAnchor),
            self.centerYAnchor.constraint(equalTo: superview.centerYAnchor)
        ])
        
        if let size = size {
            NSLayoutConstraint.activate([
                self.widthAnchor.constraint(equalToConstant: size.width),
                self.heightAnchor.constraint(equalToConstant: size.height)
            ])
        }
    }
}

// MARK: - Extension for letter spacing
extension UILabel {
    var letterSpacing: CGFloat {
        set {
            let attributedString: NSMutableAttributedString
            if let currentAttrString = attributedText {
                attributedString = NSMutableAttributedString(attributedString: currentAttrString)
            } else {
                attributedString = NSMutableAttributedString(string: text ?? "")
            }
            attributedString.addAttribute(NSAttributedString.Key.kern, value: newValue, range: NSRange(location: 0, length: attributedString.length))
            attributedText = attributedString
        }
        get {
            if let currentAttrString = attributedText {
                let attributes = currentAttrString.attributes(at: 0, effectiveRange: nil)
                if let kern = attributes[NSAttributedString.Key.kern] as? CGFloat {
                    return kern
                }
            }
            return 0
        }
    }
}
