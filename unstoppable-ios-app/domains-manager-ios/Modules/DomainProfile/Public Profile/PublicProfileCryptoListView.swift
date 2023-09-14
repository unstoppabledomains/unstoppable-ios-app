//
//  PublicProfileCryptoListView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.08.2023.
//

import SwiftUI

struct PublicProfileCryptoListView: View, ViewAnalyticsLogger {
    
    @Environment(\.presentationMode) private var presentationMode

    let domainName: DomainName
    let recordsDict: [String : String]
    @State private var records: [RecordWithIcon] = []
    @State private var copiedRecord: CryptoRecord?
    @State private var copiedTimer: Timer?
    var analyticsName: Analytics.ViewName { .domainCryptoList }

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            PublicProfilePullUpHeaderView(domainName: domainName,
                                          closeCallback: {
                logButtonPressedAnalyticEvents(button: .close)
                dismiss()
            })
            List(records, id: \.record.coin) { record in
                viewForRecordRow(record)
                    .listRowSeparator(.hidden)
                    .unstoppableListRowInset()
            }
            .offset(y: -8)
            .background(.clear)
            .clearListBackground()
            .ignoresSafeArea()
        }
        .background(Color.backgroundDefault)
        .task {
            await prepareRecords()
        }
        .onAppear {
            UITableView.appearance().backgroundColor = .clear
            logAnalytic(event: .viewDidAppear, parameters: [.domainName : domainName])
        }
    }
    
}

// MARK: - Private methods
private extension PublicProfileCryptoListView {
    func prepareRecords() async {
        let currencies = await appContext.coinRecordsService.getCurrencies()
        let recordsData = DomainRecordsData(from: recordsDict,
                                            coinRecords: currencies,
                                            resolver: nil)
        records = recordsData.records
            .map { RecordWithIcon(record: $0) }
            .sorted(by: { lhs, rhs in
            lhs.record.coin.ticker < rhs.record.coin.ticker
        })
    }
    
    func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
    
    @ViewBuilder
    func viewForRecordRow(_ record: RecordWithIcon) -> some View {
        HStack(spacing: 16) {
            Image(uiImage: record.icon ?? .init())
                .resizable()
                .background(record.icon == nil ? Color.backgroundMuted2 : Color.clear)
                .frame(width: 40,
                       height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.borderSubtle, lineWidth: 1)
                )
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 0) {
                Text(getNameForRecord(record.record))
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundColor(.foregroundDefault)
                    .frame(height: 24)
                Text(getValueForRecord(record.record))
                    .font(.currentFont(size: 14, weight: .regular))
                    .foregroundColor(.foregroundSecondary)
                    .frame(height: 20)
            }
            Spacer()
            copyButtonForRecord(record.record)
        }
        .onAppear {
            loadIconIfNeededFor(record: record)
        }
    }
    
    
    func getNameForRecord(_ record: CryptoRecord) -> String {
        if let fullName = record.coin.fullName {
            return "\(fullName) · \(record.coin.ticker)"
        } else {
            return record.coin.ticker
        }
    }
    
    func getValueForRecord(_ record: CryptoRecord) -> String {
        record.address.walletAddressTruncated
    }
    
    @ViewBuilder
    func copyButtonForRecord(_ record: CryptoRecord) -> some View {
        let copiedString = String.Constants.copied.localized()
        let copyString = String.Constants.copy.localized()
        let isCopied = copiedRecord == record
        let minWidth = copiedString.width(withConstrainedHeight: .infinity,
                                      font: .currentFont(withSize: 14, weight: .medium)) + 12 * 2 // Side offset from both sides
        Button {
            UIPasteboard.general.string = record.address
            UDVibration.buttonTap.vibrate()
            copiedRecord = record
            logButtonPressedAnalyticEvents(button: .copyCoinAddress)
            startResetCopiedTimer()
        } label: {
            Text(isCopied ? copiedString : copyString)
                .font(.currentFont(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(minWidth: minWidth, minHeight: 32)
        .background(isCopied ? Color.backgroundSuccessEmphasis : Color.backgroundAccentEmphasis)
        .clipShape(Capsule())
        .buttonStyle(PlainButtonStyle())
    }
    
    func startResetCopiedTimer() {
        copiedTimer?.invalidate()
        copiedTimer = Timer.scheduledTimer(withTimeInterval: 1,
                                           repeats: false,
                                           block: { _ in
            copiedRecord = nil
        })
    }
    
    struct RecordWithIcon: Hashable {
        let record: CryptoRecord
        var icon: UIImage?
    }
    
    func loadIconIfNeededFor(record: RecordWithIcon) {
        guard record.icon == nil else { return }
        
        Task {
            
            func setIcon(_ icon: UIImage?, to record: RecordWithIcon) {
                if let i = records.firstIndex(where: { $0.record.coin == record.record.coin }) {
                    records[i].icon = icon
                }
            }
            
            let coin = record.record.coin
            let initials = await appContext.imageLoadingService.loadImage(from: .initials(coin.ticker,
                                                                                          size: .default,
                                                                                          style: .gray),
                                                                downsampleDescription: nil)
            setIcon(initials, to: record)

            
            if let icon = await appContext.imageLoadingService.loadImage(from: .currency(coin,
                                                                                         size: .default,
                                                                                         style: .gray),
                                                                         downsampleDescription: nil) {
                setIcon(icon, to: record)
            }
        }
    }
}

struct PublicProfileCryptoListView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(Constants.swiftUIPreviewDevices, id: \.self) { device in
            PublicProfileCryptoListView(domainName: "dans.crypto",
                                        recordsDict: ["crypto.ETH.address": "0x557fc13812460e5414d9881cb3659902e9501041",
                                                      "crypto.1INCH.version.ERC20.address": "0x557fc13812460e5414d9881cb3659902e9501041",
                                                      "crypto.MATIC.version.ERC20.address": "0x557fc13812460e5414d9881cb3659902e9501041",
                                                      "crypto.MATIC.version.MATIC.address": "0x557fc13812460e5414d9881cb3659902e9501041",
                                                      "crypto.1INCH.version.MATIC.address": "0x557fc13812460e5414d9881cb3659902e9501041"])
                .previewDevice(PreviewDevice(rawValue: device))
                .previewDisplayName(device)
        }
    }
}
