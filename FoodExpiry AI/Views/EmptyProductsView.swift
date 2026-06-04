import SwiftUI

struct EmptyProductsView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Нет продуктов", systemImage: "refrigerator.fill")
        } description: {
            Text("Добавьте продукт по фото или заполните данные вручную.")
        } actions: {
            Label("Нажмите +, чтобы начать", systemImage: "plus.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    EmptyProductsView()
}
