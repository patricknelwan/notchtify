import Foundation
import AppKit

class AlbumArtProvider {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    
    init() {
        // Create our own cache directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("NotchtifyAlbumArt")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // Generate cache key from track and artist
    private func cacheKey(track: String, artist: String) -> String {
        let cleanTrack = track.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanArtist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = "\(cleanTrack)-\(cleanArtist)".lowercased()
        return combined.data(using: .utf8)?.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-") ?? "unknown"
    }
    
    // Try to get cached album art from our cache
    func getCachedAlbumArt(track: String, artist: String) -> NSImage? {
        let key = cacheKey(track: track, artist: artist)
        let cachedImageURL = cacheDirectory.appendingPathComponent("\(key).png")
        
        if fileManager.fileExists(atPath: cachedImageURL.path) {
            if let image = NSImage(contentsOf: cachedImageURL) {
                print("🎨 Found cached album art for: \(track) - \(artist)")
                return image
            }
        }
        
        return nil
    }
    
    // Save album art to our cache
    private func cacheAlbumArt(_ image: NSImage, track: String, artist: String) {
        let key = cacheKey(track: track, artist: artist)
        let cachedImageURL = cacheDirectory.appendingPathComponent("\(key).png")
        
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return
        }
        
        try? pngData.write(to: cachedImageURL)
        print("💾 Cached album art for: \(track) - \(artist)")
    }
    
    // Main hybrid method
    func getAlbumArt(track: String, artist: String, webAPIManager: SpotifyWebAPIManager, completion: @escaping (NSImage?) -> Void) {
        // 1. Try our cache first (instant)
        if let cachedImage = getCachedAlbumArt(track: track, artist: artist) {
            completion(cachedImage)
            return
        }
        
        print("🌐 Cache miss - fetching from Web API: \(track) - \(artist)")
        
        // 2. Fetch from Web API and cache the result
        webAPIManager.fetchAlbumArt(track: track, artist: artist) { [weak self] image in
            if let image = image {
                // Cache the newly fetched image for next time
                self?.cacheAlbumArt(image, track: track, artist: artist)
            }
            completion(image)
        }
    }
}
