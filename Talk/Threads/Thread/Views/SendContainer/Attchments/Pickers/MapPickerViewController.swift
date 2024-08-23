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

public final class MapPickerViewController: UIViewController {
    // Views
    private let mapView = MKMapView()
    private let btnClose = UIImageButton(imagePadding: .init(all: 4))
    private let btnSubmit = SubmitBottomButtonUIView(text: "General.add")
    private let toastView = ToastUIView(message: AppErrorTypes.location_access_denied.localized, disableWidthConstraint: true)

    // Models
    private var cancelablleSet = Set<AnyCancellable>()
    private var locationManager: LocationManager = .init()
    public var viewModel: ThreadViewModel?

    // Constarints
    private var heightSubmitConstraint: NSLayoutConstraint!

    public override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
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
        view.addSubview(mapView)

        btnClose.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(systemName: "xmark")
        btnClose.imageView.contentMode = .scaleAspectFit
        btnClose.imageView.image = image
        btnClose.tintColor = Color.App.accentUIColor
        btnClose.layer.masksToBounds = true
        btnClose.layer.cornerRadius = 14
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
            btnClose.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            btnClose.widthAnchor.constraint(equalToConstant: 28),
            btnClose.heightAnchor.constraint(equalToConstant: 28),
            btnClose.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            btnSubmit.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            btnSubmit.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heightSubmitConstraint,
            btnSubmit.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
        ])
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
        .store(in: &cancelablleSet)

        locationManager.$region.sink { [weak self] region in
            if let region = region {
                self?.onRegionChanged(region)
            }
        }
        .store(in: &cancelablleSet)
    }

    private func submitTapped() {
        if let location = locationManager.currentLocation {
            viewModel?.attachmentsViewModel.append(attachments: [.init(type: .map, request: location)])
            viewModel?.delegate?.onItemsPicked()
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
            withAnimation {
                self.locationManager.error = nil
                self.toastView.setIsHidden(true)
            }
        }
    }
}

final class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    @Published var error: AppErrorTypes?
    @Published var currentLocation: LocationItem?
    let manager = CLLocationManager()
    @Published var region: MKCoordinateRegion?

    override init() {
        super.init()
        region = .init(center: CLLocationCoordinate2D(latitude: 51.507222,
                                                      longitude: -0.1275),
                       span: MKCoordinateSpan(latitudeDelta: 0.005,
                                              longitudeDelta: 0.005))
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.requestAlwaysAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        DispatchQueue.main.async { [weak self] in
            if let currentLocation = locations.first, MKMapPoint(currentLocation.coordinate).distance(to: MKMapPoint(self?.currentLocation?.location ?? CLLocationCoordinate2D())) > 100 {
                self?.currentLocation = .init(name: String(localized: .init("Map.mayLocation"), bundle: Language.preferedBundle), description: String(localized: .init("Map.hereIAm"), bundle: Language.preferedBundle), location: currentLocation.coordinate)
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
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Get the center coordinate of the map's visible region
        let centerCoordinate = mapView.centerCoordinate

        // Remove any existing annotation from the map
        mapView.removeAnnotations(mapView.annotations)

        // Create a new annotation at the center coordinate
        let annotation = MKPointAnnotation()
        annotation.coordinate = centerCoordinate

        // Add the annotation to the map
        mapView.addAnnotation(annotation)
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
