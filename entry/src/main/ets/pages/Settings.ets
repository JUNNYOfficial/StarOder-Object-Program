import { router } from '@kit.ArkUI'
import { common, Want } from '@kit.AbilityKit'
import { UserPreferences } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { FeishuSyncService } from '../services/FeishuSyncService'
import { UiTokens } from '../design/UiTokens'

@Entry
@Component
struct Settings {
  @State settings: UserPreferences = new UserPreferences()
  @State feishuAppId: string = ''
  @State feishuAppSecret: string = ''
  @State feishuConnected: boolean = false
  @State feishuMsg: string = ''

  aboutToAppear() {
    this.settings = dataStore.getUserPrefs()
    this.loadFeishuStatus()
  }

  loadFeishuStatus() {
    this.feishuAppId = FeishuSyncService.getAppId()
    this.feishuAppSecret = FeishuSyncService.getAppSecret()
    this.feishuConnected = FeishuSyncService.isAuthorized()
  }

  saveFeishuConfig() {
    FeishuSyncService.setAppId(this.feishuAppId.trim())
    FeishuSyncService.setAppSecret(this.feishuAppSecret.trim())
    this.loadFeishuStatus()
  }

  connectFeishu() {
    if (!FeishuSyncService.isConfigured()) {
      this.feishuMsg = '请先填写 App ID 和 App Secret'
      return
    }
    const context = getContext(this) as common.UIAbilityContext
    const want: Want = {
      action: 'ohos.want.action.viewData',
      uri: FeishuSyncService.getAuthUrl()
    }
    context.startAbility(want)
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

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  private sectionTitle(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  build() {
    Column() {
      // Header
      Row() {
        Button() {
          Text('返回')
            .fontSize(this.baseFont())
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
        }
        .backgroundColor('transparent')
        .onClick(() => {
          router.back()
        })

        Text('设置')
          .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

        Row().width(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(UiTokens.bgCard)

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
              // High contrast
              this.SettingRow(
                '高对比度',
                '提高文字和背景的对比',
                this.settings.highContrast,
                () => { this.toggleHighContrast() }
              )

              if (!this.settings.highContrast) {
                Divider().strokeWidth(0.5).color(UiTokens.divider).margin({ left: 14 })
              }

              // Large text
              this.SettingRow(
                '大字体',
                '增大所有文字显示',
                this.settings.largeText,
                () => { this.toggleLargeText() }
              )

              if (!this.settings.highContrast) {
                Divider().strokeWidth(0.5).color(UiTokens.divider).margin({ left: 14 })
              }

              // Reduce motion
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
              if (!FeishuSyncService.isConfigured()) {
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
                    Button('连接飞书')
                      .width('100%')
                      .height(48)
                      .fontSize(this.baseFont())
                      .fontColor(UiTokens.textInverse)
                      .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                      .borderRadius(UiTokens.radiusXL)
                      .onClick(() => {
                        this.connectFeishu()
                      })
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
    .width('100%')
    .height('100%')
    .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPage)
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
