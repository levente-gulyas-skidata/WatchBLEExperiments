# WatchBLEExperiments

A small watchOS app for measuring how often CoreBluetooth calls
`centralManager(_:didDiscover:advertisementData:rssi:)` while scanning for a
specific BLE service UUID.

## Run the experiment

1. Install and run the Watch app on a physical Apple Watch. BLE scanning is not
   representative in the simulator.
2. Enter the advertised service UUID. The app accepts 16-bit (`180D`), 32-bit,
   and 128-bit UUIDs.
3. Tap **Start scan** and leave the app visible for a fixed duration.
4. Record **Callbacks** and **Per second** after a fixed test duration.
5. Repeat on each watchOS version with the same watch model, BLE advertiser,
   service UUID, distance, advertiser interval, and test duration.

The scan uses `CBCentralManagerScanOptionAllowDuplicatesKey: true`. This is
required to receive repeated discovery callbacks for the same peripheral.
CoreBluetooth may still coalesce advertisements, and watchOS may throttle or
suspend scanning when the app is no longer active. The callback rate therefore
is not the advertiser's raw over-the-air packet rate.

`Unique` counts distinct peripheral identifiers seen during the run. The latest
matching peripheral name and RSSI are shown as a quick check that each run is
observing the expected advertiser.
