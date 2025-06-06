import XCTest
@testable import network_speed_monitor_mac_native

final class SpeedPanelViewTests: XCTestCase {
    func testSplitValueAndUnit() {
        XCTAssertEqual(SpeedPanelView.splitValueAndUnit("12.34 MB/s").0, "12.34")
        XCTAssertEqual(SpeedPanelView.splitValueAndUnit("12.34 MB/s").1, "MB/s")
        XCTAssertEqual(SpeedPanelView.splitValueAndUnit("100%").0, "100")
        XCTAssertEqual(SpeedPanelView.splitValueAndUnit("100%").1, "%")
        XCTAssertEqual(SpeedPanelView.splitValueAndUnit("0").0, "0")
        XCTAssertEqual(SpeedPanelView.splitValueAndUnit("0").1, "")
    }
} 