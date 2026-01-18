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
    
    @Published var boostMessage = "Determining location..."
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
    
    func saveCardSelection(cards: Set<String>) -> Bool {
        savedCards = cards
        if (savedCards.isEmpty) {
            showConfig = true
            return false
        }
        
        isDataLoaded = true
        showConfig = false
        Task { await userDataManager.saveCardSelection(cards) }
        return true
    }

    @MainActor
    func loadData() async  {
        savedCards = await userDataManager.selectedCards
        isDataLoaded = true
        showConfig = savedCards.isEmpty
    }
    
    @MainActor
    func nextStep() -> Bool{
        if (boostMessage != boostDetail && !boostDetail.isEmpty) {
            print("Updating boostMessage with {\(boostDetail)}")
            boostMessage = boostDetail
            return true
        }
        else {
            return false
        }
    }
    
    func handleResult(_ result: KotlinPair<NSString, KotlinBoolean>) -> Bool {
        guard let message = result.first as String?,
              let success = result.second else {
            return false
        }
        
        if (!success.boolValue) {
            let pair = utility.splitDetails(message: String(message))
            guard let message = pair.first as String?,
                  let detail = pair.second as String? else {
                    return false
                }
            let tmpDetail = extractLocalizedMessage(from: detail)
            
            boostMessage = message
            boostDetail = tmpDetail ?? detail
            return false
        }
        return true
    }
    
    @MainActor
    func determineCard() {
        Task { await self.handleDetermineCard() }
    }
    
    private func handleDetermineCard() async {
        do {
            let coord = try await refreshLocation()
            print("COORD: " + coord.latitude.description + "," + coord.longitude.description)

            // use coord
            let placeIdResult = try await apiService.callGeocodeApiSuspend(lat: String(coord.latitude), lng: String(coord.longitude))
            if (handleResult(placeIdResult)) {

                // get place type
                let placeId = placeIdResult.first as String?
                print(placeId ?? "")
                let placeResult = try await apiService.callPlacesApiSuspend(placeId: placeId)
                if (handleResult(placeResult)) {
                    
                    // parse place details in Swift
                    let rawPlaceName = placeResult.first as String? ?? ""
                    let parts = rawPlaceName.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                    let name = parts.first ?? ""
                    let placeType = parts.count > 1 ? parts[1] : ""
                    print(placeType)
                    
                    // Prepare inputs for Perplexity call: join selected cards and use the parsed place name
                    let cardsString = savedCards.joined(separator: ",")
                    print (cardsString + " cards")
                    boostMessage = "Researching card benefits..."
                    let aiResult = try await apiService.callPerplexityLocation(cards: cardsString, placeName: name, placeType: placeType)
                    if (handleResult(aiResult)  ) {
                        let aiCard = aiResult.first as String? ?? ""
                        let innerMessage = utility.cleanupString(str: aiCard, name: name, placeType: placeType)
                        let answerParts = innerMessage.split(separator: "::", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                        boostMessage = answerParts.first ?? ""
                        boostDetail = answerParts.count > 1 ? answerParts[1] : ""
                        
                        print("Determined card: \(boostMessage)")
                        print("Answer parts: \(answerParts.count)")
                        print("Detail: \(boostDetail)")
                    }
                }
            }
        } catch {
            boostMessage = "Failed to get location"
            boostDetail = "Please enable location services in settings and allow Boost to access your location."
        }
        print("BoostMessage: \(boostMessage)")
        print ("BoostDetail: \(boostDetail)")
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
    
    func extractLocalizedMessage(from detail: String) -> String? {
        guard let startRange = detail.range(of: "NSLocalizedDescription=") else { return nil }
        let afterStart = detail[startRange.upperBound...]
        
        let periodRange = afterStart.range(of: ".")
        let messageEnd: Substring.Index
        if let periodRange {
            messageEnd = periodRange.lowerBound
        } else {
            messageEnd = afterStart.endIndex
        }
        
        let message = String(afterStart[..<messageEnd]).trimmingCharacters(in: .whitespaces)
        return message.isEmpty ? nil : message
    }
}

