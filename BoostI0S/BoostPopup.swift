import SwiftUI

struct BoostPopupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showConfiguration = false
    let message: String
    let cards: [String: [String]]
    let savedCards: Set<String>
    @ObservedObject var viewModel: BoostViewModel
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 50)
                .stroke(.yellow, lineWidth: 3)
                .frame(height: 100)
                .background(.black.opacity(0.8))
                .overlay(alignment: .center) {
                    Text(message)
                        .foregroundStyle(.white)
                        .font(.system(size: 18))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                }
                .onTapGesture { dismiss() }
                .onLongPressGesture { showConfiguration = true }
        }
        .fullScreenCover(isPresented: $showConfiguration) {
            CardSelectionDialog(
                cards: cards,
                savedCards: $viewModel.savedCards,
                viewModel: viewModel
            )
        }
    }
}
