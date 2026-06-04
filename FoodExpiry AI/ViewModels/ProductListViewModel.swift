import Combine
import Foundation

@MainActor
final class ProductListViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedFilter: ProductStatusFilter = .all

    func filteredProducts(from products: [Product]) -> [Product] {
        products
            .filter { product in
                let matchesSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || product.name.localizedCaseInsensitiveContains(searchText)

                let matchesFilter: Bool
                if let status = selectedFilter.expiryStatus {
                    matchesFilter = product.expiryStatus == status
                } else {
                    matchesFilter = true
                }

                return matchesSearch && matchesFilter
            }
            .sorted { first, second in
                if first.expiryDate == second.expiryDate {
                    return first.name.localizedCaseInsensitiveCompare(second.name) == .orderedAscending
                }

                return first.expiryDate < second.expiryDate
            }
    }
}
