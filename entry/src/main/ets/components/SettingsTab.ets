import { router, promptAction } from '@kit.ArkUI'
import { Task, UserPreferences } from 'commons'
import { dataStore } from 'commons'
import { UiTokens } from 'commons'
import { CalDAVService, CalDAVConfig } from 'commons'
import { FeishuSyncService } from 'feature_sync'

@Component
export struct SettingsTab {
  @State settings: UserPreferences = new UserPreferences()
  @State exportDataStr: string = ''
  @State importDataStr: string = ''
  @State dataMsg: string = ''
  @State exportPassword: string = ''
  @State importPassword: string = ''
  @State caldavConfig: CalDAVConfig = { serverUrl: '', username: '', password: '', calendarPath: '' }
  @State caldavMsg: string = ''
  @State feishuAppId: string = ''
  @State feishuAppSecret: string = ''
  @State feishuMsg: string = ''
  @State showSyncSection: boolean = false

  async aboutToAppear() {
    this.settings = await dataStore.getUserPrefs()
    this.caldavConfig = await CalDAVService.getConfig()
    this.feishuAppId = await FeishuSyncService.getAppId()
    this.feishuAppSecret = await FeishuSyncService.getAppSecret()
  }

  async toggleHighContrast() {
    this.settings.highContrast = !this.settings.highContrast
    await dataStore.saveUserPrefs(this.settings)
  }

  async toggleLargeText() {
    this.settings.largeText = !this.settings.largeText
    await dataStore.saveUserPrefs(this.settings)
  }

  async toggleReduceMotion() {
    this.settings.reduceAnimations = !this.settings.reduceAnimations
    await dataStore.saveUserPrefs(this.settings)
  }

  async togglePrepareHints() {
    this.settings.showPrepareHints = !this.settings.showPrepareHints
    await dataStore.saveUserPrefs(this.settings)
  }

  async toggleRetainFacePhotos() {
    this.settings.retainFacePhotos = !this.settings.retainFacePhotos
    await dataStore.saveUserPrefs(this.settings)
  }

  async saveCalDAVConfig() {
    await CalDAVService.setConfig(this.caldavConfig)
    this.caldavMsg = '配置已保存'
  }

  testCalDAVConnection() {
    this.caldavMsg = '正在测试连接...'
    CalDAVService.testConnection(this.caldavConfig, (success: boolean, msg: string) => {
      this.caldavMsg = msg
      promptAction.showToast({ message: msg })
    })
  }

  async saveFeishuConfig() {
    await FeishuSyncService.setAppId(this.feishuAppId.trim())
    await FeishuSyncService.setAppSecret(this.feishuAppSecret.trim())
    this.feishuMsg = '配置已保存'
  }

  testFeishuConnection() {
    this.feishuMsg = '正在连接飞书...'
    FeishuSyncService.testConnection((success: boolean, msg: string) => {
      this.feishuMsg = msg
    })
  }

  async syncFeishuEvents() {
    this.feishuMsg = '正在同步飞书日程...'
    FeishuSyncService.fetchCalendarEvents(async (tasks: Task[], msg: string) => {
      if (tasks.length === 0) {
        this.feishuMsg = msg
        return
      }
      const result = await dataStore.syncExternalTasks(tasks, 'feishu')
      this.feishuMsg = `同步成功：新增 ${result.added} 个，更新 ${result.updated} 个日程`
    })
  }

  async exportDataFn() {
    this.exportDataStr = await dataStore.exportAll(this.exportPassword)
    this.dataMsg = this.exportPassword ? '数据已加密导出，请复制保存' : '数据已导出到下方文本框，请复制保存'
  }

  showPlaintextExportWarning() {
    AlertDialog.show({
      title: '安全警告',
      message: '您未设置导出密码，备份数据将以明文形式保存。任何人获取该文本即可读取您的全部日程、心情记录等数据。建议设置密码后再导出。',
      primaryButton: {
        value: '仍要导出',
        action: async () => { await this.exportDataFn() }
      },
      secondaryButton: {
        value: '取消',
        action: () => {}
      }
    })
  }

  async importDataFn() {
    if (!this.importDataStr.trim()) {
      this.dataMsg = '请先粘贴备份数据'
      return
    }
    try {
      await dataStore.importAll(this.importDataStr.trim(), 'overwrite', this.importPassword)
      this.dataMsg = '数据恢复成功'
      this.importDataStr = ''
      this.importPassword = ''
    } catch (e) {
      this.dataMsg = '恢复失败，请检查数据格式或密码'
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

            Divider().strokeWidth(0.5).color(UiTokens.divider).margin({ left: 14 })

            this.SettingRow(
              '保留面部照片',
              '心情识别后保存拍摄的照片',
              this.settings.retainFacePhotos,
              () => { this.toggleRetainFacePhotos() }
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
              router.pushUrl({ url: '@bundle:com.atomicservice.6917603804064535609/feature_course/ets/pages/CourseSchedulePage' })
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
              router.pushUrl({ url: '@bundle:com.atomicservice.6917603804064535609/feature_course/ets/pages/CourseImportPage' })
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
              router.pushUrl({ url: '@bundle:com.atomicservice.6917603804064535609/feature_wellness/ets/pages/WellnessView' })
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

        // External sync (collapsible)
        Column({ space: UiTokens.gapM }) {
          Row() {
            Text('外部日历同步')
              .fontSize(this.sectionTitle())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .layoutWeight(1)

            Text(this.showSyncSection ? '∧' : '∨')
              .fontSize(this.baseFont())
              .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
          }
          .width('100%')
          .padding(14)
          .backgroundColor(UiTokens.bgCard)
          .borderRadius(UiTokens.radiusXL)
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            this.showSyncSection = !this.showSyncSection
          })

          if (this.showSyncSection) {
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

                  Button('测试连接')
                    .layoutWeight(1)
                    .height(40)
                    .fontSize(this.baseFont())
                    .fontColor(UiTokens.textInverse)
                    .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                    .borderRadius(UiTokens.radiusXL)
                    .onClick(() => { this.testFeishuConnection() })
                }
                .width('100%')

                Button('同步飞书日程')
                  .width('100%')
                  .height(40)
                  .fontSize(this.baseFont())
                  .fontColor(UiTokens.textInverse)
                  .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                  .borderRadius(UiTokens.radiusXL)
                  .onClick(() => { this.syncFeishuEvents() })

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
          }
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
            Text('导出备份')
              .fontSize(this.baseFont())
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            TextInput({ placeholder: '设置导出密码（可选，留空则不加密）', text: $$this.exportPassword })
              .width('100%')
              .height(44)
              .fontSize(this.baseFont())
              .backgroundColor(UiTokens.bgHover)
              .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
              .borderRadius(UiTokens.radiusL)
              .type(InputType.Password)

            Button('导出')
              .width('100%')
              .height(44)
              .fontSize(this.baseFont())
              .fontColor(UiTokens.textInverse)
              .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
              .borderRadius(UiTokens.radiusXL)
              .onClick(() => {
                if (!this.exportPassword || this.exportPassword.length === 0) {
                  this.showPlaintextExportWarning()
                  return
                }
                this.exportDataFn()
              })

            if (this.exportDataStr) {
              TextArea({ text: $$this.exportDataStr })
                .width('100%')
                .height(120)
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusL)
                .enabled(false)
            }

            Divider().color(UiTokens.divider).margin({ top: 8, bottom: 8 })

            Text('恢复备份')
              .fontSize(this.baseFont())
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            TextInput({ placeholder: '恢复密码（如果导出时设了密码）', text: $$this.importPassword })
              .width('100%')
              .height(44)
              .fontSize(this.baseFont())
              .backgroundColor(UiTokens.bgHover)
              .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
              .borderRadius(UiTokens.radiusL)
              .type(InputType.Password)

            TextArea({ placeholder: '在此粘贴备份数据以恢复...', text: $$this.importDataStr })
              .width('100%')
              .height(80)
              .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
              .backgroundColor(UiTokens.bgHover)
              .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
              .borderRadius(UiTokens.radiusL)

            Button('恢复')
              .width('100%')
              .height(44)
              .fontSize(this.baseFont())
              .fontColor(UiTokens.textInverse)
              .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
              .borderRadius(UiTokens.radiusXL)
              .onClick(async () => { await this.importDataFn() })

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
              router.pushUrl({ url: '@bundle:com.atomicservice.6917603804064535609/feature_schedule/ets/pages/RecycleBin' })
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
                  router.pushUrl({ url: '@bundle:com.atomicservice.6917603804064535609/feature_schedule/ets/pages/UserAgreementPage' })
                })
              Text('《隐私政策》')
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .fontColor(UiTokens.brand)
                .layoutWeight(1)
                .textAlign(TextAlign.End)
                .onClick(() => {
                  router.pushUrl({ url: '@bundle:com.atomicservice.6917603804064535609/feature_schedule/ets/pages/PrivacyPolicyPage' })
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
      .padding({
        left: UiTokens.pagePadding,
        right: UiTokens.pagePadding,
        top: 8,
        bottom: UiTokens.pagePadding
      })
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
