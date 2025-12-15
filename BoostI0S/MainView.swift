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
        .sheet(isPresented: $showingCardDialog) {
            CardSelectionDialog(
                cards: utility.cardDefinitions,
                savedCards: $viewModel.savedCards,
                viewModel: viewModel
            )
        }
        .onChange(of: showingCardDialog) { newValue in
            if !newValue {  // Dialog just closed
                viewModel.determineCard()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .ignoresSafeArea()

    }
}

#Preview {
    MainView()
}

