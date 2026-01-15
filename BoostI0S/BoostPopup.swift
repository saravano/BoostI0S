import SwiftUI

struct BoostPopupView: View {
    @State private var showConfiguration = false
    let message: String
    let cards: [String: [String]]
    let savedCards: Set<String>
    @ObservedObject var viewModel: BoostViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text(message)
                .foregroundStyle(.white)
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 2	0)
                .overlay {
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(.yellow, lineWidth: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                 }
                .onTapGesture {
                    if (!viewModel.nextStep()) {
                        exit(0) 
                    }
                }
                .onLongPressGesture {
                    showConfiguration = true
                }
        }
        .fullScreenCover(isPresented: $showConfiguration) {
            CardSelectionDialog(
                cards: cards,
                savedCards: $viewModel.savedCards,
                viewModel: viewModel
            )
        }
        .background(.black)
        .ignoresSafeArea()
    }
}


