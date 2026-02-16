import SwiftUI

extension ContentView {
    func listOffsetX() -> CGFloat {
        let base: CGFloat
        switch underlayMode {
        case .profile:
            base = UIScreen.screenWidth
        case .leaderboard:
            base = -UIScreen.screenWidth
        default:
            base = 0
        }
        return base + horizontalDragOffset
    }

    func listOffsetY() -> CGFloat {
        let base = underlayMode == .home ? -UIScreen.screenHeight : 0
        return base + verticalDragOffset
    }

    func profileOffsetX() -> CGFloat {
        let base = underlayMode == .profile ? 0 : -UIScreen.screenWidth
        let drag =
            (underlayMode == .list && horizontalDragOffset > 0)
                || (underlayMode == .profile && horizontalDragOffset < 0)
            ? horizontalDragOffset
            : 0
        return base + drag
    }

    func leaderboardOffsetX() -> CGFloat {
        let base = underlayMode == .leaderboard ? 0 : UIScreen.screenWidth
        let drag =
            (underlayMode == .list && horizontalDragOffset < 0)
                || (underlayMode == .leaderboard && horizontalDragOffset > 0)
            ? horizontalDragOffset
            : 0
        return base + drag
    }

    func homeOffsetY() -> CGFloat {
        let base = underlayMode == .home ? 0 : UIScreen.screenHeight
        let drag =
            (underlayMode == .list && verticalDragOffset < 0)
                || (underlayMode == .home && verticalDragOffset > 0)
            ? verticalDragOffset
            : 0
        return base + drag
    }
}
