import Shared
import SwiftUI
import UIKit

struct WatchHomeView<ViewModel>: View where ViewModel: WatchHomeViewModelProtocol {
    @StateObject private var viewModel: ViewModel
    @State private var showAssist = false

    private let stateIconSize: CGSize = .init(width: 60, height: 60)
    private let stateIconColor: UIColor = .white
    private let interfaceDevice = WKInterfaceDevice.current()

    init(viewModel: ViewModel) {
        self._viewModel = .init(wrappedValue: viewModel)
        MaterialDesignIcons.register()
    }

    var body: some View {
        navigation
            .onAppear {
                viewModel.onAppear()
            }
            .onDisappear {
                viewModel.onDisappear()
            }
            .fullScreenCover(isPresented: $showAssist, content: {
                WatchAssistView.build()
                    .environmentObject(viewModel.assistService)
            })
            .onReceive(NotificationCenter.default.publisher(for: AssistDefaultComplication.launchNotification)) { _ in
                showAssist = true
            }
    }

    @ViewBuilder
    private var navigation: some View {
        if #available(watchOS 10, *) {
            NavigationStack {
                content
            }
        } else {
            NavigationView {
                content
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        list
            .navigationTitle("")
            .modify {
                if #available(watchOS 10, *) {
                    $0.toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                showAssist = true
                            }, label: {
                                Image(uiImage: MaterialDesignIcons.microphoneIcon.image(
                                    ofSize: .init(width: 24, height: 24),
                                    color: Asset.Colors.haPrimary.color
                                ))
                            })
                        }
                    }
                } else {
                    $0
                }
            }
    }

    private var stateViewBackground: some ShapeStyle {
        if #available(watchOS 10, *) {
            return .regularMaterial
        } else {
            return Color.black.opacity(0.6)
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.actions, id: \.id) { action in
                WatchActionButtonView<ViewModel>(action: action)
                    .environmentObject(viewModel)
            }
            if viewModel.actions.isEmpty {
                noActionsView
            }
        }
        .animation(.easeInOut, value: viewModel.actions)
        // This improves how the overlayed assist view looks
        .opacity(showAssist ? 0.5 : 1)
    }

    private var noActionsView: some View {
        Text(L10n.Watch.Labels.noAction)
            .font(.footnote)
            .padding(.vertical)
    }
}

#if DEBUG
#Preview {
    WatchHomeView(viewModel: MockWatchHomeViewModel())
}
#endif
