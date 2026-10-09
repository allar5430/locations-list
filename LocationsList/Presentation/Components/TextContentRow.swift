//
//  TextContentRow.swift
//  PlacesApp
//
//  Created by Allar-Oleksii Aleksandrovych on 08/10/2026.
//

import SwiftUI

struct TextContentRow: View {
    enum RowState {
        case loading
        case active
        case failed
        
        var isLoading: Bool {
            switch self {
            case .loading: return true
            default: return false
            }
        }
    }
    struct Constants {
        static let horizontalSpacing = 12.0
        static let verticalSpacing = 4.0
        static let bottomSpacing = 8.0
        static let verticalPadding = 4.0
    }
    let state: RowState
    var title: String?
    var subtitle: String?
    var accessibilitySubtitle: String?
    
    @ViewBuilder var subtitleView: some View {
        if let subtitle {
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    var body: some View {
        HStack(spacing: Constants.horizontalSpacing) {
            VStack(
                alignment: .leading,
                spacing: Constants.verticalSpacing
            ) {
                switch state {
                case .active:
                    title.flatMap { Text($0) }
                    
                    subtitleView
                case .loading:
                    Text(Strings.string(for: .locationName))
                        .redacted(reason: .placeholder)
                    
                    Text(Strings.string(for: .coordinatePlaceholder))
                        .font(.caption)
                        .redacted(reason: .placeholder)
                case .failed:
                    Text(Strings.string(for: .unknown))
                    
                    subtitleView
                }
            }

            Spacer(minLength: Constants.bottomSpacing)

            if !state.isLoading {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, Constants.verticalPadding)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title ?? "")
        .accessibilityValue(accessibilitySubtitle ?? subtitle ?? "")
    }
}
