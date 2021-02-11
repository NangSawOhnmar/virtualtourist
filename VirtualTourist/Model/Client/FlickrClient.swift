//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by nang saw on 01/02/2021.
//

import Foundation

class FlickrClient {
    
    struct Constants {
        static let apiKey = "3382a088c8bd280c01eb52d5d4a8fbb9"
        static let secretKey = "5f667b161e92246f"
    }
    
    enum Endpoints {
        static let base = "https://api.flickr.com/services/rest/"
        static let photoSearch = "?method=flickr.photos.search"
        
        case searchPhoto
        
        var stringValue: String {
            switch self {
            case .searchPhoto:
                return Endpoints.base + Endpoints.photoSearch
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
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
//                do{
//                    let errorResponse = try decoder.decode(UdacityResponse.self, from: data)
//                    DispatchQueue.main.async {
//                        completion(nil,errorResponse)
//                    }
//                }catch{
                    DispatchQueue.main.async {
                        completion(nil,error)
                    }
//                }
            }
        }
        task.resume()
        return task
    }
}
