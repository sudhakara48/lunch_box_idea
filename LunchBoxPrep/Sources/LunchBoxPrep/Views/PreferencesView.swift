import SwiftUI

// MARK: - PreferencesView

/// Dietary preferences screen.
///
/// Displays a toggle for each dietary option. Each toggle is bound directly
/// to `PreferencesStore.preferences`; `store.save()` is called on every change
/// so preferences persist automatically.
///
/// - Requirements: 6.1, 6.3
public struct PreferencesView: View {

    @ObservedObject public var store: PreferencesStore

    public init(store: PreferencesStore) {
        self.store = store
    }

    public var body: some View {
        Form {
            Section {
                Toggle("Vegetarian", isOn: $store.preferences.vegetarian)
                    .onChange(of: store.preferences.vegetarian) { _ in store.save() }

                Toggle("Vegan", isOn: $store.preferences.vegan)
                    .onChange(of: store.preferences.vegan) { _ in store.save() }

                Toggle("Gluten-Free", isOn: $store.preferences.glutenFree)
                    .onChange(of: store.preferences.glutenFree) { _ in store.save() }

                Toggle("Dairy-Free", isOn: $store.preferences.dairyFree)
                    .onChange(of: store.preferences.dairyFree) { _ in store.save() }

                Toggle("Nut-Free", isOn: $store.preferences.nutFree)
                    .onChange(of: store.preferences.nutFree) { _ in store.save() }
            } header: {
                Text("Dietary Options")
            } footer: {
                Text("Active preferences are included in every suggestion request.")
            }

            Section {
                Picker("Cuisine", selection: $store.preferences.cuisineRegion) {
                    ForEach(CuisineRegion.allCases) { region in
                        Text("\(region.flag) \(region.rawValue)").tag(region)
                    }
                }
                .onChange(of: store.preferences.cuisineRegion) { _ in store.save() }
            } header: {
                Text("Cuisine Style")
            } footer: {
                Text("Suggestions will be inspired by the selected cuisine.")
            }

            Section {
                Button("Reset All", role: .destructive) {
                    store.reset()
                }
            }
        }
        .navigationTitle("Preferences")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }
}
