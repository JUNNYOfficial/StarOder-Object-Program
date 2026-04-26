import { router, promptAction } from '@kit.ArkUI'
import { UserPreferences } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { UiTokens } from '../design/UiTokens'
import { CalDAVService, CalDAVConfig } from '../services/CalDAVService'
import { FeishuSyncService } from '../services/FeishuSyncService'

@Entry
@Component
struct Settings {
  @State settings: UserPreferences = new UserPreferences()
  @State exportDataStr: string = ''
  @State importDataStr: string = ''
  @State dataMsg: string = ''

  @State caldavConfig: CalDAVConfig = { serverUrl: '', username: '', password: '', calendarPath: '' }
  @State caldavMsg: string = ''
  @State feishuAppId: string = ''
  @State feishuAppSecret: string = ''
  @State feishuMsg: string = ''

  aboutToAppear() {
    this.settings = dataStore.getUserPrefs()
    this.caldavConfig = CalDAVService.getConfig()
    this.feishuAppId = FeishuSyncService.getAppId()
    this.feishuAppSecret = FeishuSyncService.getAppSecret()
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

  saveCalDAVConfig() {
    CalDAVService.setConfig(this.caldavConfig)
    this.caldavMsg = '配置已保存'
  }

  testCalDAVConnection() {
    this.caldavMsg = '正在测试连接...'
    CalDAVService.testConnection(this.caldavConfig, (success, msg) => {
      this.caldavMsg = msg
      promptAction.showToast({ message: msg })
    })
  }

  saveFeishuConfig() {
    FeishuSyncService.setAppId(this.feishuAppId.trim())
    FeishuSyncService.setAppSecret(this.feishuAppSecret.trim())
    this.feishuMsg = '配置已保存'
  }

  testFeishuConnection() {
    this.feishuMsg = '正在连接飞书...'
    FeishuSyncService.exchangeCodeForToken('', (success, msg) => {
      this.feishuMsg = msg
    })
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


          // Course schedule
          Column({ space: UiTokens.gapM }) {
            Text('课程表')
              .fontSize(this.sectionTitle())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            Column({ space: 0 }) {
              Row() {
                Text('查看周课表')
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
                router.pushUrl({ url: 'pages/CourseSchedulePage' })
              })

              Divider().strokeWidth(0.5).color(UiTokens.divider).margin({ left: 14 })

              Row() {
                Text('从 CSV 导入课表')
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

          // CalDAV sync
          Column({ space: UiTokens.gapM }) {
            Text('CalDAV 同步')
              .fontSize(this.sectionTitle())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            Column({ space: UiTokens.gapM }) {
              Text('服务器地址')
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .width('100%')
              TextInput({ placeholder: 'https://dav.example.com/calendars/', text: $$this.caldavConfig.serverUrl })
                .width('100%')
                .height(40)
                .fontSize(this.baseFont())
                .backgroundColor(UiTokens.bgHover)
                .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                .borderRadius(UiTokens.radiusL)

              Text('用户名')
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .width('100%')
              TextInput({ placeholder: 'user@example.com', text: $$this.caldavConfig.username })
                .width('100%')
                .height(40)
                .fontSize(this.baseFont())
                .backgroundColor(UiTokens.bgHover)
                .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                .borderRadius(UiTokens.radiusL)

              Text('密码')
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .width('100%')
              TextInput({ placeholder: '应用专用密码或账户密码', text: $$this.caldavConfig.password })
                .width('100%')
                .height(40)
                .fontSize(this.baseFont())
                .backgroundColor(UiTokens.bgHover)
                .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                .borderRadius(UiTokens.radiusL)
                .type(InputType.Password)

              Text('日历路径')
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .width('100%')
              TextInput({ placeholder: 'https://dav.example.com/calendars/user/calendar/', text: $$this.caldavConfig.calendarPath })
                .width('100%')
                .height(40)
                .fontSize(this.baseFont())
                .backgroundColor(UiTokens.bgHover)
                .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                .borderRadius(UiTokens.radiusL)

              Row({ space: UiTokens.gapM }) {
                Button('保存配置')
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(this.baseFont())
                  .fontColor(UiTokens.textInverse)
                  .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                  .borderRadius(UiTokens.radiusXL)
                  .onClick(() => { this.saveCalDAVConfig() })

                Button('测试连接')
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(this.baseFont())
                  .fontColor(UiTokens.textInverse)
                  .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                  .borderRadius(UiTokens.radiusXL)
                  .onClick(() => { this.testCalDAVConnection() })
              }
              .width('100%')

              if (this.caldavMsg) {
                Text(this.caldavMsg)
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

          // Feishu sync
          Column({ space: UiTokens.gapM }) {
            Text('飞书日历同步')
              .fontSize(this.sectionTitle())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            Column({ space: UiTokens.gapM }) {
              Text('App ID')
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .width('100%')
              TextInput({ placeholder: 'cli_xxxxxxxxxxxxxxxx', text: $$this.feishuAppId })
                .width('100%')
                .height(40)
                .fontSize(this.baseFont())
                .backgroundColor(UiTokens.bgHover)
                .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                .borderRadius(UiTokens.radiusL)

              Text('App Secret')
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .width('100%')
              TextInput({ placeholder: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx', text: $$this.feishuAppSecret })
                .width('100%')
                .height(40)
                .fontSize(this.baseFont())
                .backgroundColor(UiTokens.bgHover)
                .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                .borderRadius(UiTokens.radiusL)
                .type(InputType.Password)

              Row({ space: UiTokens.gapM }) {
                Button('保存配置')
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(this.baseFont())
                  .fontColor(UiTokens.textInverse)
                  .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                  .borderRadius(UiTokens.radiusXL)
                  .onClick(() => { this.saveFeishuConfig() })

                Button('获取授权')
                  .layoutWeight(1)
                  .height(40)
                  .fontSize(this.baseFont())
                  .fontColor(UiTokens.textInverse)
                  .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                  .borderRadius(UiTokens.radiusXL)
                  .onClick(() => { this.testFeishuConnection() })
              }
              .width('100%')

              if (this.feishuMsg) {
                Text(this.feishuMsg)
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

              Row() {
                Text('《用户协议》')
                  .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                  .fontColor(UiTokens.brand)
                  .layoutWeight(1)
                  .onClick(() => {
                    router.pushUrl({ url: 'pages/UserAgreementPage' })
                  })
                Text('《隐私政策》')
                  .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                  .fontColor(UiTokens.brand)
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
                  .onClick(() => {
                    router.pushUrl({ url: 'pages/PrivacyPolicyPage' })
                  })
              }
              .width('100%')
              .padding({ left: 14, right: 14, bottom: 14 })
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
