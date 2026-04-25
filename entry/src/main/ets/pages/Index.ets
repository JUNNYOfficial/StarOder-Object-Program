import { router } from '@kit.ArkUI'
import { Task, TaskStatus, UserPreferences } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { ScheduleCard } from '../components/ScheduleCard'
import { CalendarTab } from '../components/CalendarTab'
import { TimerTab } from '../components/TimerTab'
import { SettingsTab } from '../components/SettingsTab'
import { UiTokens } from '../design/UiTokens'
import { addDays, todayStr } from '../utils/DateUtils'

@Entry
@Component
struct Index {
  @State tasks: Task[] = []
  @State filteredTasks: Task[] = []
  @State settings: UserPreferences = new UserPreferences()
  @State currentDate: string = ''
  @State greeting: string = ''
  @State searchQuery: string = ''
  @State activeTab: number = 0

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

  prevDay() {
    this.currentDate = addDays(this.currentDate, -1)
    this.loadData()
  }

  nextDay() {
    this.currentDate = addDays(this.currentDate, 1)
    this.loadData()
  }

  goToday() {
    this.currentDate = this.formatDate(new Date())
    this.loadData()
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

          if (this.activeTab === 0) {
            Row({ space: 8 }) {
              Button() {
                Text('<')
                  .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              }
              .width(32)
              .height(32)
              .backgroundColor(UiTokens.bgHover)
              .borderRadius(UiTokens.radiusM)
              .onClick(() => { this.prevDay() })

              Text(this.currentDate)
                .fontSize(this.settings.largeText ? UiTokens.text2XL : UiTokens.textXL)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

              Button() {
                Text('>')
                  .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              }
              .width(32)
              .height(32)
              .backgroundColor(UiTokens.bgHover)
              .borderRadius(UiTokens.radiusM)
              .onClick(() => { this.nextDay() })

              if (this.currentDate !== todayStr()) {
                Button() {
                  Text('回今天')
                    .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                    .fontColor(UiTokens.brand)
                    .fontWeight(FontWeight.Medium)
                }
                .backgroundColor(UiTokens.brandSoft)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .borderRadius(UiTokens.radiusM)
                .onClick(() => { this.goToday() })
              }
            }
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding, top: 20, bottom: 4 })

      // Content
      if (this.activeTab === 0) {
        if (this.filteredTasks.length === 0) {
          Column() {
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
            .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding, top: 8, bottom: 4 })

            Column() {
              Text(this.currentDate === todayStr() ? '今天还没有安排' : '这天还没有安排')
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
          }
          .layoutWeight(1)
        } else {
          List({ space: 0 }) {
            ListItem() {
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
          .padding({ top: 0, bottom: 8 })
        }
      } else if (this.activeTab === 1) {
        CalendarTab()
          .layoutWeight(1)
      } else if (this.activeTab === 2) {
        TimerTab()
          .layoutWeight(1)
      } else if (this.activeTab === 3) {
        SettingsTab()
          .layoutWeight(1)
      }

      // Bottom Navigation
      Row() {
        this.NavItem('今日', 0)
        this.NavItem('日历', 1)

        // 添加（中间突出）
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
        }
        .layoutWeight(1)
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          router.pushUrl({ url: 'pages/AddSchedule' })
        })

        this.NavItem('专注', 2)
        this.NavItem('设置', 3)
      }
      .width('100%')
      .height(72)
      .padding({ left: 16, right: 16 })
      .backgroundColor(UiTokens.bgCard)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPage)
  }

  @Builder
  NavItem(label: string, tabIndex: number) {
    Column() {
      Text(label)
        .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
        .fontColor(this.activeTab === tabIndex
          ? UiTokens.brand
          : (this.settings.highContrast ? '#555555' : UiTokens.textSecondary))
        .fontWeight(this.activeTab === tabIndex ? FontWeight.Medium : FontWeight.Regular)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.activeTab = tabIndex
    })
  }
}
