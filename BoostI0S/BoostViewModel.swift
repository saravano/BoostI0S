//
//  BoostViewModel.swift
//  BoostI0S
//
//  Created by Sara on 12/16/25.
//
//  UIKit-friendly view model; no longer relies on SwiftUI's ObservableObject

import UIKit
import Combine
import CoreLocation
import boostShared

class BoostViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var boostMessage = "Vibing with the ether..."
    @Published var savedCards: Set<String> = []
    @Published var isDataLoaded = false
    @Published var showConfig = false
    @Published var showPopup = true
    
    private var userDataManager = UserDataManager()
    private let locationService: LocationServiceType  = LocationService()
    private let apiService: ApiService = ApiService()
    private let utility: Utility = Utility()

    override init() {
        super.init()
        Task { await loadData() }
    }
    
    func initializeData(_ cards: Set<String>) {
        savedCards = cards
        showConfig = cards.isEmpty
    }
    
    func saveCardSelection(_ cardName: String, isSelected: Bool) {
        if isSelected {
            savedCards.insert(cardName)
        } else {
            savedCards.remove(cardName)
        }
        Task { await userDataManager.saveCardSelection(savedCards) }
    }
    
    func loadData() async {
        savedCards = await userDataManager.selectedCards
        isDataLoaded = true
        await MainActor.run { 
            self.initializeData(self.savedCards) 
        }
    }
    
    func determineCard() {
        Task { await self.handleDetermineCard() }
    }
    
    private func handleDetermineCard() async {
        do {
            let coord = try await refreshLocation()
            boostMessage = String(format: "Lat: %.6f, Lon: %.6f", coord.latitude, coord.longitude)
            
            // use coord
            let placeId = try await apiService.callGeocodeApiSuspend(lat: String(coord.latitude), lng: String(coord.longitude))
            boostMessage = "Place ID: \(placeId ?? "<unknown>")"
            
            // get place type
            let placeName = try await apiService.callPlacesApiSuspend(placeId: placeId)
            boostMessage = "Place Name: \(placeName ?? "<unknown>")"
            
            // parse place details in Swift
            let rawPlaceName = placeName ?? ""
            let parts = rawPlaceName.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            let name = parts.first ?? ""
            let placeType = parts.count > 1 ? parts[1] : ""

            // Prepare inputs for Perplexity call: join selected cards and use the parsed place name
            let cardsString = savedCards.joined(separator: ",")
            let answerCard = try await apiService.callPerplexityLocation(cards: cardsString, placeName: name)
            let innerMessage = utility.cleanupString(str: answerCard, name: name, placeType: placeType)
            boostMessage = innerMessage
            
        } catch {
            // handle error (e.g., notify UI)
            print("Failed to determine card: \(error)")
        }
    }

    func refreshLocation() async throws -> CLLocationCoordinate2D {
        return try await withCheckedThrowingContinuation { continuation in
            locationService.requestCurrentLocation { result in
                switch result {
                case .success(let coord):
                    self.boostMessage = String(format: "Lat: %.6f, Lon: %.6f", coord.latitude, coord.longitude)
                    continuation.resume(returning: coord)
                case .failure(let error):
                    print("Location error: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

