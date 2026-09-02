import SwiftUI

// MARK: - 像素奶茶绘制
// 用字符矩阵定义像素画：每个字符一个像素，对应下方调色板。
// 两个画面 frameA/frameB 交替播放形成动效：奶茶晃动 + 眼睛眨眼 + 吸管摆动。

enum PixelColor: Character {
    case outline = "#"      // 深棕描边
    case tea = "T"          // 奶茶主体
    case milk = "M"         // 奶盖/浅色
    case pearl = "P"        // 珍珠
    case cup = "C"          // 杯身透明部分
    case lid = "L"          // 杯盖
    case straw = "S"        // 吸管
    case strawStripe = "s"  // 吸管条纹
    case face = "F"         // 表情（眼睛腮红）
    case blush = "B"        // 腮红
    case empty = "."
}

let palette: [PixelColor: Color] = [
    .outline: Color(red: 0.36, green: 0.20, blue: 0.12),
    .tea: Color(red: 0.87, green: 0.64, blue: 0.38),
    .milk: Color(red: 0.98, green: 0.94, blue: 0.86),
    .pearl: Color(red: 0.18, green: 0.11, blue: 0.09),
    .cup: Color(red: 0.75, green: 0.88, blue: 0.82).opacity(0.55),
    .lid: Color(red: 0.95, green: 0.95, blue: 0.95),
    .straw: Color(red: 0.92, green: 0.36, blue: 0.36),
    .strawStripe: Color(red: 0.98, green: 0.75, blue: 0.75),
    .face: Color(red: 0.15, green: 0.10, blue: 0.08),
    .blush: Color(red: 0.94, green: 0.48, blue: 0.42).opacity(0.85),
]

// 16 列 x 20 行
let frameA: [String] = [
    "......S.S.......",
    "......SsS.......",
    "......S.S.......",
    "......S.S.......",
    "################",
    "#LLLLLLLLLLLLLL#",
    "#CCCCCCCCCCCCCC#",
    "#CMTTTTTTTTTTMC#",
    "#CTTTTTTTTTTTTC#",
    "#CTTFFFFTFFFTTC#",
    "#CTTFFFFTFFFTTC#",
    "#CTTBBFFEFFBBTC#",
    "#CTTTTTFTTTTTTC#",
    "#CTTPPTTTPPTTTC#",
    "#CTTTTPPTTTTTTC#",
    "#CTTPPTTTPPTTTC#",
    "#CTTPPTTTPPTTTC#",
    "##TTTTTTTTTTTT##",
    ".##TTTTTTTTTT##.",
    "...#############",
]

let frameB: [String] = [
    ".....S.S........",
    ".....SsS........",
    ".....S.S........",
    ".....S.S........",
    "################",
    "#LLLLLLLLLLLLLL#",
    "#CCCCCCCCCCCCCC#",
    "#CMTTTTTTTTTTMC#",
    "#CTTTTTTTTTTTTC#",
    "#CTTFFFFTFFFTTC#",
    "#CTTFFFFTFFFTTC#",
    "#CTTBBFFFFFFBTC#",
    "#CTTTTFFTFFFFTC#",
    "#CTTPPTTTPPTTTC#",
    "#CTTTTPPTTTTTTC#",
    "#CTTPPTTTPPTTTC#",
    "#CTTPPTTTPPTTTC#",
    "##TTTTTTTTTTTT##",
    ".##TTTTTTTTTT##.",
    "...#############",
]

struct PixelMilkTea: View {
    let pixelSize: CGFloat
    @Binding var frame: Int // 0 或 1，用于切换动效帧

    var body: some View {
        let rows = frame == 0 ? frameA : frameB
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 0) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, ch in
                        if let c = PixelColor(rawValue: ch), c != .empty,
                           let color = palette[c] {
                            Rectangle().fill(color).frame(width: pixelSize, height: pixelSize)
                        } else {
                            Rectangle().fill(.clear).frame(width: pixelSize, height: pixelSize)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 动效：左右摇摆

struct AnimatedMilkTea: View {
    var pixelSize: CGFloat = 6
    @State private var wobble = false

    var body: some View {
        ZStack {
            PixelMilkTea(pixelSize: pixelSize, frame: .constant(0))
            StickerBadge()
                .rotationEffect(.degrees(-12))
                .offset(x: 4, y: 44) // 贴在杯身中上部
        }
        .rotationEffect(.degrees(wobble ? 3 : -3), anchor: .bottom)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                wobble = true
            }
        }
    }
}

// MARK: - 「叶师傅」像素风贴纸
// 方角贴纸 + 粗边框 + 色块阴影，模仿像素画的硬边缘风格

struct StickerBadge: View {
    var body: some View {
        Text("叶师傅")
            .font(.system(size: 10, weight: .black))
            .foregroundColor(Color(red: 0.36, green: 0.20, blue: 0.12))
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(Color(red: 0.98, green: 0.94, blue: 0.86))
            .overlay(
                Rectangle()
                    .stroke(Color(red: 0.36, green: 0.20, blue: 0.12), lineWidth: 1.5)
            )
            // 用直角色块当“阴影”，保持硬边像素感
            .background(alignment: .bottomTrailing) {
                Rectangle()
                    .fill(Color(red: 0.36, green: 0.20, blue: 0.12))
                    .offset(x: 2, y: 2)
                    .padding(-1.5)
            }
            .shadow(color: .clear, radius: 0)
    }
}
