// HarmonyOS Design + Neurodiversity-friendly Design System
export class UiTokens {
  // ===== 颜色 =====
  // 品牌
  static readonly brand: string = '#0A59F7'
  static readonly brandSoft: string = '#E8EFFF'
  static readonly confirm: string = '#34C759'
  static readonly warning: string = '#E84026'

  // 文本（Light 模式）
  static readonly textPrimary: string = '#E5000000'
  static readonly textSecondary: string = '#99000000'
  static readonly tertiaryText: string = '#66000000'
  static readonly textInverse: string = '#FFFFFFFF'

  // 背景（Light 模式）
  static readonly bgPrimary: string = '#FFFFFFFF'
  static readonly bgSecondary: string = '#FFF1F3F5'
  static readonly bgTertiary: string = '#FFE5E5EA'

  // 边框与分割
  static readonly border: string = '#FFE5E5EA'
  static readonly divider: string = '#FFF1F3F5'

  // 高对比度
  static readonly hcText: string = '#000000'
  static readonly hcBg: string = '#FFFFFF'
  static readonly hcBorder: string = '#000000'

  // ===== 间距 =====
  static readonly pagePadding: number = 16
  static readonly cardPadding: number = 16
  static readonly gapS: number = 8
  static readonly gapM: number = 12
  static readonly gapL: number = 16

  // ===== 圆角 =====
  static readonly radiusS: number = 8
  static readonly radiusM: number = 12
  static readonly radiusL: number = 16

  // ===== 按钮 =====
  static readonly btnHeight: number = 48
  static readonly btnRadius: number = 12

  // ===== 字号 =====
  static readonly textXS: number = 12
  static readonly textS: number = 14
  static readonly textM: number = 16
  static readonly textL: number = 18
  static readonly textXL: number = 20
  static readonly text2XL: number = 24
}
