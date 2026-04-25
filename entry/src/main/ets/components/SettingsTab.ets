import { router, promptAction } from '@kit.ArkUI'
import { UserPreferences } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { FeishuSyncService } from '../services/FeishuSyncService'
import { UiTokens } from '../design/UiTokens'
import { pasteboard } from '@kit.BasicServicesKit'

@Component
export struct SettingsTab {
  @State settings: UserPreferences = new UserPreferences()
  @State feishuAppId: string = 'cli_a966274eeef8dcc8'
  @State feishuAppSecret: string = 'A9ob9MaNUT6RsFMi0udWkfLESJIADjUW'
  @State feishuConnected: boolean = false
  @State feishuConfigured: boolean = false
  @State feishuMsg: string = ''
  @State feishuAuthCode: string = ''
  @State exportDataStr: string = ''
  @State importDataStr: string = ''
  @State dataMsg: string = ''

  aboutToAppear() {
    this.settings = dataStore.getUserPrefs()
    this.loadFeishuStatus()
  }

  loadFeishuStatus() {
    this.feishuAppId = FeishuSyncService.getAppId()
    this.feishuAppSecret = FeishuSyncService.getAppSecret()
    this.feishuConnected = FeishuSyncService.isAuthorized()
    this.feishuConfigured = FeishuSyncService.isConfigured()
  }

  saveFeishuConfig() {
    FeishuSyncService.setAppId(this.feishuAppId.trim())
    FeishuSyncService.setAppSecret(this.feishuAppSecret.trim())
    this.loadFeishuStatus()
    this.feishuMsg = '配置已保存'
  }

  connectFeishu() {
    if (!FeishuSyncService.isConfigured()) {
      this.feishuMsg = '请先填写 App ID 和 App Secret'
      return
    }
    const authUrl = FeishuSyncService.getAuthUrl()
    try {
      const systemPasteboard = pasteboard.getSystemPasteboard()
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, authUrl)
      systemPasteboard.setDataSync(pasteData)
      this.feishuMsg = '授权链接已复制到剪贴板，请粘贴到浏览器打开'
      promptAction.showToast({ message: '链接已复制', duration: 2000 })
    } catch (e) {
      this.feishuMsg = '复制失败，请手动复制下方链接'
    }
  }

  private extractCodeFromUrl(input: string): string {
    // 如果输入是完整 URL，提取 code 参数
    if (input.includes('code=')) {
      try {
        const url = new URL(input)
        const code = url.searchParams.get('code')
        if (code) return code
      } catch (e) {
        // 不是标准 URL，尝试正则提取
        const match = input.match(/[?&]code=([^&]+)/)
        if (match) return match[1]
      }
    }
    return input
  }

  submitAuthCode() {
    const rawInput = this.feishuAuthCode.trim()
    if (!rawInput) {
      this.feishuMsg = '请输入授权码或回调地址'
      return
    }
    const code = this.extractCodeFromUrl(rawInput)
    if (!code || code === rawInput && !rawInput.includes('-')) {
      this.feishuMsg = '无法识别授权码，请检查输入'
      return
    }
    this.feishuMsg = '正在换取令牌...'
    FeishuSyncService.exchangeCodeForToken(code, (success, msg) => {
      if (success) {
        this.feishuMsg = '授权成功！可以同步日程了'
        this.feishuAuthCode = ''
        this.loadFeishuStatus()
      } else {
        this.feishuMsg = `授权失败: ${msg}`
      }
    })
  }

  syncFeishu() {
    this.feishuMsg = '同步中...'
    FeishuSyncService.fetchCalendarEvents((tasks, msg) => {
      if (tasks.length > 0) {
        const all = dataStore.getActiveTasks()
        const existingIds = new Set<string>()
        for (let i = 0; i < all.length; i++) {
          if (all[i].externalId) {
            existingIds.add(all[i].externalId)
          }
        }
        for (let i = 0; i < tasks.length; i++) {
          if (!existingIds.has(tasks[i].externalId)) {
            all.push(tasks[i])
          }
        }
        dataStore.saveTasks(all)
      }
      this.feishuMsg = msg
    })
  }

  disconnectFeishu() {
    FeishuSyncService.clearAuth()
    this.loadFeishuStatus()
    this.feishuMsg = '已断开连接'
  }

  toggleHighContrast() {
    this.settings.highContrast = !this.settings.highContrast
    dataStore.saveUserPrefs(this.settings)
  }

  toggleLargeText() {
    this.settings.largeText = !this.settings.largeText
    dataStore.saveUserPrefs(this.settings)
  }

  toggleReduceMotion() {
    this.settings.reduceAnimations = !this.settings.reduceAnimations
    dataStore.saveUserPrefs(this.settings)
  }

  togglePrepareHints() {
    this.settings.showPrepareHints = !this.settings.showPrepareHints
    dataStore.saveUserPrefs(this.settings)
  }

  exportDataFn() {
    this.exportDataStr = dataStore.exportAll()
    this.dataMsg = '数据已导出到下方文本框，请复制保存'
  }

  importDataFn() {
    if (!this.importDataStr.trim()) {
      this.dataMsg = '请先粘贴备份数据'
      return
    }
    try {
      dataStore.importAll(this.importDataStr.trim(), 'overwrite')
      this.dataMsg = '数据恢复成功'
      this.importDataStr = ''
    } catch (e) {
      this.dataMsg = '恢复失败，请检查数据格式'
    }
  }

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  private sectionTitle(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  build() {
    Scroll() {
      Column({ space: UiTokens.gapXL }) {
        // Accessibility section
        Column({ space: UiTokens.gapM }) {
          Text('无障碍辅助')
            .fontSize(this.sectionTitle())
            .fontWeight(FontWeight.Medium)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            .width('100%')

          Column({ space: 0 }) {
            this.SettingRow(
              '高对比度',
              '提高文字和背景的对比',
              this.settings.highContrast,
              () => { this.toggleHighContrast() }
            )

            if (!this.settings.highContrast) {
              Divider().strokeWidth(0.5).color(UiTokens.divider).margin({ left: 14 })
            }

            this.SettingRow(
              '大字体',
              '增大所有文字显示',
              this.settings.largeText,
              () => { this.toggleLargeText() }
            )

            if (!this.settings.highContrast) {
              Divider().strokeWidth(0.5).color(UiTokens.divider).margin({ left: 14 })
            }

            this.SettingRow(
              '减少动态效果',
              '减弱过渡动画和动效',
              this.settings.reduceAnimations,
              () => { this.toggleReduceMotion() }
            )
          }
          .width('100%')
          .backgroundColor(UiTokens.bgCard)
          .borderRadius(UiTokens.radiusXL)
          .padding({ top: 6, bottom: 6 })
          .shadow({
            radius: this.settings.highContrast ? 0 : 8,
            color: '#0A000000',
            offsetX: 0,
            offsetY: 2
          })
        }
        .width('100%')

        // Display section
        Column({ space: UiTokens.gapM }) {
          Text('显示选项')
            .fontSize(this.sectionTitle())
            .fontWeight(FontWeight.Medium)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            .width('100%')

          Column({ space: 0 }) {
            this.SettingRow(
              '显示准备提示',
              '在日程列表中显示准备事项',
              this.settings.showPrepareHints,
              () => { this.togglePrepareHints() }
            )
          }
          .width('100%')
          .backgroundColor(UiTokens.bgCard)
          .borderRadius(UiTokens.radiusXL)
          .padding({ top: 6, bottom: 6 })
          .shadow({
            radius: this.settings.highContrast ? 0 : 8,
            color: '#0A000000',
            offsetX: 0,
            offsetY: 2
          })
        }
        .width('100%')

        // Feishu sync
        Column({ space: UiTokens.gapM }) {
          Text('飞书同步')
            .fontSize(this.sectionTitle())
            .fontWeight(FontWeight.Medium)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            .width('100%')

          Column({ space: UiTokens.gapM }) {
            if (!this.feishuConfigured) {
              Column({ space: UiTokens.gapS }) {
                TextInput({ placeholder: '飞书 App ID', text: $$this.feishuAppId })
                  .width('100%')
                  .height(44)
                  .fontSize(this.baseFont())
                  .backgroundColor(UiTokens.bgHover)
                  .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                  .borderRadius(UiTokens.radiusL)

                TextInput({ placeholder: '飞书 App Secret', text: $$this.feishuAppSecret })
                  .width('100%')
                  .height(44)
                  .fontSize(this.baseFont())
                  .backgroundColor(UiTokens.bgHover)
                  .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                  .borderRadius(UiTokens.radiusL)

                Button('保存配置')
                  .width('100%')
                  .height(44)
                  .fontSize(this.baseFont())
                  .fontColor(UiTokens.textInverse)
                  .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                  .borderRadius(UiTokens.radiusL)
                  .onClick(() => {
                    this.saveFeishuConfig()
                  })
              }
              .width('100%')
            } else {
              Column({ space: UiTokens.gapM }) {
                if (!this.feishuConnected) {
                  Column({ space: UiTokens.gapM }) {
                    Button('1. 复制授权链接')
                      .width('100%')
                      .height(48)
                      .fontSize(this.baseFont())
                      .fontColor(UiTokens.textInverse)
                      .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                      .borderRadius(UiTokens.radiusXL)
                      .onClick(() => {
                        this.connectFeishu()
                      })

                    Text('去浏览器粘贴链接，完成飞书登录授权')
                      .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                      .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
                      .width('100%')
                      .textAlign(TextAlign.Center)

                    // 授权链接预览
                    Text(FeishuSyncService.getAuthUrl())
                      .fontSize(this.settings.largeText ? UiTokens.textS : 11)
                      .fontColor(UiTokens.brand)
                      .width('100%')
                      .padding(10)
                      .backgroundColor(UiTokens.bgHover)
                      .borderRadius(UiTokens.radiusM)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Divider().strokeWidth(0.5).color(UiTokens.divider).width('100%')

                    Text('2. 粘贴浏览器地址栏的链接（自动提取授权码）')
                      .fontSize(this.baseFont())
                      .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                      .width('100%')

                    TextInput({ placeholder: '粘贴完整地址或只贴授权码', text: $$this.feishuAuthCode })
                      .width('100%')
                      .height(44)
                      .fontSize(this.baseFont())
                      .backgroundColor(UiTokens.bgHover)
                      .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                      .borderRadius(UiTokens.radiusL)

                    Button('3. 提交授权码')
                      .width('100%')
                      .height(44)
                      .fontSize(this.baseFont())
                      .fontColor(UiTokens.textInverse)
                      .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                      .borderRadius(UiTokens.radiusL)
                      .onClick(() => {
                        this.submitAuthCode()
                      })
                  }
                  .width('100%')
                } else {
                  Row({ space: UiTokens.gapM }) {
                    Button('同步日程')
                      .layoutWeight(1)
                      .height(48)
                      .fontSize(this.baseFont())
                      .fontColor(UiTokens.textInverse)
                      .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                      .borderRadius(UiTokens.radiusXL)
                      .onClick(() => {
                        this.syncFeishu()
                      })

                    Button('断开连接')
                      .layoutWeight(1)
                      .height(48)
                      .fontSize(this.baseFont())
                      .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textSecondary)
                      .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgHover)
                      .borderRadius(UiTokens.radiusXL)
                      .onClick(() => {
                        this.disconnectFeishu()
                      })
                  }
                  .width('100%')
                }

                if (this.feishuMsg) {
                  Text(this.feishuMsg)
                    .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                    .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
                    .width('100%')
                    .textAlign(TextAlign.Center)
                }
              }
              .width('100%')
            }
          }
          .width('100%')
          .padding(UiTokens.cardPadding)
          .backgroundColor(UiTokens.bgCard)
          .borderRadius(UiTokens.radiusXL)
          .shadow({
            radius: this.settings.highContrast ? 0 : 8,
            color: '#0A000000',
            offsetX: 0,
            offsetY: 2
          })
        }
        .width('100%')

        // Course import
        Column({ space: UiTokens.gapM }) {
          Text('导入课表')
            .fontSize(this.sectionTitle())
            .fontWeight(FontWeight.Medium)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            .width('100%')

          Column() {
            Row() {
              Text('从 CSV 格式导入本周课表')
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .layoutWeight(1)

              Text('>')
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
            }
            .width('100%')
            .padding(14)
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              router.pushUrl({ url: 'pages/CourseImportPage' })
            })
          }
          .width('100%')
          .backgroundColor(UiTokens.bgCard)
          .borderRadius(UiTokens.radiusXL)
          .shadow({
            radius: this.settings.highContrast ? 0 : 8,
            color: '#0A000000',
            offsetX: 0,
            offsetY: 2
          })
        }
        .width('100%')

        // Data review
        Column({ space: UiTokens.gapM }) {
          Text('数据回顾')
            .fontSize(this.sectionTitle())
            .fontWeight(FontWeight.Medium)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            .width('100%')

          Column() {
            Row() {
              Text('查看能量、专注与情绪统计')
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .layoutWeight(1)

              Text('>')
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
            }
            .width('100%')
            .padding(14)
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              router.pushUrl({ url: 'pages/WellnessView' })
            })
          }
          .width('100%')
          .backgroundColor(UiTokens.bgCard)
          .borderRadius(UiTokens.radiusXL)
          .shadow({
            radius: this.settings.highContrast ? 0 : 8,
            color: '#0A000000',
            offsetX: 0,
            offsetY: 2
          })
        }
        .width('100%')

        // Data management
        Column({ space: UiTokens.gapM }) {
          Text('数据管理')
            .fontSize(this.sectionTitle())
            .fontWeight(FontWeight.Medium)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            .width('100%')

          Column({ space: UiTokens.gapM }) {
            Row({ space: UiTokens.gapM }) {
              Button('导出备份')
                .layoutWeight(1)
                .height(44)
                .fontSize(this.baseFont())
                .fontColor(UiTokens.textInverse)
                .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                .borderRadius(UiTokens.radiusXL)
                .onClick(() => { this.exportDataFn() })

              Button('恢复备份')
                .layoutWeight(1)
                .height(44)
                .fontSize(this.baseFont())
                .fontColor(UiTokens.textInverse)
                .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                .borderRadius(UiTokens.radiusXL)
                .onClick(() => { this.importDataFn() })
            }
            .width('100%')

            if (this.exportDataStr) {
              TextArea({ text: $$this.exportDataStr })
                .width('100%')
                .height(120)
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusL)
                .enabled(false)
            }

            TextArea({ placeholder: '在此粘贴备份数据以恢复...', text: $$this.importDataStr })
              .width('100%')
              .height(80)
              .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
              .backgroundColor(UiTokens.bgHover)
              .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
              .borderRadius(UiTokens.radiusL)

            if (this.dataMsg) {
              Text(this.dataMsg)
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
                .width('100%')
                .textAlign(TextAlign.Center)
            }
          }
          .width('100%')
          .padding(UiTokens.cardPadding)
          .backgroundColor(UiTokens.bgCard)
          .borderRadius(UiTokens.radiusXL)
          .shadow({
            radius: this.settings.highContrast ? 0 : 8,
            color: '#0A000000',
            offsetX: 0,
            offsetY: 2
          })
        }
        .width('100%')

        // Recycle bin
        Column({ space: UiTokens.gapM }) {
          Text('回收站')
            .fontSize(this.sectionTitle())
            .fontWeight(FontWeight.Medium)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            .width('100%')

          Column() {
            Row() {
              Text('查看已删除的日程')
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .layoutWeight(1)

              Text('>')
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
            }
            .width('100%')
            .padding(14)
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              router.pushUrl({ url: 'pages/RecycleBin' })
            })
          }
          .width('100%')
          .backgroundColor(UiTokens.bgCard)
          .borderRadius(UiTokens.radiusXL)
          .shadow({
            radius: this.settings.highContrast ? 0 : 8,
            color: '#0A000000',
            offsetX: 0,
            offsetY: 2
          })
        }
        .width('100%')

        // About
        Column({ space: UiTokens.gapM }) {
          Text('关于')
            .fontSize(this.sectionTitle())
            .fontWeight(FontWeight.Medium)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            .width('100%')

          Column() {
            Row() {
              Text('星序')
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              Text('v1.0.0')
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
            }
            .width('100%')
            .padding(14)
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .width('100%')
          .backgroundColor(UiTokens.bgCard)
          .borderRadius(UiTokens.radiusXL)
          .shadow({
            radius: this.settings.highContrast ? 0 : 8,
            color: '#0A000000',
            offsetX: 0,
            offsetY: 2
          })
        }
        .width('100%')

        // Description
        Text('星序 是一款为神经多样性人士设计的时间管理工具，采用认知友好、非惩罚式的设计理念。')
          .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
          .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding({ top: 8, bottom: 32 })
      }
      .width('100%')
      .padding(UiTokens.pagePadding)
    }
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }

  @Builder
  SettingRow(title: string, desc: string, value: boolean, onToggle: () => void) {
    Row() {
      Column({ space: 2 }) {
        Text(title)
          .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
          .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
        Text(desc)
          .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
          .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor(UiTokens.brand)
        .onChange(() => {
          onToggle()
        })
    }
    .width('100%')
    .padding(14)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }
}
