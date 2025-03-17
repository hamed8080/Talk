//
//  MapPickerViewController.swift
//  Talk
//
//  Created by hamed on 3/14/23.
//

import Chat
import MapKit
import SwiftUI
import TalkModels
import TalkUI
import TalkViewModels
import ChatCore
import Combine
import WebKit

@MainActor
public final class MapPickerViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
    // Views
    private let mapView = MKMapView()
    private let btnClose = UIImageButton(imagePadding: .init(all: 8))
    private let btnSubmit = SubmitBottomButtonUIView(text: "General.add")
    private let toastView = ToastUIView(message: AppErrorTypes.location_access_denied.localized, disableWidthConstraint: true)
    private let btnLocateMe = UIButton()
    private let btnMapSwap = UIButton()
    private var webView = WKWebView()

    // Models
    private var cancellableSet = Set<AnyCancellable>()
    private var locationManager: LocationManager = .init()
    public var viewModel: ThreadViewModel?
    private var canUpdate = true
    private let annotation = MKPointAnnotation()
    private var showOSMMap = true

    // Constarints
    private var heightSubmitConstraint: NSLayoutConstraint!

    public override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        showOSM()
        registerObservers()
    }

    private func configureViews() {
        let style: UIUserInterfaceStyle = AppSettingsModel.restore().isDarkModeEnabled == true ? .dark : .light
        overrideUserInterfaceStyle = style
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.delegate = self
        mapView.accessibilityIdentifier = "mapViewMapPickerViewController"
        mapView.overrideUserInterfaceStyle = style
        
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "locationHandler") // Add message handler
        config.userContentController.add(self, name: "consoleHandler") // Add log handler
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
  
        
        // Swap between Apple Maps and OSM
        btnMapSwap.translatesAutoresizingMaskIntoConstraints = false
        btnMapSwap.setImage(UIImage(systemName: "apple.logo"), for: .normal)
        btnMapSwap.tintColor = Color.App.accentUIColor
        btnMapSwap.backgroundColor = .black
        btnMapSwap.layer.cornerRadius = 24
        btnMapSwap.addTarget(self, action: #selector(swapToAppleMaps), for: .touchUpInside)
        view.addSubview(btnMapSwap)
        
        // Configure Locate Me button
        btnLocateMe.translatesAutoresizingMaskIntoConstraints = false
        btnLocateMe.setImage(UIImage(systemName: "location.fill"), for: .normal)
        btnLocateMe.tintColor = .white
        btnLocateMe.backgroundColor = Color.App.accentUIColor
        btnLocateMe.layer.cornerRadius = 24
        btnLocateMe.addTarget(self, action: #selector(moveToUserLocation), for: .touchUpInside)
        view.addSubview(btnLocateMe)

        btnClose.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(systemName: "xmark")
        btnClose.imageView.contentMode = .scaleAspectFit
        btnClose.imageView.image = image
        btnClose.tintColor = Color.App.accentUIColor
        btnClose.layer.masksToBounds = true
        btnClose.layer.cornerRadius = 21
        btnClose.backgroundColor = Color.App.bgSendInputUIColor
        btnClose.accessibilityIdentifier = "btnCloseMapPickerViewController"

        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(closeTapped))
        btnClose.addGestureRecognizer(tapGesture)
        view.addSubview(btnClose)

        btnSubmit.translatesAutoresizingMaskIntoConstraints = false
        btnSubmit.accessibilityIdentifier = "btnSubmitMapPickerViewController"
        btnSubmit.action = { [weak self] in
            guard let self = self else { return }
            submitTapped()
            closeTapped(btnClose)
        }
        view.addSubview(btnSubmit)

        toastView.translatesAutoresizingMaskIntoConstraints = false
        toastView.accessibilityIdentifier = "toastViewMapPickerViewController"
        toastView.setIsHidden(true)
        view.addSubview(toastView)

        heightSubmitConstraint = btnSubmit.heightAnchor.constraint(greaterThanOrEqualToConstant: 64)
        NSLayoutConstraint.activate([
            toastView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            toastView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toastView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toastView.heightAnchor.constraint(equalToConstant: 96),
            btnClose.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            btnClose.widthAnchor.constraint(equalToConstant: 42),
            btnClose.heightAnchor.constraint(equalToConstant: 42),
            btnClose.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            btnSubmit.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            btnSubmit.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heightSubmitConstraint,
            btnSubmit.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            btnLocateMe.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            btnLocateMe.bottomAnchor.constraint(equalTo: btnSubmit.topAnchor, constant: -16),
            btnLocateMe.widthAnchor.constraint(equalToConstant: 48),
            btnLocateMe.heightAnchor.constraint(equalToConstant: 48),
            btnMapSwap.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            btnMapSwap.bottomAnchor.constraint(equalTo: btnLocateMe.topAnchor, constant: -16),
            btnMapSwap.widthAnchor.constraint(equalToConstant: 48),
            btnMapSwap.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func showOSM() {
        mapView.removeFromSuperview()
        showOSMMap = true
        view.addSubview(webView)
        view.sendSubviewToBack(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        // Load the local HTML file
        guard let filePath = Bundle.main.path(forResource: "map", ofType: "html") else { return }
        let fileURL = URL(fileURLWithPath: filePath)
        webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        webView.navigationDelegate = self
    }
    
    private func showAppleMaps() {
        webView.removeFromSuperview()
        showOSMMap = false
        
        view.addSubview(mapView)
        view.sendSubviewToBack(mapView)
        
        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let markerPath = Bundle.main.path(forResource: "location_pin", ofType: "png") {
            let fileURL = URL(fileURLWithPath: markerPath)
            let jsCode = "localMarkerPath = '\(fileURL.path())';"
            webView.evaluateJavaScript(jsCode, completionHandler: nil)
        }
        webView.evaluateJavaScript("initializeMap();", completionHandler: nil)
    }
    
    // Receive messages from JavaScript
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "locationHandler",
           let body = message.body as? [String: Any],
           let lat = body["latitude"] as? Double, let lng = body["longitude"] as? Double {
            self.locationManager.currentLocation = .init(name: String(localized: .init("Map.mayLocation"), bundle: Language.preferedBundle), description: String(localized: .init("Map.hereIAm"), bundle: Language.preferedBundle), location: CLLocationCoordinate2D(latitude: lat, longitude: lng))
        }
#if DEBUG
        if message.name == "consoleHandler", let log = message.body as? String {
            
            print("JavaScript Log: \(log)")
        }
#endif
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Add the annotation to the map
        annotation.coordinate = mapView.centerCoordinate
        mapView.addAnnotation(annotation)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let margin: CGFloat = view.safeAreaInsets.bottom > 0 ? 16 : 0
        heightSubmitConstraint.constant = 64 + margin
    }

    private func registerObservers() {
        locationManager.$error.sink { [weak self] error in
            if error != nil {
                self?.onError()
            }
        }
        .store(in: &cancellableSet)

        locationManager.$region.sink { [weak self] region in
            if let region = region, self?.canUpdate == true {
                self?.onRegionChanged(region)
            }
        }
        .store(in: &cancellableSet)
        
        locationManager.$userLocation.sink { [weak self] userLocation in
            if self?.showOSMMap == true, let location = userLocation?.location {
                /// A delay to load osm for the first time
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        self?.moveOSMTo(location: location)
                    }
                }
            }
        }
        .store(in: &cancellableSet)
        
        /// Wait 2 seconds to get an accurate user location
        /// Then we don't want to bog down the user with a rapid return to the user location
        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.canUpdate = false
            }
        }
    }

    private func submitTapped() {
        if let location = locationManager.currentLocation {
            viewModel?.attachmentsViewModel.append(attachments: [.init(type: .map, request: location)])
            /// Just update the UI to call registerModeChange inside that method it will detect the mode.
            viewModel?.sendContainerViewModel.setMode(type: .voice, attachmentsCount: 1)
        }
    }

    @objc private func closeTapped(_ sender: UIImageButton) {
        dismiss(animated: true)
    }
    
    private func onRegionChanged(_ region: MKCoordinateRegion) {
        mapView.setRegion(region, animated: true)
    }

    private func onError() {
        toastView.setIsHidden(false)
        Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            Task { @MainActor [weak self] in
                withAnimation {
                    self?.locationManager.error = nil
                    self?.toastView.setIsHidden(true)
                }
            }
        }
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let annotationView = mapView.view(for: annotation) {
            UIView.animate(withDuration: 0.2, animations: {
                annotationView.transform = CGAffineTransform(translationX: 0, y: -20) // Lift up
                    .scaledBy(x: 1.3, y: 1.3) // Scale up
            })
        }
    }
    
    @objc private func swapToAppleMaps() {
        if showOSMMap {
            showAppleMaps()
        } else {
            showOSM()
        }
    }
    
    @objc private func moveToUserLocation() {
        guard let location = locationManager.userLocation else { return }
        
        let region = MKCoordinateRegion(
            center: location.location,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        
        // Send location to JavaScript
        if showOSMMap {
            moveOSMTo(location: location.location)
        } else {
            mapView.setRegion(region, animated: true)
        }
    }
    
    private func moveOSMTo(location: CLLocationCoordinate2D) {
        let jsCode = "moveMapToLocation(\(location.latitude), \(location.longitude));"
        webView.evaluateJavaScript(jsCode, completionHandler: nil)
    }
}

final class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published var error: AppErrorTypes?
    @Published var currentLocation: LocationItem?
    @Published var userLocation: LocationItem?
    let manager = CLLocationManager()
    @Published var region: MKCoordinateRegion?

    override init() {
        super.init()
        region = .init(center: CLLocationCoordinate2D(latitude: 35.701002,
                                                      longitude: 51.377188),
                       span: MKCoordinateSpan(latitudeDelta: 0.005,
                                              longitudeDelta: 0.005))
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async { [weak self] in
            if let currentLocation = locations.first,
               MKMapPoint(currentLocation.coordinate).distance(to: MKMapPoint(self?.currentLocation?.location ?? CLLocationCoordinate2D())) > 100 {
                self?.userLocation = .init(name: String(localized: .init("Map.mayLocation"), bundle: Language.preferedBundle), description: String(localized: .init("Map.hereIAm"), bundle: Language.preferedBundle), location: currentLocation.coordinate)
                self?.currentLocation = self?.userLocation
                self?.region?.center = currentLocation.coordinate
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .denied {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                withAnimation {
                    self?.error = AppErrorTypes.location_access_denied
                }
            }
        }
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
    }
}

extension MapPickerViewController: MKMapViewDelegate {
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "CustomAnnotation"
        
        if annotation is MKUserLocation {
            return nil // Don't override user location annotation
        }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CustomAnnotationView
        
        if annotationView == nil {
            annotationView = CustomAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
    
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if let annotationView = mapView.view(for: annotation) {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.2, options: .curveEaseOut, animations: {
                annotationView.transform = .identity // Reset size & position (drop back)
            })
        }
    }
    
    public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let coordinate = mapView.centerCoordinate
        locationManager.currentLocation = .init(name: String(localized: .init("Map.mayLocation"), bundle: Language.preferedBundle), description: String(localized: .init("Map.hereIAm"), bundle: Language.preferedBundle), location: coordinate)
        annotation.coordinate = mapView.centerCoordinate
    }
}

class CustomAnnotationView: MKAnnotationView {
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        self.image = UIImage(named: "location_pin") // Replace with your custom pin image
        self.canShowCallout = false
        self.frame.size = CGSize(width: 40, height: 40) // Adjust size as needed
        self.centerOffset = CGPoint(x: 0, y: -20) // Adjust to align properly
    }
}

struct MapView_Previews: PreviewProvider {

    struct MapPickerViewWrapper: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> some UIViewController { MapPickerViewController() }
        func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    }

    static var previews: some View {
        MapPickerViewWrapper()
    }
}
