import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var lang: LocalizationManager
    @EnvironmentObject private var store: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedID: String?

    private var selected: Product? {
        store.products.first { $0.id == selectedID } ?? store.annual ?? store.products.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    features
                    plans
                    subscribeButton
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.headline)
                    }
                }
            }
            .onChange(of: store.isPremium) { _, premium in
                if premium { dismiss() }
            }
            .alert(lang.s(.purchaseFailed),
                   isPresented: Binding(get: { store.errorMessage != nil },
                                        set: { if !$0 { store.errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.errorMessage ?? "")
            }
            .task {
                if store.products.isEmpty { await store.loadProducts() }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.blue.gradient)
                .padding(.top, 8)
            Text(lang.s(.premiumTitle))
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text(lang.s(.premiumSubtitle))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow("camera.viewfinder", lang.s(.premiumFeatureScan))
            featureRow("wand.and.stars", lang.s(.premiumFeatureAutofill))
            featureRow("bolt.fill", lang.s(.premiumFeatureFast))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
        }
    }

    @ViewBuilder
    private var plans: some View {
        if store.products.isEmpty {
            ProgressView(lang.s(.loadingPlans)).padding()
        } else {
            VStack(spacing: 12) {
                ForEach(store.products) { product in
                    planCard(product)
                }
            }
        }
    }

    private func planCard(_ product: Product) -> some View {
        let isSelected = product.id == selected?.id
        let isAnnual = product.id == store.annual?.id
        return Button { selectedID = product.id } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(isAnnual ? lang.s(.planAnnual) : lang.s(.planMonthly))
                            .font(.headline)
                        if isAnnual {
                            Text(lang.s(.bestValue))
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.green)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text("\(product.displayPrice) / \(isAnnual ? lang.s(.perYear) : lang.s(.perMonth))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.blue : Color(.separator), lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var subscribeButton: some View {
        Button {
            guard let product = selected else { return }
            Task { await store.purchase(product) }
        } label: {
            Group {
                if store.isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    Text(lang.s(.subscribe)).font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(selected == nil || store.isPurchasing)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Button(lang.s(.restorePurchases)) {
                Task { await store.restore() }
            }
            .font(.subheadline)
            .disabled(store.isPurchasing)

            Text(lang.s(.autoRenewNotice))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Link(lang.s(.termsOfUse),
                 destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                .font(.caption)
        }
    }
}
