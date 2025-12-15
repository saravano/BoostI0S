import SwiftUI

struct GroupedCheckboxList: View {
    let cards: [String: [String]]
    @Binding var savedSelections: Set<String>
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(Array(cards.keys.sorted()), id: \.self) { groupName in
                    GroupHeader(groupName: groupName)
                    ForEach(cards[groupName] ?? [], id: \.self) { item in
                        HStack {
                            Button(action: {
                                toggleSelection(item)
                            }) {
                                Image(systemName: savedSelections.contains(item) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(savedSelections.contains(item) ? .black : .gray)
                            }
                            Text(item)
                                .foregroundStyle(.white)
                                .font(.body)
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                    }
                }
            }
            .padding()
        }
    }
    
    private func toggleSelection(_ item: String) {
        if savedSelections.contains(item) {
            savedSelections.remove(item)
        } else {
            savedSelections.insert(item)
        }
    }
}
#if DEBUG
// Minimal fallback to avoid compile errors if GroupHeader isn't defined elsewhere.
private struct GroupHeader: View {
    let groupName: String
    var body: some View {
        HStack {
            Text(groupName)
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.clear)
    }
}
#endif

