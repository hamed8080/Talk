//
//  ToolbarView.swift
//  Talk
//
//  Created by hamed on 9/14/23.
//

import SwiftUI
import AdditiveUI
import TalkUI
import TalkViewModels
import TalkModels

struct ToolbarView<LeadingContentView: View, CenterContentView: View, TrailingContentView: View>: View {
    @ViewBuilder let leadingNavigationViews: LeadingContentView?
    @ViewBuilder let centerNavigationViews: CenterContentView?
    @ViewBuilder let trailingNavigationViews: TrailingContentView?
    var searchCompletion: ((String) -> ())?
    @Environment(\.horizontalSizeClass) var sizeClass
    let title: String?
    let searchPlaceholder: String?
    var isIpad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    @State var searchText: String = ""
    @State var isInSearchMode: Bool = false
    let showSearchButton: Bool
    let toolbarHeight: CGFloat = 46
    let searchKeyboardType: UIKeyboardType
    private var searchId: String?

    enum Field: Hashable {
        case search
    }

    @FocusState var searchFocus: Field?

    init(searchId: String? = nil,
         title: String? = nil,
         showSearchButton: Bool = true,
         searchPlaceholder: String? = nil,
         searchKeyboardType: UIKeyboardType = .default,
         leadingViews:  LeadingContentView? = nil,
         centerViews: CenterContentView? = nil,
         trailingViews: TrailingContentView? = nil,
         searchCompletion: ((String) -> ())? = nil
    ) {
        self.searchId = searchId
        self.title = title
        self.showSearchButton = showSearchButton
        self.searchPlaceholder = searchPlaceholder
        self.searchCompletion = searchCompletion
        self.leadingNavigationViews = leadingViews
        self.centerNavigationViews = centerViews
        self.trailingNavigationViews = trailingViews
        self.searchKeyboardType = searchKeyboardType
    }

    var body: some View {
        HStack(spacing: isInSearchMode ? 0 : 8) {
            toolbars
        }
        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2), value: isInSearchMode)
        .frame(minWidth: 0, maxWidth: sizeClass == .compact ? nil : .infinity)
        .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .background(MixMaterialBackground(color: Color.App.bgToolbar).ignoresSafeArea())
        .onChange(of: searchText) { newValue in
            searchCompletion?(newValue)
        }
        .overlay(alignment: .center) {
            VStack(spacing: 2) {
                if let title {
                    Text(title)
                        .frame(minWidth: 0, maxWidth: isInSearchMode ? 0 : nil, minHeight: 0, maxHeight: isInSearchMode ? 0 : 48)
                        .font(Font.bold(.subheadline))
                        .foregroundStyle(Color.App.toolbarButton)
                        .clipped()
                }
                centerNavigationViews
                    .frame(minWidth: 0, maxWidth: isInSearchMode ? 0 : nil, minHeight: 0, maxHeight: isInSearchMode ? 0 : 48)
                    .clipped()
            }
        }
        .onReceive(NotificationCenter.cancelSearch.publisher(for: .cancelSearch)) { newValue in
            if let cancelSearch = newValue.object as? Bool, cancelSearch == true, cancelSearch && isInSearchMode {
                cancelSaerch()
            }
        }
        .onReceive(NotificationCenter.forceSearch.publisher(for: .forceSearch)) { newValue in
            if (newValue.object as? String) == searchId {
                if isInSearchMode == false {
                    isInSearchMode = true
                    searchFocus = .search
                }
            }
        }
    }

    @ViewBuilder var toolbars: some View {
        leadingNavigationViews
            .frame(minWidth: 0, maxWidth: isInSearchMode ? 0 : nil, minHeight: 0, maxHeight: isInSearchMode ? 0 : toolbarHeight)
            .clipped()
            .disabled(isInSearchMode)
            .foregroundStyle(Color.App.accent)
        if !isInSearchMode {
            Spacer()
        }


        if !isInSearchMode {
            Spacer()
        }
        searchView
            .frame(minHeight: 0, maxHeight: toolbarHeight)
        trailingNavigationViews
            .frame(minWidth: 0, maxWidth: isInSearchMode ? 0 : nil, minHeight: 0, maxHeight: isInSearchMode ? 0 : toolbarHeight)
            .clipped()
            .disabled(isInSearchMode)
            .foregroundStyle(Color.App.accent)
    }

    @ViewBuilder var searchView: some View {
        if searchCompletion != nil {
            TextField((searchPlaceholder ?? "" ).bundleLocalized(), text: $searchText)
                .keyboardType(searchKeyboardType)
                .font(Font.normal(.body))
                .textFieldStyle(.clear)
                .focused($searchFocus, equals: .search)
                .frame(minWidth: 0, maxWidth: isInSearchMode ? nil : 0, minHeight: 0, maxHeight: isInSearchMode ? 38 : 0)
                .clipped()
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.clear)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

            Button {
                cancelSaerch()
            } label: {
                Text("General.cancel")
                    .padding(.leading)
                    .font(Font.normal(.body))
                    .foregroundStyle(Color.App.toolbarButton)
            }
            .buttonStyle(.borderless)
            .frame(minWidth: 0, maxWidth: isInSearchMode ? 72 : 0, minHeight: 0, maxHeight: isInSearchMode ? toolbarHeight : 0)
            .clipped()

            if showSearchButton {
                ToolbarButtonItem(imageName: "magnifyingglass", hint: "Search", padding: 8) {
                    withAnimation {
                        isInSearchMode.toggle()
                        searchFocus = isInSearchMode ? .search : .none
                    }
                }
                .frame(minWidth: 0, maxWidth: isInSearchMode ? 0 : ToolbarButtonItem.buttonWidth, minHeight: 0, maxHeight: isInSearchMode ? 0 : toolbarHeight)
                .clipped()
                .foregroundStyle(Color.App.toolbarButton)
            }
        }
    }

    private func cancelSaerch() {
        withAnimation {
            NotificationCenter.cancelSearch.post(name: .cancelSearch, object: nil)
            if isInSearchMode {
                hideKeyboard()
            }
            isInSearchMode.toggle()
            searchText = ""
            searchCompletion?("")
        }
    }
}

struct NormalToolbarViewModifier<T, TrailingContentView: View>: ViewModifier {
    let title: String
    let type: T.Type?
    let innerBack: Bool
    @ViewBuilder let trailingView: TrailingContentView?

    public init(title: String, innerBack: Bool = false, type: T.Type? = nil, trailingView: TrailingContentView? = nil) {
        self.title = title
        self.type = type
        self.innerBack = innerBack
        self.trailingView = trailingView
    }

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .safeAreaInset(edge: .top) {
                ToolbarView(title: title,
                            showSearchButton: false,
                            leadingViews: leadingView,
                            centerViews: EmptyView(),
                            trailingViews: trailingView)
            }
    }
    
    private var leadingView: some View {
        NavigationBackButton(automaticDismiss: false) {
            AppState.shared.objectsContainer.navVM.removeUIKit()
        }
    }
}

extension View {

    func normalToolbarView(title: String, innerBack: Bool = false) -> some View {
        modifier(NormalToolbarViewModifier<Any, EmptyView>(title: title, innerBack: innerBack, type: nil, trailingView: nil))
    }

    func normalToolbarView<T>(title: String, innerBack: Bool = false, type: T.Type) -> some View {
        modifier(NormalToolbarViewModifier<T, EmptyView>(title: title, innerBack: innerBack, type: type, trailingView: nil))
    }

    func normalToolbarView<T, TrailingContentView: View>(title: String, innerBack: Bool = false, type: T.Type, trailingView: TrailingContentView? = nil) -> some View {
        modifier(NormalToolbarViewModifier(title: title, innerBack: innerBack, type: type, trailingView: trailingView))
    }
}

struct ToolbarView_Previews: PreviewProvider {
    static var previews: some View {
        ToolbarView<EmptyView, EmptyView, Image>(trailingViews: Image(systemName: ""))
    }
}
