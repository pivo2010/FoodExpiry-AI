import SwiftData
import SwiftUI

struct ProductListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.expiryDate, order: .forward) private var products: [Product]
    @StateObject private var viewModel = ProductListViewModel()
    @State private var isShowingAddProduct = false

    private var visibleProducts: [Product] {
        viewModel.filteredProducts(from: products)
    }

    var body: some View {
        NavigationStack {
            Group {
                if products.isEmpty {
                    EmptyProductsView()
                } else {
                    List {
                        filterSection

                        ForEach(visibleProducts) { product in
                            NavigationLink {
                                ProductDetailView(product: product)
                            } label: {
                                ProductCardView(product: product)
                                    .padding(.vertical, 4)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(product)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .overlay {
                        if visibleProducts.isEmpty {
                            ContentUnavailableView.search(text: viewModel.searchText)
                        }
                    }
                }
            }
            .navigationTitle("FoodExpiry AI")
            .searchable(text: $viewModel.searchText, prompt: "Поиск по названию")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddProduct = true
                    } label: {
                        Label("Добавить", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddProduct) {
                AddProductView()
            }
        }
    }

    private var filterSection: some View {
        Section {
            Picker("Статус", selection: $viewModel.selectedFilter) {
                ForEach(ProductStatusFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 12, trailing: 16))
            .listRowSeparator(.hidden)
        }
    }

    private func delete(_ product: Product) {
        modelContext.delete(product)
        try? modelContext.save()
    }
}

#Preview {
    ProductListView()
        .modelContainer(for: Product.self, inMemory: true)
}
