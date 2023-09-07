//
//  UBTController.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 09.08.2023.
//

import Foundation
import CoreBluetooth

enum UBTControllerState {
    case notReady
    case setupFailed
    case unauthorized
    case ready
}

struct BTDomainUIInfo: Hashable, Identifiable {
    let id: UUID
    var domainName: String = ""
    var walletAddress: String = ""
    
    static let mock = BTDomainUIInfo(id: UUID(), domainName: "one.x", walletAddress: "0x537e2EB956AEC859C99B3e5e28D8E45200C4Fa52")
    static func newMock() -> BTDomainUIInfo {
        BTDomainUIInfo(id: UUID(), domainName: "kuplin.hi", walletAddress: "0x557fc13812460e5414d9881cb3659902e9501041")
    }
    static func newMock(_ count: Int) -> [BTDomainUIInfo] {
        var arr = [BTDomainUIInfo]()
        for _ in 0..<count {
            arr.append(.newMock())
        }
        return arr
    }
}

final class UBTController: NSObject, ObservableObject {
    
    let domainEntity: any DomainEntity
    private let serviceId = CBUUID(string: "090DAE5A-0DD8-4327-B074-E1E09B259597")
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    private var peripheralService: CBMutableService!
    private var discoveredDevices: [DiscoveredBTDevice] = []
    private var peripherals: [CBPeripheral] = [] // We should hold reference to peripheral
    
    @Published private(set) var btState: UBTControllerState = .notReady
    @Published private(set) var isScanning = false
    @Published private(set) var readyDevices: [BTDomainUIInfo] = [] // BTDeviceUI.newMock(3)
    
    init(domainEntity: any DomainEntity) {
        self.domainEntity = domainEntity
        super.init()
        
        setup()
        print("0xb2fb91c03db880c3ec1086e938c24608c6b56cc6".ethChecksumAddress())
    }
    
    func setup() {
        do {
            setupCentralManager()
            try setupPeripheralManager()
        } catch {
            btState = .setupFailed
        }
    }
    
    func setupCentralManager() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func setupPeripheralManager() throws {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        peripheralService = CBMutableService(type: serviceId, primary: true)
        
        try setCharacteristicsWith(domainName: domainEntity.name, walletAddress: domainEntity.ownerWallet ?? "")
    }
    
    func startScanning() {
        if btState == .ready {
            isScanning = true
            centralManager.scanForPeripherals(withServices: [serviceId], options: nil)
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceId]])
        }
    }
    
    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
        peripheralManager.stopAdvertising()
    }
    
    enum CharacteristicType: CaseIterable {
        case domainInfo
        
        var id: String {
            switch self {
            case .domainInfo:
                return "3403C4D9-2C2C-4A6A-A9DB-115D10095771"
            }
        }
        var uuid: UUID {
            UUID(uuidString: id)!
        }
        var cbuuid: CBUUID {
            CBUUID(string: id)
        }
        
        func buildCharacteristicWith(value: Data?) -> CBMutableCharacteristic {
            CBMutableCharacteristic(type: cbuuid, properties: .read, value: value, permissions: .readable)
        }
    }
    
    func addMock() {
        #if DEBUG
        readyDevices.append(contentsOf: BTDomainUIInfo.newMock(1))
        #endif
    }
    
    struct DomainBTInfo: Codable {
        let name: String
        let walletAddress: String
    }
}

// MARK: - CBCentralManagerDelegate, CBPeripheralDelegate
extension UBTController: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        updateState()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let device = DiscoveredBTDevice(peripheral: peripheral)

        guard discoveredDevices.contains(where: { $0.id == device.id }) == false else { return }
        self.peripherals.append(peripheral)
        discoveredDevices.append(device)
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let peripheralServices = peripheral.services else { return }
        for service in peripheralServices {
            peripheral.discoverCharacteristics(CharacteristicType.allCases.map { $0.cbuuid }, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            peripheral.readValue(for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let type = CharacteristicType.allCases.first(where: { $0.cbuuid == characteristic.uuid }),
              let value = characteristic.value,
        let domainInfo = DomainBTInfo.objectFromData(value),
              let i = self.discoveredDevices.firstIndex(where: { $0.peripheral.identifier == peripheral.identifier }) else { return }
        
        
        switch type {
        case .domainInfo:
            discoveredDevices[i].name = domainInfo.name
            discoveredDevices[i].walletAddress = domainInfo.walletAddress
        }
        updateReadyDevices()
    }
}

// MARK: - CBPeripheralManagerDelegate
extension UBTController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            peripheralManager.add(peripheralService)
        }
        updateState()
    }
}

// MARK: - Private methods
private extension UBTController {
    func updateState() {
        switch (centralManager.state, peripheralManager.state) {
        case (.poweredOn, .poweredOn):
            btState = .ready
        case (.unauthorized, _), (_, .unauthorized):
            btState = .unauthorized
        default:
            btState = .notReady
        }
//        btState = (centralManager.state == .poweredOn && peripheralManager.state == .poweredOn) ?.ready : .notReady
    }
    
    func updateReadyDevices() {
        readyDevices = discoveredDevices.filter({ $0.isReady }).map({ $0.btUI() })
    }
    
    func setCharacteristicsWith(domainName: String, walletAddress: String) throws {
        let domainInfo = DomainBTInfo(name: domainName, walletAddress: walletAddress)
        let data = try domainInfo.jsonDataThrowing()
        let nameChar = createCharacteristicOfType(.domainInfo, withValue: data)
        peripheralService.characteristics = [nameChar]
    }
    
    func createCharacteristicOfType(_ type: CharacteristicType, withValue value: Data) -> CBMutableCharacteristic {
        return type.buildCharacteristicWith(value: value)
    }
}

// MARK: - Private methods
private extension UBTController {
    struct DiscoveredBTDevice: Hashable, Identifiable {
        
        let peripheral: CBPeripheral
        let id: UUID
        var name: String = ""
        var walletAddress: String = ""
        
        var isReady: Bool {
            !name.isEmpty && !walletAddress.isEmpty
        }
        
        init(peripheral: CBPeripheral) {
            self.peripheral = peripheral
            id = peripheral.identifier
        }
        
        func btUI() -> BTDomainUIInfo {
            BTDomainUIInfo(id: id, domainName: name, walletAddress: walletAddress)
        }
    }

}

/*
case unknown = 0

case resetting = 1

case unsupported = 2

case unauthorized = 3

case poweredOff = 4

case poweredOn = 5
*/
