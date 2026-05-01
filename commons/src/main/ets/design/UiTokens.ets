// 冷调蓝灰配色系统 — 参考 Manatee / Outer Space / Pewter Blue / Metallic Blue / Cool Black
export class UiTokens {
  // ===== 页面层级 =====
  static readonly bgPage: string = '#F4F6F8'      // 极浅冷灰
  static readonly bgCard: string = '#FFFFFF'      // 卡片纯白
  static readonly bgHover: string = '#EDF1F5'     // 悬停/输入背景

  // ===== 文字层级 =====
  static readonly textPrimary: string = '#0D2A67'   // Cool Black — 标题
  static readonly textSecondary: string = '#43484B' // Outer Space — 正文
  static readonly textTertiary: string = '#939EA4'  // Manatee — 辅助文字
  static readonly textInverse: string = '#FFFFFF'

  // ===== 分割线 =====
  static readonly divider: string = '#D5D9DD'

  // ===== 品牌与状态（全部来自配色板） =====
  static readonly brand: string = '#334A75'       // Metallic Blue — 主按钮/选中
  static readonly brandSoft: string = '#E8EEF5'   // Metallic Blue 极淡版 — 选中背景

  static readonly done: string = '#84B0C1'        // Pewter Blue — 已完成
  static readonly active: string = '#334A75'      // Metallic Blue — 进行中
  static readonly paused: string = '#939EA4'      // Manatee — 已暂停
  static readonly todo: string = '#939EA4'        // Manatee — 待开始
  static readonly error: string = '#E74C3C'       // 错误/删除

  // ===== 高对比度模式 =====
  static readonly hcText: string = '#000000'
  static readonly hcBg: string = '#FFFFFF'
  static readonly hcBorder: string = '#000000'

  // ===== 间距 =====
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
  static readonly textS: number = 13
  static readonly textM: number = 15
  static readonly textL: number = 17
  static readonly textXL: number = 20
  static readonly text2XL: number = 28
}
