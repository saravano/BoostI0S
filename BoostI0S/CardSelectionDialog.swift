//
//  CardSelectionDialog.swift
//  BoostI0S
//
//  Created by Sara on 12/16/25.
//
import SwiftUI


struct CardSelectionDialog: View {
    @Environment(\.dismiss) private var dismiss
    let cards: [String: [String]]
    @Binding var savedCards: Set<String>
    let viewModel: BoostViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(Array(cards.keys.sorted()), id: \.self) { category in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(category)
                                    .font(.headline)
                                    .foregroundColor(.yellow)
                                    .padding(.horizontal)
                                
                                ForEach(cards[category] ?? [], id: \.self) { card in
                                    CardToggleRow(
                                        cardName: card,
                                        isSelected: savedCards.contains(card),
                                        onToggle: { toggleCard(card) }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Select Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        persistSelection()
                        dismiss()
                    }
                    .foregroundColor(.yellow)
                    .fontWeight(.semibold)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
    
    private func toggleCard(_ card: String) {
        if savedCards.contains(card) {
            savedCards.remove(card)
        } else {
            savedCards.insert(card)
        }
    }
    
    private func persistSelection() {
        // Compute diffs against the view model's current savedCards
        Task { await viewModel.userDataManager.saveCardSelection(savedCards) }
    }
}

struct CardToggleRow: View {
    let cardName: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Text(cardName)
                    .foregroundColor(.white)
                    .font(.body)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .yellow : .gray)
                    .font(.title3)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
            )
            .padding(.horizontal)
        }
    }
}
