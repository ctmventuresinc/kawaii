import SwiftUI

class ColorCombinationsManager: ObservableObject {
    static let shared = ColorCombinationsManager()
    
    @Published var colorCombinations: [(background: String, button: String, inviteButtonColor: String)] = [
        ("#4D9DE1", "#FF5C8D", "#FF5C8D"),      // 1
        ("#FF0095", "#FFEA00", "#FFEA00"),      // 2 - KEEP FILTER
        ("#F5F5F5", "#F03889", "#F03889"),      // 3
        ("#5500CC", "#FF0095", "#FF0095"),      // 4
        ("#E86A58", "#178E96", "#178E96"),      // 5
        ("#A8DADC", "#178E96", "#178E96"),      // 6
        ("#A8DADC", "#FBECCF", "#FBECCF"),      // 7
        ("#33A1FD", "#FA7921", "#FA7921"),      // 8 - KEEP FILTER
        ("#7DE0E6", "#FA7921", "#FA7921"),      // 9
        ("#7DE0E6", "#FF2A93", "#FF2A93"),      // 10
        ("#FF0095", "#77CC00", "#77CC00"),      // 11 - KEEP FILTER
        ("#F9F6F0", "#C19875", "#C19875"),      // 12
        ("#F70000", "#E447D1", "#E447D1")       // 13 - KEEP FILTER
    ]
    
    private init() {}
    
    func shouldApplyColorFilter(for index: Int) -> Bool {
        // Only combinations 2, 8, 11, 13 (1-based) should have color filters
        // In 0-based indexing: 1, 7, 10, 12
        let filterEnabledIndices = [1, 7, 10, 12]
        return filterEnabledIndices.contains(index)
    }
    
    func getRandomCombination() -> (index: Int, combo: (background: String, button: String, inviteButtonColor: String)) {
        let index = Int.random(in: 0..<colorCombinations.count)
        return (index, colorCombinations[index])
    }
}
