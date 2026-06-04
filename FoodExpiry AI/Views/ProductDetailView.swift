import SwiftData
import SwiftUI

struct ProductDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var product: Product
    @State private var isShowingDeleteConfirmation = false

    var body: some View {
        Form {
            Section {
                productImage
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
            }

            Section("Данные продукта") {
                TextField("Название", text: $product.name)

                Picker("Категория", selection: $product.category) {
                    ForEach(Product.categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }

                DatePicker("Дата добавления", selection: $product.dateAdded, displayedComponents: .date)
                DatePicker("Срок годности", selection: $product.expiryDate, displayedComponents: .date)

                if let confidence = product.aiConfidence {
                    LabeledContent("Точность AI", value: confidence.formatted(.percent.precision(.fractionLength(0...1))))
                }
            }

            Section("Статус") {
                LabeledContent("Состояние") {
                    Label(product.expiryStatus.rawValue, systemImage: product.expiryStatus.systemImage)
                        .foregroundStyle(product.statusColor)
                }

                LabeledContent("До окончания", value: DateHelper.daysText(product.daysUntilExpiry))
            }

            Section("Заметки") {
                TextField("Заметки", text: Binding(
                    get: { product.notes ?? "" },
                    set: { product.notes = $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
                ), axis: .vertical)
                .lineLimit(3...6)
            }

            Section {
                Button(role: .destructive) {
                    isShowingDeleteConfirmation = true
                } label: {
                    Label("Удалить продукт", systemImage: "trash")
                }
            }
        }
        .navigationTitle(product.name.isEmpty ? "Продукт" : product.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Готово") {
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
        .confirmationDialog("Удалить продукт?", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
            Button("Удалить", role: .destructive) {
                deleteProduct()
            }

            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Это действие нельзя отменить.")
        }
    }

    private var productImage: some View {
        Group {
            if let image = ImageStorageHelper.image(from: product.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.thinMaterial)
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func deleteProduct() {
        modelContext.delete(product)
        try? modelContext.save()
        dismiss()
    }
}
