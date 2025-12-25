import SwiftUI
import boostShared

struct MainView: View {
    @StateObject private var viewModel = BoostViewModel()
    @State private var isDataLoaded = false
    @State private var showingCardDialog = false  // <- Add this
    let utility = Utility()

    var body: some View {
        ZStack {
            if !isDataLoaded {
                VStack {
                    ProgressView()
                    Text("Loading saved cards...")
                        .font(.body)
                }
            } else {
                BoostPopupView(
                    message: viewModel.boostMessage,
                    cards: utility.cardDefinitions,
                    savedCards: viewModel.savedCards,
                    viewModel: viewModel
                )
            }
        }
        .task {
            await viewModel.loadData()
            if viewModel.showConfig {
                showingCardDialog = true  // <- Trigger sheet
            } else {
                viewModel.determineCard()
            }
            isDataLoaded = true
        }
        .sheet(isPresented: $showingCardDialog, onDismiss: {
            viewModel.determineCard()
        } ){
            CardSelectionDialog(
                cards: utility.cardDefinitions,
                savedCards: $viewModel.savedCards,
                viewModel: viewModel
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .ignoresSafeArea()

    }
}

#Preview {
    MainView()
}

