import AVFoundation
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct AddProductView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = AddProductViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isShowingCamera = false
    @State private var isShowingCameraUnavailableAlert = false
    @State private var cameraAlertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Фото") {
                    imagePreview

                    HStack(spacing: 12) {
                        Button {
                            Task {
                                await openCamera()
                            }
                        } label: {
                            Label("Сделать фото", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Галерея", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    Button {
                        Task {
                            await viewModel.analyzeSelectedImage()
                        }
                    } label: {
                        HStack {
                            if viewModel.isAnalyzing {
                                ProgressView()
                            }

                            Label("Проанализировать фото", systemImage: "sparkles")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canAnalyze)
                }

                Section("Информация") {
                    TextField("Название продукта", text: $viewModel.productName)

                    Picker("Категория", selection: $viewModel.category) {
                        ForEach(Product.categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }

                    DatePicker("Срок годности", selection: $viewModel.expiryDate, displayedComponents: .date)

                    if let confidence = viewModel.aiConfidence {
                        LabeledContent("Точность AI", value: confidence.formatted(.percent.precision(.fractionLength(0...1))))
                    }
                }

                Section("Заметки") {
                    TextField("Например: открыт 3 июня", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section {
                    Button {
                        saveProduct()
                    } label: {
                        Label("Сохранить продукт", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canSave)
                }
            }
            .navigationTitle("Новый продукт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPicker { image in
                    viewModel.selectedImage = image
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    await loadPhoto(from: newItem)
                }
            }
            .alert("Ошибка анализа", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Камера недоступна", isPresented: $isShowingCameraUnavailableAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(cameraAlertMessage)
            }
        }
    }

    private var imagePreview: some View {
        Group {
            if let selectedImage = viewModel.selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "photo.badge.plus")
                        .font(.largeTitle)
                    Text("Добавьте фото продукта")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.thinMaterial)
            }
        }
        .frame(height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                await MainActor.run {
                    viewModel.selectedImage = image
                }
            }
        } catch {
            await MainActor.run {
                viewModel.errorMessage = "Не удалось загрузить выбранное фото."
            }
        }
    }

    private func saveProduct() {
        guard let product = viewModel.makeProduct() else { return }
        modelContext.insert(product)
        try? modelContext.save()
        dismiss()
    }

    private func openCamera() async {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            cameraAlertMessage = "Камера не работает в большинстве симуляторов. Запустите приложение на реальном iPhone или выберите фото из галереи."
            isShowingCameraUnavailableAlert = true
            return
        }

        guard Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil else {
            cameraAlertMessage = "В настройках target не добавлен NSCameraUsageDescription. Добавьте этот ключ в Info, иначе iOS не разрешит приложению открыть камеру."
            isShowingCameraUnavailableAlert = true
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isShowingCamera = true
        case .notDetermined:
            let isGranted = await AVCaptureDevice.requestAccess(for: .video)
            if isGranted {
                isShowingCamera = true
            } else {
                cameraAlertMessage = "Доступ к камере не предоставлен. Разрешите доступ в настройках iPhone."
                isShowingCameraUnavailableAlert = true
            }
        case .denied:
            cameraAlertMessage = "Доступ к камере запрещён. Откройте Настройки iPhone и разрешите камеру для FoodExpiry AI."
            isShowingCameraUnavailableAlert = true
        case .restricted:
            cameraAlertMessage = "Доступ к камере ограничен настройками устройства."
            isShowingCameraUnavailableAlert = true
        @unknown default:
            cameraAlertMessage = "Не удалось проверить доступ к камере."
            isShowingCameraUnavailableAlert = true
        }
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }

            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddProductView()
        .modelContainer(for: Product.self, inMemory: true)
}
