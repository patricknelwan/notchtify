import Foundation
import AppKit

class AlbumArtPrefetcher {
    private let imageCache = NSCache<NSString, NSImage>()
    private var prefetchTasks: [String: URLSessionDataTask] = [:]
    private var lastQueueCheck: Date = Date.distantPast
    
    init() {
        imageCache.countLimit = 50
        imageCache.totalCostLimit = 100 * 1024 * 1024
    }
    
    // Generate cache key from track and artist
    private func cacheKey(track: String, artist: String) -> String {
        return "\(track.lowercased())-\(artist.lowercased())"
    }
    
    // Check if we already have the image in memory
    func getCachedImage(track: String, artist: String) -> NSImage? {
        let key = cacheKey(track: track, artist: artist)
        return imageCache.object(forKey: key as NSString)
    }
    
    // Prefetch album art in background (doesn't block UI)
    func prefetchAlbumArt(track: String, artist: String, webAPIManager: SpotifyWebAPIManager) {
        let key = cacheKey(track: track, artist: artist)
        
        // Skip if already cached or currently fetching
        guard imageCache.object(forKey: key as NSString) == nil,
              prefetchTasks[key] == nil else {
            return
        }
        
        print("🔄 Prefetching album art for: \(track) - \(artist)")
        
        // Start prefetch in background
        let task = webAPIManager.fetchAlbumArtAsync(track: track, artist: artist) { [weak self] image in
            DispatchQueue.main.async {
                if let image = image {
                    // Store in memory cache
                    let cost = Int(image.size.width * image.size.height * 4) // Rough memory cost
                    self?.imageCache.setObject(image, forKey: key as NSString, cost: cost)
                    print("✅ Prefetched and cached: \(track) - \(artist)")
                }
                self?.prefetchTasks.removeValue(forKey: key)
            }
        }
        
        prefetchTasks[key] = task
    }
    
    // Get album art with instant cache check + fallback
    func getAlbumArt(track: String, artist: String, webAPIManager: SpotifyWebAPIManager, completion: @escaping (NSImage?) -> Void) {
        // 1. Check memory cache first (instant!)
        if let cachedImage = getCachedImage(track: track, artist: artist) {
            print("⚡ Instant cache hit: \(track) - \(artist)")
            completion(cachedImage)
            return
        }
        
        // 2. Not cached - fetch normally (but probably already prefetched)
        print("🌐 Cache miss - fetching: \(track) - \(artist)")
        webAPIManager.fetchAlbumArt(track: track, artist: artist) { [weak self] image in
            if let image = image {
                // Cache for future use
                let key = self?.cacheKey(track: track, artist: artist) ?? ""
                let cost = Int(image.size.width * image.size.height * 4)
                self?.imageCache.setObject(image, forKey: key as NSString, cost: cost)
            }
            completion(image)
        }
    }
}
