import SwiftUI

struct ProductCardView: View {
    let product: Product

    var body: some View {
        HStack(spacing: 14) {
            productImage

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text(product.name)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer(minLength: 8)

                    statusBadge
                }

                Label(product.category, systemImage: "tag.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Label(DateHelper.displayDate(product.expiryDate), systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(DateHelper.daysText(product.daysUntilExpiry))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(product.statusColor)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var productImage: some View {
        Group {
            if let image = ImageStorageHelper.image(from: product.imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.thinMaterial)
            }
        }
        .frame(width: 78, height: 78)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.separator.opacity(0.3), lineWidth: 1)
        )
    }

    private var statusBadge: some View {
        Label(product.expiryStatus.rawValue, systemImage: product.expiryStatus.systemImage)
            .font(.caption.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .foregroundStyle(product.statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(product.statusColor.opacity(0.14), in: Capsule())
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}
