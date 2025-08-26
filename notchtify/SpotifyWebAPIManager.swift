import Foundation
import SwiftUI

class SpotifyWebAPIManager: ObservableObject {
    private let clientId = "ec991827686849cfa4298655a341a7a5"
    private let clientSecret = "4432b3b584cd4fb2af80ec7daa16bce9"
    private var accessToken: String?
    
    init() {
        getClientCredentialsToken()
    }
    
    private func getClientCredentialsToken() {
        let url = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let credentials = "\(clientId):\(clientSecret)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        
        let body = "grant_type=client_credentials"
        request.httpBody = body.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Token request error: \(error?.localizedDescription ?? "Unknown")")
                return
            }
            
            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                DispatchQueue.main.async {
                    self.accessToken = tokenResponse.access_token
                    print("✅ Spotify Web API token obtained")
                }
            } catch {
                print("Token decode error: \(error)")
            }
        }.resume()
    }
    
    func fetchAlbumArt(track: String, artist: String, completion: @escaping (NSImage?) -> Void) {
        guard let token = accessToken else {
            completion(nil)
            return
        }
        
        let query = "\(track) artist:\(artist)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://api.spotify.com/v1/search?q=\(query)&type=track&limit=1"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Search request error: \(error?.localizedDescription ?? "Unknown")")
                completion(nil)
                return
            }
            
            do {
                let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
                if let firstTrack = searchResponse.tracks.items.first,
                   let albumArt = firstTrack.album.images.first,
                   let imageUrl = URL(string: albumArt.url) {
                    
                    URLSession.shared.dataTask(with: imageUrl) { imageData, _, _ in
                        guard let imageData = imageData,
                              let image = NSImage(data: imageData) else {
                            completion(nil)
                            return
                        }
                        
                        DispatchQueue.main.async {
                            completion(image)
                        }
                    }.resume()
                } else {
                    completion(nil)
                }
            } catch {
                print("Search decode error: \(error)")
                completion(nil)
            }
        }.resume()
    }
}

struct TokenResponse: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
}

struct SearchResponse: Codable {
    let tracks: TrackSearchResult
}

struct TrackSearchResult: Codable {
    let items: [SpotifyTrack]
}

struct SpotifyTrack: Codable {
    let album: SpotifyAlbum
}

struct SpotifyAlbum: Codable {
    let images: [SpotifyImage]
}

struct SpotifyImage: Codable {
    let url: String
    let height: Int?
    let width: Int?
}
