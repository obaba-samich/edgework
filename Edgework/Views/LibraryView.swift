import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var store: Store
    @State private var query = ""
    @State private var category: Category?
    @State private var onlyMine = false
    @State private var favoritesOnly = false
    @State private var planFilter = 0 // 0 all, 1 priority, 2 required

    private var results: [Exercise] {
        let hidden: Set<Category> = store.data.settings.sport == .track ? Category.hockeyOnly : Category.trackOnly
        return Library.all.filter { ex in
            (category == nil ? !hidden.contains(ex.category) : ex.category == category)
                && (!onlyMine || ex.equipment.allSatisfy { store.data.settings.equipment.contains($0) })
                && (!favoritesOnly || store.isFavorite(ex.id))
                && (planFilter != 1 || store.priority(ex.id) > 0)
                && (planFilter != 2 || store.isRequired(ex.id))
                && (query.isEmpty || ex.name.localizedCaseInsensitiveContains(query)
                    || ex.primary.contains { $0.title.localizedCaseInsensitiveContains(query) }
                    || ex.category.title.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    filters
                    let grouped = Dictionary(grouping: results, by: \.category)
                    let cats = Category.allCases.filter { grouped[$0] != nil }
                    if cats.isEmpty {
                        EmptyState(symbol: "magnifyingglass", title: "Nothing found", message: "Try a different search or clear the filters.")
                    }
                    ForEach(cats) { cat in
                        let list = grouped[cat] ?? []
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: cat.symbol).foregroundStyle(cat.color).font(.system(size: 13, weight: .bold))
                                Overline(cat.title)
                                Spacer()
                                Text("\(list.count)").font(.number(12, .semibold)).foregroundStyle(Theme.text3)
                            }
                            VStack(spacing: 0) {
                                ForEach(Array(list.enumerated()), id: \.element.id) { idx, ex in
                                    NavigationLink {
                                        ExerciseDetailView(exercise: ex)
                                    } label: {
                                        ExerciseRowLabel(exercise: ex, trailing: ex.defaultTarget(), showFavorite: store.isFavorite(ex.id),
                                                         priority: store.priority(ex.id), required: store.isRequired(ex.id))
                                            .padding(.vertical, 9)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Picker("Priority", selection: Binding(get: { store.priority(ex.id) }, set: { store.setPriority(ex.id, $0) })) {
                                            ForEach(0..<4) { Text(Store.priorityNames[$0]).tag($0) }
                                        }
                                        Button {
                                            store.setRequired(ex, !store.isRequired(ex.id))
                                        } label: {
                                            Label(store.isRequired(ex.id) ? "Not required" : "Required in every workout",
                                                  systemImage: store.isRequired(ex.id) ? "checklist.unchecked" : "checklist")
                                        }
                                        Button { store.toggleFavorite(ex.id) } label: {
                                            Label(store.isFavorite(ex.id) ? "Unfavorite" : "Favorite", systemImage: "star")
                                        }
                                    }
                                    if idx < list.count - 1 { Divider().overlay(Theme.stroke).padding(.leading, 56) }
                                }
                            }
                            .cardStyle(padding: 12)
                        }
                    }
                }
                .padding(16)
            }
            .screenBackground()
            .navigationTitle("Library")
            .searchable(text: $query, prompt: "Exercises, muscles, categories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        MustDosEditor()
                    } label: {
                        Label("Required (\(store.data.settings.mustDos.count))", systemImage: "checklist")
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
        }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button { category = nil } label: {
                        Chip(text: "All \(Library.all.count)", color: Theme.ice, filled: category == nil)
                    }
                    ForEach(Category.allCases.filter { c in
                        !(store.data.settings.sport == .track ? Category.hockeyOnly : Category.trackOnly).contains(c)
                    }) { c in
                        Button { category = category == c ? nil : c } label: {
                            Chip(text: c.title, symbol: c.symbol, color: c.color, filled: category == c)
                        }
                    }
                }
                .buttonStyle(PressableStyle())
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
            HStack(spacing: 8) {
                Button { onlyMine.toggle() } label: {
                    Chip(text: "My equipment", symbol: onlyMine ? "checkmark" : "dumbbell", color: Theme.text, filled: onlyMine)
                }
                Button { favoritesOnly.toggle() } label: {
                    Chip(text: "Favorites", symbol: "star.fill", color: Theme.amber, filled: favoritesOnly)
                }
                Button { planFilter = planFilter == 1 ? 0 : 1 } label: {
                    Chip(text: "Priority", symbol: "arrow.up.circle.fill", color: Theme.green, filled: planFilter == 1)
                }
                Button { planFilter = planFilter == 2 ? 0 : 2 } label: {
                    Chip(text: "Required", symbol: "checklist", color: Theme.red, filled: planFilter == 2)
                }
            }
            .buttonStyle(PressableStyle())
        }
    }
}

// MARK: - Picker

struct ExercisePicker: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let onPick: ([Exercise]) -> Void
    @State private var selected: [String] = []
    @State private var query = ""
    @State private var category: Category?

    private var results: [Exercise] {
        Library.all.filter { ex in
            (category == nil || ex.category == category)
                && (query.isEmpty || ex.name.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Category.allCases) { c in
                                Button { category = category == c ? nil : c } label: {
                                    Chip(text: c.title, symbol: c.symbol, color: c.color, filled: category == c)
                                }
                                .buttonStyle(PressableStyle())
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                }
                Section {
                    ForEach(results) { ex in
                        Button {
                            if let i = selected.firstIndex(of: ex.id) { selected.remove(at: i) } else { selected.append(ex.id) }
                            store.haptic(.light)
                        } label: {
                            HStack {
                                ExerciseRowLabel(exercise: ex, trailing: ex.defaultTarget())
                                Image(systemName: selected.contains(ex.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundStyle(selected.contains(ex.id) ? Theme.ice : Theme.text3)
                            }
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Theme.surface)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .screenBackground()
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Add exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(selected.isEmpty ? "Add" : "Add \(selected.count)") {
                        onPick(selected.compactMap { Library.byID[$0] })
                        dismiss()
                    }
                    .disabled(selected.isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
    }
}
