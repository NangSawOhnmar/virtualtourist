//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by nang saw on 01/02/2021.
//

import UIKit

class FlickrClient {
    
    struct Constants {
        static let apiKey = "3382a088c8bd280c01eb52d5d4a8fbb9"
        static let secretKey = "5f667b161e92246f"
        static let NUM_OF_PHOTOS = 20
        static let TOTAL_PAGE = (1...10).randomElement() ?? 1
        
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest/"
        static let Method = "flickr.photos.search"
        static let Format = "json"
        static let Extras = "url_m"
    }
    
    class func getPhotos(parameters: [String: AnyObject], completion: @escaping ([FlickrImage], Error?) -> Void) -> Void {
        let request = flickrURLFromParameters(parameters, withPathExtension: "")
        let _ = taskForGETRequest(url: request, response: PhotoSearchResponse.self) { response, error in
            if let response = response {
                completion(response.data.photo, nil)
            } else {
                completion([], error)
            }
        }
    }
    
    class func requestImageFile(url: URL, completionHandler: @escaping(Data?, Error?) -> Void){
        let downloadTask = URLSession.shared.dataTask(with: url, completionHandler: { (data,response,error) in
            guard let data = data else {
                completionHandler(nil,error)
                return
            }
            completionHandler(data,nil)
        })
        downloadTask.resume()
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, response: ResponseType.Type, completion: @escaping(ResponseType?,Error?) -> Void) -> URLSessionTask{
        let task = URLSession.shared.dataTask(with: url) { data,response,error in
            guard let data = data else{
                DispatchQueue.main.async {
                    completion(nil,error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject,nil)
                }
            }catch{
                do{
                    let errorResponse = try decoder.decode(FlickrErrorResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil,errorResponse)
                    }
                }catch{
                    DispatchQueue.main.async {
                        completion(nil,error)
                    }
                }
            }
        }
        task.resume()
        return task
    }
    
    class func flickrURLFromParameters(_ parameters: [String: AnyObject], withPathExtension: String? = nil) -> URL {
        var components = URLComponents()
        components.scheme = Constants.ApiScheme
        components.host = Constants.ApiHost
        components.path = Constants.ApiPath + (withPathExtension ?? "")
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}
