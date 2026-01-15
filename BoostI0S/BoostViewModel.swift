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

@MainActor
class BoostViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var boostMessage = "Vibing with the ether..."
    @Published var boostDetail: String = ""
    @Published var savedCards: Set<String> = []
    @Published var isDataLoaded = false
    @Published var showConfig = false
    @Published var showPopup = true
    
    public var userDataManager = UserDataManager()
    private let locationService: LocationServiceType  = LocationService()
    private let apiService: ApiService = ApiService()
    private let utility: Utility = Utility()

    override init() {
        super.init()
    }
    
    func initializeData(_ cards: Set<String>) {	
        savedCards = cards
        showConfig = cards.isEmpty
    }
    
    func saveCardSelection(cards: Set<String>) {
        savedCards = cards
        isDataLoaded = true
        showConfig = false
        Task { await userDataManager.saveCardSelection(cards) }
    }

    @MainActor
    func loadData() async  {
        savedCards = await userDataManager.selectedCards
        isDataLoaded = true
        showConfig = savedCards.isEmpty
    }
    
    @MainActor
    func nextStep() -> Bool{
        if (boostMessage != boostDetail) {
            print("Updating boostMessage with {\(boostDetail)}")
            boostMessage = boostDetail
            return true
        }
        else {
            return false
        }
    }
    
    @MainActor
    func determineCard() {
        Task { await self.handleDetermineCard() }
    }
    
    private func handleDetermineCard() async {
        do {
            let coord = try await refreshLocation()
  
            // use coord
            let placeId = try await apiService.callGeocodeApiSuspend(lat: String(coord.latitude), lng: String(coord.longitude))
              
            // get place type
            let placeName = try await apiService.callPlacesApiSuspend(placeId: placeId)
            
            // parse place details in Swift
            let rawPlaceName = placeName ?? ""
            let parts = rawPlaceName.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            let name = parts.first ?? ""
            let placeType = parts.count > 1 ? parts[1] : ""

            // Prepare inputs for Perplexity call: join selected cards and use the parsed place name
            let cardsString = savedCards.joined(separator: ",")
            let answerCard = try await apiService.callPerplexityLocation(cards: cardsString, placeName: name, placeType: placeType)
            let innerMessage = utility.cleanupString(str: answerCard, name: name, placeType: placeType)
            let answerParts = innerMessage.split(separator: "::", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            boostMessage = answerParts.first ?? ""
            boostDetail = answerParts.count > 1 ? answerParts[1] : ""
            print("Determined card: \(boostMessage)")
            print("Answer parts: \(answerParts.count)")
            print("Detail: \(boostDetail)")
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
                    continuation.resume(returning: coord)
                case .failure(let error):
                    print("Location error: \(error)")
                    continuation.resume(throwing: error)
                }
            }
            
        }
    }
    
    func updateBoostMessage(_ message: String) {
        boostMessage = message
    }
}

