import { router } from '@kit.ArkUI'
import { Schedule } from '../models/ScheduleModel'
import { AppSettings } from '../models/SettingsModel'
import { storage } from '../utils/StorageUtil'
import { ScheduleCard } from '../components/ScheduleCard'
import { UiTokens } from '../design/UiTokens'

@Entry
@Component
struct Index {
  @State schedules: Schedule[] = []
  @State settings: AppSettings = new AppSettings()
  @State currentDate: string = ''
  @State greeting: string = ''

  aboutToAppear() {
    const now = new Date()
    this.currentDate = this.formatDate(now)
    this.greeting = this.getGreeting(now)
    this.loadData()
  }

  onPageShow() {
    this.loadData()
  }

  loadData() {
    this.settings = storage.getSettings()
    const all = storage.getSchedules()
    this.schedules = all
      .filter(s => s.date === this.currentDate)
      .sort((a, b) => a.startTime.localeCompare(b.startTime))
  }

  formatDate(d: Date): string {
    const y = d.getFullYear()
    const m = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  getGreeting(d: Date): string {
    const h = d.getHours()
    if (h < 6) return '夜深了，注意休息'
    if (h < 9) return '早上好，今天从简单的事开始吧'
    if (h < 12) return '上午好，按自己的节奏来'
    if (h < 14) return '中午好，记得休息一下'
    if (h < 18) return '下午好，已经完成一部分了'
    return '晚上好，准备结束今天吧'
  }

  toggleComplete(schedule: Schedule) {
    const all = storage.getSchedules()
    const idx = all.findIndex(s => s.id === schedule.id)
    if (idx >= 0) {
      all[idx].isCompleted = !all[idx].isCompleted
      storage.saveSchedules(all)
      this.loadData()
    }
  }

  private navFont(): number {
    return this.settings.largeText ? UiTokens.textS : UiTokens.textXS
  }

  build() {
    Column() {
      // Header
      Column() {
        Text(this.greeting)
          .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
          .fontColor(this.settings.highContrast ? '#333333' : UiTokens.textSecondary)
          .margin({ bottom: 4 })

        Row() {
          Text('星序')
            .fontSize(this.settings.largeText ? 28 : 22)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
            .fontWeight(FontWeight.Bold)
            .margin({ right: 8 })

          Text(this.currentDate)
            .fontSize(this.settings.largeText ? UiTokens.text2XL : UiTokens.textXL)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding, top: 16, bottom: 8 })

      // Divider
      Row()
        .width('100%')
        .height(this.settings.highContrast ? 2 : 1)
        .backgroundColor(this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border)

      // Content
      if (this.schedules.length === 0) {
        Column() {
          Text('星序')
            .fontSize(48)
            .fontColor(UiTokens.border)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 16 })
          Text('今天还没有安排')
            .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            .margin({ bottom: 8 })
          Text('点击下方按钮添加第一个日程')
            .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
            .fontColor(this.settings.highContrast ? '#333333' : UiTokens.textSecondary)
            .textAlign(TextAlign.Center)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(32)
      } else {
        List({ space: 0 }) {
          ForEach(this.schedules, (schedule: Schedule) => {
            ListItem() {
              ScheduleCard({
                schedule: schedule,
                settings: this.settings,
                onClickCard: () => {
                  router.pushUrl({ url: 'pages/ScheduleDetail', params: { id: schedule.id } })
                },
                onToggleComplete: () => {
                  this.toggleComplete(schedule)
                }
              })
            }
            .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })
          })
        }
        .width('100%')
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Auto)
        .padding({ top: 8, bottom: 8 })
      }

      // Bottom Navigation
      Row() {
        Column() {
          Button() {
            Text('今日')
              .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
              .fontColor(UiTokens.brand)
              .fontWeight(FontWeight.Medium)
          }
          .type(ButtonType.Circle)
          .backgroundColor('transparent')
          .onClick(() => {
            this.loadData()
          })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Button() {
            Text('+')
              .fontSize(28)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
          }
          .width(this.settings.largeText ? 64 : 56)
          .height(this.settings.largeText ? 64 : 56)
          .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
          .borderRadius(UiTokens.radiusM)
          .onClick(() => {
            router.pushUrl({ url: 'pages/AddSchedule' })
          })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Button() {
            Text('设置')
              .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
              .fontColor(this.settings.highContrast ? '#333333' : UiTokens.textSecondary)
              .fontWeight(FontWeight.Medium)
          }
          .type(ButtonType.Circle)
          .backgroundColor('transparent')
          .onClick(() => {
            router.pushUrl({ url: 'pages/Settings' })
          })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height(this.settings.largeText ? 88 : 72)
      .padding({ left: 24, right: 24 })
      .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgSecondary)
      .border({ width: { top: this.settings.highContrast ? 2 : 1 }, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgSecondary)
  }
}
