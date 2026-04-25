import { router } from '@kit.ArkUI'
import { Task, TaskStatus, UserPreferences } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { ScheduleCard } from '../components/ScheduleCard'
import { UiTokens } from '../design/UiTokens'

@Entry
@Component
struct Index {
  @State tasks: Task[] = []
  @State filteredTasks: Task[] = []
  @State settings: UserPreferences = new UserPreferences()
  @State currentDate: string = ''
  @State greeting: string = ''
  @State searchQuery: string = ''

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
    this.settings = dataStore.getUserPrefs()
    this.tasks = dataStore.getTasksByDate(this.currentDate)
    this.applyFilter()
  }

  applyFilter() {
    if (this.searchQuery.length === 0) {
      this.filteredTasks = this.tasks
    } else {
      const q = this.searchQuery.toLowerCase()
      const result: Task[] = []
      for (let i = 0; i < this.tasks.length; i++) {
        if (this.tasks[i].title.toLowerCase().includes(q)) {
          result.push(this.tasks[i])
        }
      }
      this.filteredTasks = result
    }
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

  advanceStatus(task: Task) {
    const all = dataStore.getActiveTasks()
    const idx = all.findIndex(t => t.id === task.id)
    if (idx >= 0) {
      const statusOrder = [TaskStatus.TODO, TaskStatus.STARTED, TaskStatus.MOSTLY, TaskStatus.DONE]
      const currentIdx = statusOrder.indexOf(all[idx].status)
      all[idx].status = statusOrder[(currentIdx + 1) % statusOrder.length]
      all[idx].updatedAt = Date.now()
      dataStore.saveTasks(all)
      this.loadData()
    }
  }

  build() {
    Column() {
      // Header
      Column({ space: 4 }) {
        Text(this.greeting)
          .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
          .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)

        Row() {
          Text('星序')
            .fontSize(this.settings.largeText ? 24 : 20)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
            .fontWeight(FontWeight.Bold)
            .margin({ right: 8 })

          Text(this.currentDate)
            .fontSize(this.settings.largeText ? UiTokens.text2XL : UiTokens.textXL)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

          Row({ space: 8 }) {
            Button() {
              Text('日历')
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .fontColor(UiTokens.brand)
                .fontWeight(FontWeight.Medium)
            }
            .backgroundColor(UiTokens.brandSoft)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(UiTokens.radiusM)
            .onClick(() => {
              router.pushUrl({ url: 'pages/CalendarView' })
            })

            Button() {
              Text('专注')
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .fontColor(UiTokens.brand)
                .fontWeight(FontWeight.Medium)
            }
            .backgroundColor(UiTokens.brandSoft)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(UiTokens.radiusM)
            .onClick(() => {
              router.pushUrl({ url: 'pages/TimerPage' })
            })

            Button() {
              Text('语音')
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .fontColor(UiTokens.brand)
                .fontWeight(FontWeight.Medium)
            }
            .backgroundColor(UiTokens.brandSoft)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(UiTokens.radiusM)
            .onClick(() => {
              router.pushUrl({ url: 'pages/VoiceInputPage' })
            })
          }
          .margin({ left: 12 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row() {
          TextInput({ placeholder: '搜索日程', text: $$this.searchQuery })
            .width('100%')
            .height(40)
            .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
            .backgroundColor(UiTokens.bgHover)
            .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
            .borderRadius(UiTokens.radiusL)
            .padding({ left: 14, right: 14 })
            .onChange(() => {
              this.applyFilter()
            })
        }
        .width('100%')
        .padding({ top: 8, bottom: 4 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding, top: 20, bottom: 4 })

      // Content
      if (this.filteredTasks.length === 0) {
        Column() {
          Text('今天还没有安排')
            .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            .margin({ bottom: 6 })
          Text('点击下方按钮添加第一个日程')
            .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(32)
      } else {
        List({ space: 0 }) {
          ForEach(this.filteredTasks, (task: Task) => {
            ListItem() {
              ScheduleCard({
                task: task,
                settings: this.settings,
                onClickCard: () => {
                  router.pushUrl({ url: 'pages/ScheduleDetail', params: { id: task.id } })
                },
                onToggleStatus: () => {
                  this.advanceStatus(task)
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
              .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
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
              .fontSize(24)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Medium)
          }
          .width(52)
          .height(52)
          .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
          .borderRadius(UiTokens.radiusL)
          .onClick(() => {
            router.pushUrl({ url: 'pages/AddSchedule' })
          })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)

        Column() {
          Button() {
            Text('设置')
              .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
              .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
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
      .height(72)
      .padding({ left: 24, right: 24 })
      .backgroundColor(UiTokens.bgCard)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPage)
  }
}
