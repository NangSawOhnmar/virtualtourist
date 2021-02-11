//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by nang saw on 01/02/2021.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var newCollectionBtn: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    // Injected by default
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var pin: Pin!
    let insets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    let itemsPerRow: CGFloat = 3
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(pin!.creationDate!)-photos")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        collectionView.dataSource = self
        collectionView.delegate = self
        
        setupFetchedResultsController()
        setNewCollectionButtonEnable(isEnable: false)
        
        if (fetchedResultsController.sections?[0].numberOfObjects == 0) {
            self.getFlickrPhoto()
        }else {
            setNewCollectionButtonEnable(isEnable: true)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    private func setupMapView() {
        mapView.addAnnotation(pin)
        mapView.delegate = self
        mapView.isUserInteractionEnabled = false
        mapView.isZoomEnabled = true
        mapView.centerCoordinate = pin.coordinate
    }
    
    private func setNewCollectionButtonEnable(isEnable: Bool) {
        newCollectionBtn.isEnabled = isEnable
    }
    
    private func getFlickrPhoto() {
        activityIndicatorView.startAnimating()
        let parameters = [PhotoSearchRequest.api_key: FlickrClient.Constants.apiKey, PhotoSearchRequest.method: FlickrClient.Constants.Method, PhotoSearchRequest.format: FlickrClient.Constants.Format, PhotoSearchRequest.nojsoncallback: 1, PhotoSearchRequest.extras: FlickrClient.Constants.Extras, PhotoSearchRequest.latitude: pin.latitude, PhotoSearchRequest.longitude: pin.longitude, PhotoSearchRequest.radius: 20, PhotoSearchRequest.per_page: 20, PhotoSearchRequest.page: FlickrClient.Constants.TOTAL_PAGE] as [String : AnyObject]
        FlickrClient.getPhotos(parameters: parameters, completion: { (flickrImages,error) in
            if error != nil {
                self.showFailureAlert(message: error?.localizedDescription ?? "", title: "Something went wrong!")
            }
            for image in flickrImages {
                self.addPhoto(url: image.imageUrl)
            }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.setNewCollectionButtonEnable(isEnable: true)
                self.activityIndicatorView.stopAnimating()
            }
        })
    }
    
    func addPhoto(url: String) {
        let photo = Photo(context: dataController.viewContext)
        photo.creationDate = Date()
        photo.url = url
        photo.pin = pin
        try? dataController.viewContext.save()
    }
    
    func deletePhoto(_ photo: Photo) {
        dataController.viewContext.delete(photo)
        try? dataController.viewContext.save()
    }
    
    @IBAction func tappedNewCollectionButton(_ sender: Any) {
        if let photos = fetchedResultsController.fetchedObjects {
            for photo in photos {
                dataController.viewContext.delete(photo)
                do {
                    try dataController.viewContext.save()
                } catch {
                    print("Error saving")
                }
            }
        }
        getFlickrPhoto()
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let numOfObjects = self.fetchedResultsController.sections?[section].numberOfObjects
        if numOfObjects != 0  {
            collectionView.deleteEmptyMessage()
            return numOfObjects ?? 0
        }else {
            collectionView.setEmptyMessage("No Images")
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController.object(at: indexPath)
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? FlickrPhotoCollectionViewCell {
            
            if let photoData = photo.data {
                cell.imageView.image = UIImage(data: photoData)
            } else if let photoUrl = photo.url {
                guard let url = URL(string: photoUrl) else {
                    return cell
                }
                FlickrClient.requestImageFile(url: url, completionHandler: { (data,error) in
                    guard let imagedata = data else { return }
                    let downloadedImage = UIImage(data: imagedata)
                    photo.data = imagedata
                    try? self.dataController.viewContext.save()
                    DispatchQueue.main.async {
                        cell.imageView.image = downloadedImage
                    }
                })
            }
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        deletePhoto(photoToDelete)
    }
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
//        case .insert:
//            collectionView.insertItems(at: [newIndexPath!])
//            break
        case .delete:
            collectionView.deleteItems(at: [indexPath!])
            break
        default: ()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding = insets.right * (itemsPerRow + 1)
        let availableWidth = view.frame.width / itemsPerRow
        let widthOfItem = availableWidth - padding
        
        return CGSize(width: widthOfItem, height: (view.frame.width / 3) - 12)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return insets
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return insets.right
    }
}


extension UICollectionView {
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textAlignment = .center;
        messageLabel.sizeToFit()
        print("set empty")
        self.backgroundView = messageLabel;
    }
    
    func deleteEmptyMessage() {
        self.backgroundView = nil
    }
}

// MARK: MKMapViewDelegate
extension PhotoAlbumViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay.isKind(of: MKCircle.self) {
            let view = MKCircleRenderer(overlay: overlay)
            view.fillColor = UIColor.black.withAlphaComponent(0.2)
            return view
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}

// To show error alert
extension UIViewController {
    func showFailureAlert(message: String, title: String) {
        let alertVC = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertVC, animated: true, completion: nil)
    }
}
