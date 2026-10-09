import SwiftUI

struct CustomLocationView: View {
    @State var viewModel: CustomLocationViewModel
    @FocusState private var isLocationFieldFocused: Bool
    @AccessibilityFocusState private var isErrorMessageFocused: Bool

    private var locationTextField: some View {
        TextField(
            viewModel.locationPlaceholder,
            text: $viewModel.locationName
        )
        .textInputAutocapitalization(.words)
        .focused($isLocationFieldFocused)
        .disabled(viewModel.state == .geocoding)
    }
    
    var body: some View {
        Form {
            Section {
                locationTextField
                Toggle(viewModel.toggleTitle, isOn: $viewModel.usesCurrentLocation)
                    .disabled(viewModel.state == .geocoding)
            }
            
            if case .failed(let message) = viewModel.state {
                Section {
                    Text(message)
                        .foregroundStyle(.red)
                        .accessibilityElement()
                        .accessibilityFocused($isErrorMessageFocused)
                        .accessibilityValue(message)
                }
            }
        }
        .navigationTitle(viewModel.title)
        .onAppear {
            isLocationFieldFocused = true
        }
        .onChange(of: viewModel.state) { _, newState in
            if case .failed = newState {
                isLocationFieldFocused = false
                Task {
                    // Keyboard moved out of focus, failure text appears, focus moved to it with small delay
                    try? await Task.sleep(for: .milliseconds(100))
                    isErrorMessageFocused = true
                }
            } else {
                isErrorMessageFocused = false
            }
        }
        .onChange(of: viewModel.locationName) { _, _ in
            if case .failed = viewModel.state {
                viewModel.didEditAfterFailure()
            }
        }
        .onChange(of: viewModel.usesCurrentLocation) { _, _ in
            viewModel.didChangeLocationMode()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(viewModel.cancelTitle) {
                    viewModel.didTapCancel()
                }
                .font(.body)

            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    viewModel.didTapDone(
                        locationName: viewModel.locationName,
                        isCurrentLocation: viewModel.usesCurrentLocation
                    )
                } label: {
                    if viewModel.state == .geocoding {
                        ProgressView()
                    } else {
                        Text(viewModel.doneTitle)
                    }
                }
                .disabled(viewModel.isDoneDisabled)
            }
        }
    }
}
