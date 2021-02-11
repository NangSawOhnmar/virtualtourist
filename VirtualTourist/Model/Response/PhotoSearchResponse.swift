//
//  PhotoSearchResponse.swift
//  VirtualTourist
//
//  Created by nang saw on 02/02/2021.
//

import Foundation

struct PhotoSearchResponse: Codable {
    let stat: String
    let data: Photos
    
    enum CodingKeys: String, CodingKey {
        case stat
        case data = "photos"
    }
}

struct Photos: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [FlickrImage]
}

struct FlickrImage: Codable {
    let id: String
    let title: String
    let imageUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case imageUrl = "url_m"
    }
}
