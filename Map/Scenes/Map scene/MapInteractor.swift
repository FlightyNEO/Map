//
//  MapInteractor.swift
//  Map
//
//  Created by Arkadiy Grigoryanc on 17.12.2019.
//

import CoreLocation
import UIKit

// MARK: MapBusinessLogic protocol
protocol MapBusinessLogic
{
	func getSmartTargets(_ request: Map.FetchSmartTargets.Request)
	func getSmartTarget(_ request: Map.GetSmartTarget.Request)
	func configureLocationService(request: Map.UpdateStatus.Request)
	func returnToCurrentLocation(request: Map.UpdateStatus.Request)
	func getAddress(_ request: Map.Address.Request)

	// Adding, updating, removing smart targets
	func addSmartTarget(_ request: Map.AddSmartTarget.Request)
	func updateSmartTarget(_ request: Map.UpdateSmartTarget.Request)
	func removeSmartTarget(_ request: Map.RemoveSmartTarget.Request)

	func updateSmartTargets(_ request: Map.UpdateSmartTargets.Request)

	// Notifications
	func setNotificationServiceDelegate(_ request: Map.SetNotificationServiceDelegate.Request)

	// Monitoring Region
	func startMonitoringRegion(_ request: Map.StartMonitoringRegion.Request)
	func stopMonitoringRegion(_ request: Map.StopMonitoringRegion.Request)

	// Settings
	func getCurrentRadius(_ request: Map.GetCurrentRadius.Request)
	func getRangeRadius(_ request: Map.GetRangeRadius.Request)
	func getMeasuringSystem(_ request: Map.GetMeasuringSystem.Request)
	func getRemovePinAlertSettings(_ request: Map.GetRemovePinAlertSettings.Request)
}

// MARK: - MapDataStore protocol
protocol MapDataStore
{
	var temptSmartTarget: SmartTarget? { get set }

	var temptSmartTargetCollection: ISmartTargetCollection? { get set }
	var smartTargetCollection: ISmartTargetCollection? { get set }
}

// MARK: Class
final class MapInteractor<T: ISmartTargetRepository, G: IDecoderGeocoder>: NSObject, CLLocationManagerDelegate
	where T.Element: ISmartTargetCollection
{
	// MARK: ...Private properties
	private var presenter: MapPresentationLogic
	private var dataBaseWorker: DataBaseWorker<T>
	private var geocoderWorker: GeocoderWorker<G>
	private var settingsWorker: SettingsWorker
	private var notificationWorker: NotificationWorker
	private lazy var locationManager: CLLocationManager = {
		let locationManager = CLLocationManager()
		locationManager.delegate = self
		locationManager.allowsBackgroundLocationUpdates = true
		locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
		return locationManager
	}()

	private var currentCoordinate: CLLocationCoordinate2D?

	var temptSmartTargetCollection: ISmartTargetCollection?
	var smartTargetCollection: ISmartTargetCollection?

	private var pendingRequesrWorkItem: DispatchWorkItem?
	private let dispatchQueueGetAddress =
		DispatchQueue(label: "com.map.getAddress",
					  qos: .userInitiated,
					  attributes: .concurrent)

	private let dispatchQueueSaveSmartTargets =
		DispatchQueue(label: "com.map.saveSmartTargets",
					  qos: .userInitiated,
					  attributes: .concurrent)

	private var userValues: (lower: Double, upper: Double) {
		(lower: settingsWorker.lowerValueOfRadius ?? 0,
		 upper: settingsWorker.upperValueOfRadius ?? 0)
	}

	// MARK: ...Map data store
	var temptSmartTarget: SmartTarget?

	// MARK: ...Initialization
	init(presenter: MapPresentationLogic,
		 dataBaseWorker: DataBaseWorker<T>,
		 geocoderWorker: GeocoderWorker<G>,
		 settingsWorker: SettingsWorker,
		 notificationWorker: NotificationWorker) {
		self.presenter = presenter
		self.dataBaseWorker = dataBaseWorker
		self.geocoderWorker = geocoderWorker
		self.settingsWorker = settingsWorker
		self.notificationWorker = notificationWorker
	}

	// MARK: ...Private methods
	private func checkAuthorizationService() {
		switch CLLocationManager.authorizationStatus() {
		case .notDetermined:
			locationManager.requestAlwaysAuthorization()
		case .authorizedAlways, .authorizedWhenInUse:
			authorizationLocationResponse(true, coordinate: nil)
		case .restricted, .denied:
			authorizationLocationResponse(false, coordinate: nil)
		@unknown default:
			fatalError("Unknown case")
		}
	}

	private func authorizationLocationResponse(_ isApproved: Bool, coordinate: CLLocationCoordinate2D?) {
		let response = Map.UpdateStatus.Response(accessToLocationApproved: isApproved,
												 userCoordinate: coordinate)
		presenter.beginLocationUpdates(response: response)
	}

	private func saveSmartTargetCollection(_ completion: @escaping (Bool) -> Void) {
		dispatchQueueSaveSmartTargets.async { [weak self] in
			guard let smartTargetCollection = self?.smartTargetCollection as? T.Element else { return }
			self?.dataBaseWorker.saveSmartTargets(smartTargetCollection) { result in
				let isSaved: Bool
				if case .success = result {
					isSaved = true
				}
				else {
					isSaved = false
				}
				completion(isSaved)
			}
		}
	}

	private func updateTemptSmartTargetCollection() {
		if temptSmartTargetCollection == nil {
			temptSmartTargetCollection = smartTargetCollection?.copy()
		}
	}

	private func performGetAddress(after: TimeInterval, _ block: @escaping () -> Void) {
		pendingRequesrWorkItem?.cancel()

		let requestWorkItem = DispatchWorkItem(block: block)

		pendingRequesrWorkItem = requestWorkItem

		dispatchQueueGetAddress.asyncAfter(deadline: .now() + after, execute: requestWorkItem)
	}

	// MARK: ...CLLocationDelegate
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		switch status {
		case .notDetermined, .restricted, .denied:
			authorizationLocationResponse(false, coordinate: nil)
		case .authorizedAlways, .authorizedWhenInUse:
			authorizationLocationResponse(true, coordinate: locationManager.location?.coordinate)
		@unknown default:
			fatalError("Unknown case")
		}
	}

	func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
		notificationWorker.requestNotificationAuthorized { _ in }
		let response = Map.StartMonitoringRegion.Response(isStarted: true)
		presenter.presentStartMonitoringRegion(response)
	}

	func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
		guard var smartTarget = smartTargetCollection?[region.identifier] else { return }
		smartTarget.entryDate = Date()
		smartTargetCollection?.put(smartTarget)
		saveSmartTargetCollection { _ in }
		notificationWorker.addNotifications(for: [smartTarget])
	}

	func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
		guard var smartTarget = smartTargetCollection?[region.identifier] else { return }
		smartTarget.exitDate = Date()
		smartTargetCollection?.put(smartTarget)
		saveSmartTargetCollection { _ in }
		notificationWorker.addNotifications(for: [smartTarget])
	}

	func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
		let response = Map.StartMonitoringRegion.Response(isStarted: false)
		presenter.presentStartMonitoringRegion(response)
	}
}

// MARK: - Map display logic
extension MapInteractor: MapBusinessLogic
{

	func getSmartTarget(_ request: Map.GetSmartTarget.Request) {
		guard let smartTarget = smartTargetCollection?[request.uid] else { return }
		let response = Map.GetSmartTarget.Response(smartTarget: smartTarget)
		presenter.presentSmartTarget(response)
	}

	func getSmartTargets(_ request: Map.FetchSmartTargets.Request) {
		dataBaseWorker.fetchSmartTargets { [weak self] result in
			switch result {
			case .success(let collection):
				self?.temptSmartTargetCollection = collection.copy()
				self?.smartTargetCollection = collection
			case .failure(let error):
				switch error {
				case .fileNotExists:
					self?.smartTargetCollection = SmartTargetCollection()
					self?.temptSmartTargetCollection = self?.smartTargetCollection?.copy()
				default:
					print(error)
				}
			}
			guard let collection = self?.smartTargetCollection else { return }
			let response = Map.FetchSmartTargets.Response(smartTargetCollection: collection)
			self?.presenter.presentSmartTargets(response)
		}
	}

	func configureLocationService(request: Map.UpdateStatus.Request) {
		checkAuthorizationService()
	}

	func returnToCurrentLocation(request: Map.UpdateStatus.Request) {
		checkAuthorizationService()
	}

	func getAddress(_ request: Map.Address.Request) {
		performGetAddress(after: 0.35) { [weak self] in
			self?.geocoderWorker.getGeocoderMetaData(by: request.coordinate.geocode) { result in
				let response = Map.Address.Response(result: result,
													coordinate: request.coordinate)
				self?.presenter.presentAddress(response)
			}
		}
	}

	func addSmartTarget(_ request: Map.AddSmartTarget.Request) {
		updateTemptSmartTargetCollection()
		smartTargetCollection?.put(request.smartTarget)
		saveSmartTargetCollection { [weak self] isSaved in
			let response = Map.AddSmartTarget.Response(isAdded: isSaved)
			self?.presenter.presentAddSmartTarget(response)
		}
	}

	func removeSmartTarget(_ request: Map.RemoveSmartTarget.Request) {
		updateTemptSmartTargetCollection()
		smartTargetCollection?.remove(atUID: request.uid)
		saveSmartTargetCollection { [weak self] isSaved in
			let response = Map.RemoveSmartTarget.Response(isRemoved: isSaved)
			self?.presenter.presentRemoveSmartTarget(response)
		}
	}

	func updateSmartTarget(_ request: Map.UpdateSmartTarget.Request) {
		updateTemptSmartTargetCollection()
		smartTargetCollection?.put(request.smartTarget)
		saveSmartTargetCollection { [weak self] isSaved in
			let response = Map.UpdateSmartTarget.Response(isUpdated: isSaved)
			self?.presenter.presentUpdateSmartTarget(response)
		}
	}

	func setNotificationServiceDelegate(_ request: Map.SetNotificationServiceDelegate.Request) {
		notificationWorker.setDelegate(request.notificationDelegate)
		let response = Map.SetNotificationServiceDelegate.Response(isSet: true)
		presenter.presentSetNotificationServiceDelegate(response)
	}

	func startMonitoringRegion(_ request: Map.StartMonitoringRegion.Request) {
		locationManager.startMonitoring(for: request.smartTarget.region)
	}

	func stopMonitoringRegion(_ request: Map.StopMonitoringRegion.Request) {
		var isStoped = true
		defer {
			let response = Map.StopMonitoringRegion.Response(isStoped: isStoped)
			presenter.presentStopMonitoringRegion(response)
		}
		guard let region = locationManager.monitoredRegions.first(where: { $0.identifier == request.uid }) else {
			isStoped = false
			return
		}
		locationManager.stopMonitoring(for: region)
		notificationWorker.removeNotification(at: request.uid)
	}

	func updateSmartTargets(_ request: Map.UpdateSmartTargets.Request) {
		guard
			let oldCollection = temptSmartTargetCollection?.copy(),
			let smartTargetCollection = smartTargetCollection else { return }

		let differences = smartTargetCollection.smartTargetsOfDifference(from: oldCollection)
		let response = Map.UpdateSmartTargets.Response(collection: oldCollection,
													   addedSmartTargets: differences.added,
													   removedSmartTargets: differences.removed,
													   updatedSmartTargets: differences.updated)
		presenter.presentUpdateSmartTargets(response)
	}

	func getCurrentRadius(_ request: Map.GetCurrentRadius.Request) {
		let response = Map.GetCurrentRadius.Response(currentRadius: request.currentRadius,
													 userValues: userValues)
		presenter.presentGetCurrentRadius(response)
	}

	func getRangeRadius(_ request: Map.GetRangeRadius.Request) {
		let response = Map.GetRangeRadius.Response(userValues: userValues)
		presenter.presentGetRangeRadius(response)
	}

	func getMeasuringSystem(_ request: Map.GetMeasuringSystem.Request) {
		let measuringSystem = settingsWorker.measuringSystem ?? .kilometer
		let response = Map.GetMeasuringSystem.Response(measuringSystem: measuringSystem)
		presenter.presentGetMeasuringSystem(response)
	}

	func getRemovePinAlertSettings(_ request: Map.GetRemovePinAlertSettings.Request) {
		let alertOn = settingsWorker.forceRemovePin ?? true
		let response = Map.GetRemovePinAlertSettings.Response(removePinAlertOn: alertOn)
		presenter.presentGetRemovePinAlertSettings(response)
	}
}

// MARK: - Map data source
extension MapInteractor: MapDataStore { }
