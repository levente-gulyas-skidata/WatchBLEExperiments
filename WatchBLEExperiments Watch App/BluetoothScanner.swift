import CoreBluetooth
import Combine
import Foundation

final class BluetoothScanner: NSObject, ObservableObject {
    @Published private(set) var bluetoothState: CBManagerState = .unknown
    @Published private(set) var isScanning = false
    @Published private(set) var callbackCount = 0
    @Published private(set) var uniquePeripheralCount = 0
    @Published private(set) var elapsedSeconds: TimeInterval = 0
    @Published private(set) var secondsSinceLastDiscovery: TimeInterval?
    @Published private(set) var lastRSSI: Int?
    @Published private(set) var lastPeripheralName: String?
    @Published private(set) var lastCallbackAt: Date?
    @Published private(set) var errorMessage: String?

    private var centralManager: CBCentralManager!
    private var discoveredPeripheralIDs = Set<UUID>()
    private var scanStartedAt: Date?
    private var elapsedTimer: Timer?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    deinit {
        elapsedTimer?.invalidate()
    }

    var averageCallbacksPerSecond: Double {
        guard elapsedSeconds > 0 else { return 0 }
        return Double(callbackCount) / elapsedSeconds
    }

    var stateDescription: String {
        switch bluetoothState {
        case .unknown: "Initializing"
        case .resetting: "Resetting"
        case .unsupported: "Unsupported"
        case .unauthorized: "Unauthorized"
        case .poweredOff: "Powered off"
        case .poweredOn: isScanning ? "Scanning" : "Ready"
        @unknown default: "Unknown"
        }
    }

    func startScanning(serviceUUIDText: String) {
        guard let serviceUUID = Self.parseServiceUUID(serviceUUIDText) else {
            errorMessage = "Enter a 16-bit, 32-bit, or 128-bit UUID."
            return
        }

        guard bluetoothState == .poweredOn else {
            errorMessage = "Bluetooth is not ready: \(stateDescription)."
            return
        }

        resetMeasurements()
        errorMessage = nil
        isScanning = true
        scanStartedAt = Date()
        startElapsedTimer()

        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
    }

    func stopScanning() {
        centralManager.stopScan()
        updateElapsedTime()
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        isScanning = false
    }

    func resetMeasurements() {
        if isScanning {
            stopScanning()
        }
        callbackCount = 0
        uniquePeripheralCount = 0
        elapsedSeconds = 0
        secondsSinceLastDiscovery = nil
        lastRSSI = nil
        lastPeripheralName = nil
        lastCallbackAt = nil
        discoveredPeripheralIDs.removeAll()
        scanStartedAt = nil
    }

    private func startElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }

    private func updateElapsedTime() {
        guard let scanStartedAt else { return }
        elapsedSeconds = Date().timeIntervalSince(scanStartedAt)
        if let lastCallbackAt {
            secondsSinceLastDiscovery = Date().timeIntervalSince(lastCallbackAt)
        }
    }

    private static func parseServiceUUID(_ input: String) -> CBUUID? {
        var candidate = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if candidate.lowercased().hasPrefix("0x") {
            candidate.removeFirst(2)
        }

        let hexadecimal = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        if [4, 8].contains(candidate.count),
           candidate.unicodeScalars.allSatisfy(hexadecimal.contains) {
            return CBUUID(string: candidate.uppercased())
        }

        if let uuid = UUID(uuidString: candidate) {
            return CBUUID(nsuuid: uuid)
        }

        return nil
    }
}

extension BluetoothScanner: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state

        if central.state != .poweredOn, isScanning {
            stopScanning()
            errorMessage = "Scanning stopped: \(stateDescription)."
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        callbackCount += 1
        discoveredPeripheralIDs.insert(peripheral.identifier)
        uniquePeripheralCount = discoveredPeripheralIDs.count
        lastRSSI = RSSI.intValue
        lastPeripheralName =
            advertisementData[CBAdvertisementDataLocalNameKey] as? String
            ?? peripheral.name
            ?? "Unnamed"
        lastCallbackAt = Date()
        secondsSinceLastDiscovery = 0
        updateElapsedTime()
    }
}
