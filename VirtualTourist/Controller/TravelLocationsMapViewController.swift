//
//  ViewController.swift
//  VirtualTourist
//
//  Created by nang saw on 01/02/2021.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    var selectedPin: Pin?
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    fileprivate func loadMapAnnotations() {
        if let pins = fetchedResultsController.fetchedObjects {
            mapView.addAnnotations(pins)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
        loadMapAnnotations()
        
        // Add LongTapGesture
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(sender:)))
        mapView.delegate = self
        mapView.addGestureRecognizer(longPressRecognizer)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        loadMapAnnotations()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    func setupMapView() {
        view.backgroundColor = UIColor.black
        navigationController?.navigationBar.barStyle = .black
        
        let mapRadius = CLLocationDistance(exactly: MKMapRect.world.size.height)!
        mapView.addOverlay(MKCircle(center: mapView.centerCoordinate, radius: mapRadius))
    }
    
    // add pin by holding on a location on map
    @objc func longPressed(sender: UILongPressGestureRecognizer) {
        if sender.state != .began {
            return
        }
        
        let touchPoint = sender.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        addPin(longitude: newCoordinates.longitude, latitude: newCoordinates.latitude)
    }
    
    // Adds a new pin to the end of the `pins` array
    func addPin(longitude: Double, latitude: Double) {
        let pin = Pin(context: dataController.viewContext)
        pin.longitude = longitude
        pin.latitude = latitude
        pin.creationDate = Date()
        try? dataController.viewContext.save()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PhotoAlbumViewController {
            vc.pin = selectedPin
            vc.dataController = dataController
        }
    }
}

extension TravelLocationsMapViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let pin = anObject as? Pin else {
            preconditionFailure("NOT A PIN!")
        }
        switch type {
        case .insert:
            mapView.addAnnotation(pin)
            break
        default: ()
        }
    }
}

extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay.isKind(of: MKCircle.self) {
            let view = MKCircleRenderer(overlay: overlay)
            view.fillColor = UIColor.black.withAlphaComponent(0.2)
            return view
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // TODO: by pressing on a pin go to photosListViewController
        mapView.deselectAnnotation(view.annotation! , animated: true)
        self.selectedPin = view.annotation as? Pin
        performSegue(withIdentifier: "PhotoAlbum", sender: self)
    }
}
