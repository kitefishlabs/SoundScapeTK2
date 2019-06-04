//
//  APIResources.swift
//  SoundScapeTK2
//
//  Created by kfl on 5/29/19.
//  Copyright © 2019 kfl. All rights reserved.
//

import Foundation

protocol ApiResource {
    var methodPath: String { get }
}

extension ApiResource {
    var url: URL {
        let baseURL = "https://my-json-server.typicode.com"
        let githubUser = "/kitefishlabs"
        let githubRepo = "/json-test-data"
        let url = baseURL + githubUser + githubRepo + methodPath
        return URL(string: url)!
    }
}

struct RegionsResource: ApiResource {
    let methodPath = "/regions"
}

struct SoundScapeResource: ApiResource {
    let methodPath = "/db"
}
