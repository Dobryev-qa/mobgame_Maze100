import SwiftUI

/// Central design system for Maze 100 Professional Rebuild
struct Theme {
    
    // MARK: - Colors
    struct Colors {
        static let background = Color(hex: "#050505")
        static let surface = Color(hex: "#121212")
        static let accent = Color(hex: "#007AFF") // Electric Blue
        static let secondaryAccent = Color(hex: "#5856D6") // Cyber Indigo
        
        static let neonBlue = Color(hex: "#00F2FF")
        static let neonPurple = Color(hex: "#BC00FF")
        static let neonGreen = Color(hex: "#39FF14")
        
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textMuted = Color.white.opacity(0.4)
        
        static let wall = Color(hex: "#1A1A1A")
        static let death = Color(hex: "#FF3131")
        static let victory = Color(hex: "#FFD700")
    }
    
    // MARK: - Gradients
    struct Gradients {
        static let primary = LinearGradient(
            colors: [Colors.neonBlue, Colors.secondaryAccent],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cyber = LinearGradient(
            colors: [Colors.neonPurple, Colors.neonBlue],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Typography
    struct Typography {
        static func titleFont(size: CGFloat = 36) -> Font {
            return .system(size: size, weight: .black, design: .rounded)
        }
        
        static func bodyFont(size: CGFloat = 18) -> Font {
            return .system(size: size, weight: .medium, design: .default)
        }
        
        static func hudFont(size: CGFloat = 22) -> Font {
            return .system(size: size, weight: .bold, design: .monospaced)
        }
    }
    
    // MARK: - Biomes
    struct Biome {
        let wall: Color
        let background: Color
        let accent: Color
    }
    
    static func themeForLevel(_ level: Int) -> Biome {
        if level <= 20 {
            // Cyber Neon (Default)
            return Biome(wall: Color(hex: "#1A1A1A"), background: Color(hex: "#050505"), accent: Colors.neonBlue)
        } else if level <= 40 {
            // Ancient Temple (Emerald/Gold)
            return Biome(wall: Color(hex: "#1A2E1A"), background: Color(hex: "#0A120A"), accent: Color(hex: "#39FF14"))
        } else if level <= 60 {
            // Frozen Void (Cyan/White)
            return Biome(wall: Color(hex: "#1A1A2E"), background: Color(hex: "#050510"), accent: Color(hex: "#00F2FF"))
        } else if level <= 80 {
            // Inferno (Red/Orange)
            return Biome(wall: Color(hex: "#2E1A1A"), background: Color(hex: "#120A0A"), accent: Color(hex: "#FF3131"))
        } else {
            // Zenith (Purple/Gold)
            return Biome(wall: Color(hex: "#251A2E"), background: Color(hex: "#0F0510"), accent: Color(hex: "#BC00FF"))
        }
    }
    
    // MARK: - Layout
    struct Layout {
        static let cornerRadius: CGFloat = 16
        static let glassBlur: CGFloat = 20
        static let glassOpacity: CGFloat = 0.15
    }
}

// MARK: - Hex Color Helper for SwiftUI
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
