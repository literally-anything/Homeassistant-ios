import AppIntents
import Shared
import SwiftUI
import WidgetKit

struct WidgetBasicContainerView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    @Environment(\.pixelLength) var pixelLength: CGFloat

    let emptyViewGenerator: () -> AnyView
    let contents: [WidgetBasicViewModel]

    init(emptyViewGenerator: @escaping () -> AnyView, contents: [WidgetBasicViewModel]) {
        self.emptyViewGenerator = emptyViewGenerator
        self.contents = contents
    }

    var body: some View {
        Group {
            switch contents.count {
            case 0: emptyViewGenerator()
            case 1: singleView(for: contents.first!)
            default: multiView(for: contents)
            }
        }
        .widgetBackground(Color.clear)
    }

    func singleView(for model: WidgetBasicViewModel) -> some View {
        ZStack {
            if !Self.clearFamilies.contains(family) {
                model.backgroundColor
                    .opacity(0.8)
            }
            if case let .widgetURL(url) = model.interactionType {
                WidgetBasicView(model: model, sizeStyle: .single)
                    .widgetURL(url.withWidgetAuthenticity())
            } else {
                if #available(iOS 17.0, *), let intent = intent(for: model) {
                    Button(intent: intent) {
                        WidgetBasicView(model: model, sizeStyle: .single)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @available(iOS 17.0, *)
    private func intent(for model: WidgetBasicViewModel) -> (any AppIntent)? {
        switch model.interactionType {
        case .widgetURL:
            return nil
        case let .appIntent(widgetIntentType):
            switch widgetIntentType {
            case .action:
                let intent = WidgetActionsAppIntent()
                intent.actions = [IntentActionAppEntity(id: model.id, displayString: model.title)]
                return intent
            }
        }
    }

    @ViewBuilder
    func multiView(for models: [WidgetBasicViewModel]) -> some View {
        let actionCount = models.count
        let columnCount = Self.columnCount(family: family, modelCount: actionCount)
        let rows = Array(columnify(count: columnCount, models: models))

        let sizeStyle: WidgetBasicSizeStyle = {
            let compactBp = Self.compactSizeBreakpoint(for: family)

            let condensed = compactBp < actionCount
            let compactRowCount = compactBp / Self.columnCount(family: family, modelCount: compactBp)

            if condensed {
                return .condensed
            } else if rows.count < compactRowCount {
                return .expanded
            } else {
                return .regular
            }
        }()

        VStack(alignment: .leading, spacing: pixelLength) {
            ForEach(rows, id: \.self) { column in
                HStack(spacing: pixelLength) {
                    ForEach(column) { model in
                        ZStack {
                            // stacking the color under makes the Link's highlight state nicer
                            if !Self.clearFamilies.contains(family) {
                                model.backgroundColor
                                    .opacity(0.8)
                            }
                            if case let .widgetURL(url) = model.interactionType {
                                Link(destination: url.withWidgetAuthenticity()) {
                                    WidgetBasicView(model: model, sizeStyle: sizeStyle)
                                }
                            } else {
                                if #available(iOS 17.0, *), let intent = intent(for: model) {
                                    Button(intent: intent) {
                                        WidgetBasicView(model: model, sizeStyle: sizeStyle)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(Color.black)
    }

    private func columnify(count: Int, models: [WidgetBasicViewModel]) -> AnyIterator<[WidgetBasicViewModel]> {
        var perActionIterator = models.makeIterator()
        return AnyIterator { () -> [WidgetBasicViewModel]? in
            let column = stride(from: 0, to: count, by: 1)
                .compactMap { _ in perActionIterator.next() }
            return column.isEmpty == false ? column : nil
        }
    }

    static func columnCount(family: WidgetFamily, modelCount: Int) -> Int {
        switch family {
        #if !targetEnvironment(macCatalyst) // no ventura SDK yet
        case .accessoryCircular, .accessoryInline, .accessoryRectangular: return 1
        #endif
        case .systemSmall: return 1
        case .systemMedium: return 2
        case .systemLarge:
            if modelCount <= 2 {
                // 2 'landscape' actions looks better than 2 'portrait'
                return 1
            } else {
                return 2
            }
        case .systemExtraLarge:
            if modelCount <= 4 {
                return 1
            } else if modelCount <= 15 {
                // note this is 15 and not 16 - divisibility by 3 here
                return 3
            } else {
                return 4
            }
        @unknown default: return 2
        }
    }

    /// more than this number: show compact (icon left, text right) version
    static func compactSizeBreakpoint(for family: WidgetFamily) -> Int {
        switch family {
        #if !targetEnvironment(macCatalyst) // no ventura SDK yet
        case .accessoryCircular, .accessoryInline, .accessoryRectangular: return 1
        #endif
        case .systemSmall: return 1
        case .systemMedium: return 4
        case .systemLarge: return 8
        case .systemExtraLarge: return 16
        @unknown default: return 8
        }
    }

    static func maximumCount(family: WidgetFamily) -> Int {
        switch family {
        #if !targetEnvironment(macCatalyst) // no ventura SDK yet
        case .accessoryCircular, .accessoryInline, .accessoryRectangular: return 1
        #endif
        case .systemSmall: return 1
        case .systemMedium: return 8
        case .systemLarge: return 16
        case .systemExtraLarge: return 32
        @unknown default: return 8
        }
    }

    private static var clearFamilies: [WidgetFamily] {
        var supportedFamilies: [WidgetFamily] = []

        if #available(iOSApplicationExtension 16.0, *) {
            supportedFamilies = [.accessoryCircular, .accessoryInline, .accessoryRectangular]
        }

        return supportedFamilies
    }
}
