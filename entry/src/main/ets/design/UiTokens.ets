// Apple Minimal Design System for Neurodiversity
export class UiTokens {
  // ===== Apple 风格颜色 =====
  static readonly bgPage: string = '#F2F2F7'      // 页面背景 极浅灰
  static readonly bgCard: string = '#FFFFFF'      // 卡片纯白
  static readonly bgHover: string = '#F5F5F7'     // 悬停/次级背景

  static readonly textPrimary: string = '#1D1D1F'   // 主文字 近黑
  static readonly textSecondary: string = '#6E6E73' // 次要文字 灰
  static readonly textTertiary: string = '#A1A1A6'  // 三级文字 浅灰
  static readonly textInverse: string = '#FFFFFF'

  static readonly divider: string = '#E5E5EA'       // 极淡分割线

  // 品牌色 — 只用于关键操作
  static readonly brand: string = '#007AFF'
  static readonly brandSoft: string = '#E6F2FF'

  // 状态色 — 只用于文字或极小元素
  static readonly done: string = '#34C759'
  static readonly active: string = '#007AFF'
  static readonly paused: string = '#FF9500'
  static readonly todo: string = '#8E8E93'

  // ===== 高对比度模式 =====
  static readonly hcText: string = '#000000'
  static readonly hcBg: string = '#FFFFFF'
  static readonly hcBorder: string = '#000000'

  // ===== 间距 (更大留白) =====
  static readonly pagePadding: number = 20
  static readonly cardPadding: number = 20
  static readonly gapS: number = 8
  static readonly gapM: number = 12
  static readonly gapL: number = 16
  static readonly gapXL: number = 24

  // ===== 圆角 =====
  static readonly radiusS: number = 8
  static readonly radiusM: number = 12
  static readonly radiusL: number = 16
  static readonly radiusXL: number = 20

  // ===== 字号 =====
  static readonly textXS: number = 12
  static readonly textS: number = 13   // Apple 常用小字号
  static readonly textM: number = 15   // Apple 标准正文
  static readonly textL: number = 17   // Apple 大正文
  static readonly textXL: number = 20
  static readonly text2XL: number = 28 // 大标题

  // ===== 辅助方法 =====
  static textPrimaryColor(hc: boolean): string {
    return hc ? UiTokens.hcText : UiTokens.textPrimary
  }

  static textSecondaryColor(hc: boolean): string {
    return hc ? '#333333' : UiTokens.textSecondary
  }
}
