//
//  ContentView.swift
//  WatchBLEExperiments Watch App
//
//  Created by Gulyas, Levente on 15.10.26.
//

import CoreBluetooth
import SwiftUI

struct ContentView: View {
    @StateObject private var scanner = BluetoothScanner()
    @AppStorage("serviceUUID") private var serviceUUID =  "71de11e0-8504-4108-b387-6ceb6ea8886e"
    @FocusState private var isUUIDFieldFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                TextField("Service UUID", text: $serviceUUID)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused($isUUIDFieldFocused)
                    .disabled(scanner.isScanning)

                statusRow

                HStack(spacing: 6) {
                    metric(title: "Callbacks", value: "\(scanner.callbackCount)")
                    metric(title: "Unique", value: "\(scanner.uniquePeripheralCount)")
                }

                HStack(spacing: 6) {
                    metric(
                        title: "Per second",
                        value: scanner.averageCallbacksPerSecond.formatted(.number.precision(.fractionLength(2)))
                    )
                    metric(
                        title: "Since last",
                        value: scanner.secondsSinceLastDiscovery.map {
                            $0.formatted(.number.precision(.fractionLength(1))) + "s"
                        } ?? "—"
                    )
                }

                if let lastRSSI = scanner.lastRSSI {
                    VStack(spacing: 2) {
                        Text(scanner.lastPeripheralName ?? "Unnamed")
                            .font(.caption)
                            .lineLimit(1)
                        Text("Latest RSSI: \(lastRSSI) dBm")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage = scanner.errorMessage {
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button(scanner.isScanning ? "Stop" : "Start scan") {
                    isUUIDFieldFocused = false
                    if scanner.isScanning {
                        scanner.stopScanning()
                    } else {
                        scanner.startScanning(serviceUUIDText: serviceUUID)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(scanner.isScanning ? .red : .blue)
                .disabled(!scanner.isScanning && scanner.bluetoothState != .poweredOn)

                if !scanner.isScanning && scanner.callbackCount > 0 {
                    Button("Reset") {
                        scanner.resetMeasurements()
                    }
                    .font(.caption)
                }
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("BLE callbacks")
    }

    private var statusRow: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(scanner.isScanning ? Color.green : Color.secondary)
                .frame(width: 7, height: 7)
            Text(scanner.stateDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
}
