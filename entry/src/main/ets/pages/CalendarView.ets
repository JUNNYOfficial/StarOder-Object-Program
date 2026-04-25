import { router } from '@kit.ArkUI'
import { Task, UserPreferences } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { ScheduleCard } from '../components/ScheduleCard'
import { UiTokens } from '../design/UiTokens'

class CalendarDay {
  date: string
  day: number
  isCurrentMonth: boolean
  isToday: boolean
  taskCount: number
  hasTask: boolean

  constructor(date: string, day: number, isCurrentMonth: boolean, isToday: boolean, taskCount: number) {
    this.date = date
    this.day = day
    this.isCurrentMonth = isCurrentMonth
    this.isToday = isToday
    this.taskCount = taskCount
    this.hasTask = taskCount > 0
  }
}

@Entry
@Component
struct CalendarView {
  @State settings: UserPreferences = new UserPreferences()
  @State currentYear: number = 0
  @State currentMonth: number = 0
  @State selectedDate: string = ''
  @State todayStr: string = ''
  @State calendarDays: CalendarDay[] = []
  @State dayTasks: Task[] = []
  @State monthNames: string[] = ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月']
  @State weekdayLabels: string[] = ['一', '二', '三', '四', '五', '六', '日']

  aboutToAppear() {
    this.settings = dataStore.getUserPrefs()
    const now = new Date()
    this.currentYear = now.getFullYear()
    this.currentMonth = now.getMonth() + 1
    this.todayStr = this.formatDate(now)
    this.selectedDate = this.todayStr
    this.generateCalendar()
    this.loadDayTasks()
  }

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  private largeFont(): number {
    return this.settings.largeText ? UiTokens.text2XL : UiTokens.textXL
  }

  private formatDate(d: Date): string {
    const y = d.getFullYear()
    const m = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  private formatYMD(y: number, m: number, d: number): string {
    const ms = String(m).padStart(2, '0')
    const ds = String(d).padStart(2, '0')
    return `${y}-${ms}-${ds}`
  }

  generateCalendar() {
    const firstDay = new Date(this.currentYear, this.currentMonth - 1, 1)
    const startWeekday = firstDay.getDay()
    const offset = (startWeekday + 6) % 7
    const daysInMonth = new Date(this.currentYear, this.currentMonth, 0).getDate()

    const allTasks = dataStore.getActiveTasks()
    const taskCountByDate: Record<string, number> = {}
    for (let i = 0; i < allTasks.length; i++) {
      const d = allTasks[i].date
      const prev = taskCountByDate[d]
      taskCountByDate[d] = prev ? prev + 1 : 1
    }

    const days: CalendarDay[] = []
    for (let i = 0; i < offset; i++) {
      days.push(new CalendarDay('', 0, false, false, 0))
    }
    for (let d = 1; d <= daysInMonth; d++) {
      const dateStr = this.formatYMD(this.currentYear, this.currentMonth, d)
      const count = taskCountByDate[dateStr] ? taskCountByDate[dateStr] : 0
      days.push(new CalendarDay(dateStr, d, true, dateStr === this.todayStr, count))
    }
    while (days.length < 42) {
      days.push(new CalendarDay('', 0, false, false, 0))
    }
    this.calendarDays = days
  }

  loadDayTasks() {
    this.dayTasks = dataStore.getTasksByDate(this.selectedDate)
  }

  prevMonth() {
    if (this.currentMonth === 1) {
      this.currentMonth = 12
      this.currentYear = this.currentYear - 1
    } else {
      this.currentMonth = this.currentMonth - 1
    }
    this.generateCalendar()
  }

  nextMonth() {
    if (this.currentMonth === 12) {
      this.currentMonth = 1
      this.currentYear = this.currentYear + 1
    } else {
      this.currentMonth = this.currentMonth + 1
    }
    this.generateCalendar()
  }

  goToday() {
    const now = new Date()
    this.currentYear = now.getFullYear()
    this.currentMonth = now.getMonth() + 1
    this.selectedDate = this.todayStr
    this.generateCalendar()
    this.loadDayTasks()
  }

  selectDay(day: CalendarDay) {
    if (!day.isCurrentMonth || day.day === 0) return
    this.selectedDate = day.date
    this.loadDayTasks()
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

        Text('日历')
          .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

        Button() {
          Text('今天')
            .fontSize(this.baseFont())
            .fontColor(UiTokens.brand)
            .fontWeight(FontWeight.Medium)
        }
        .backgroundColor('transparent')
        .onClick(() => {
          this.goToday()
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(UiTokens.bgCard)

      Scroll() {
        Column({ space: UiTokens.gapXL }) {
          // Month navigator
          Row() {
            Button() {
              Text('<')
                .fontSize(this.largeFont())
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            }
            .width(44)
            .height(44)
            .backgroundColor(UiTokens.bgHover)
            .borderRadius(UiTokens.radiusL)
            .onClick(() => {
              this.prevMonth()
            })

            Text(`${this.currentYear}年 ${this.monthNames[this.currentMonth - 1]}`)
              .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

            Button() {
              Text('>')
                .fontSize(this.largeFont())
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            }
            .width(44)
            .height(44)
            .backgroundColor(UiTokens.bgHover)
            .borderRadius(UiTokens.radiusL)
            .onClick(() => {
              this.nextMonth()
            })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)

          // Weekday labels
          Row() {
            ForEach(this.weekdayLabels, (label: string) => {
              Text(label)
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
                .fontWeight(FontWeight.Medium)
                .width('14.28%')
                .textAlign(TextAlign.Center)
            })
          }
          .width('100%')

          // Calendar grid
          Grid() {
            ForEach(this.calendarDays, (day: CalendarDay) => {
              GridItem() {
                Column({ space: 4 }) {
                  Text(day.day > 0 ? String(day.day) : '')
                    .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                    .fontWeight(day.isToday ? FontWeight.Bold : FontWeight.Regular)
                    .fontColor(day.isToday
                      ? UiTokens.textInverse
                      : (day.isCurrentMonth
                        ? (this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                        : (this.settings.highContrast ? '#CCCCCC' : UiTokens.textTertiary)))
                    .width(36)
                    .height(36)
                    .textAlign(TextAlign.Center)
                    .backgroundColor(day.isToday
                      ? UiTokens.brand
                      : (this.selectedDate === day.date && day.isCurrentMonth
                        ? UiTokens.brandSoft
                        : 'transparent'))
                    .borderRadius(UiTokens.radiusL)

                  if (day.hasTask) {
                    Row({ space: 2 }) {
                      if (day.taskCount > 0) {
                        Circle()
                          .width(4)
                          .height(4)
                          .fill(day.isCurrentMonth ? UiTokens.brand : UiTokens.divider)
                      }
                      if (day.taskCount > 1) {
                        Circle()
                          .width(4)
                          .height(4)
                          .fill(day.isCurrentMonth ? UiTokens.brand : UiTokens.divider)
                      }
                      if (day.taskCount > 2) {
                        Circle()
                          .width(4)
                          .height(4)
                          .fill(day.isCurrentMonth ? UiTokens.brand : UiTokens.divider)
                      }
                    }
                    .height(4)
                    .justifyContent(FlexAlign.Center)
                  }
                }
                .width('100%')
                .height(56)
                .justifyContent(FlexAlign.Center)
                .backgroundColor(this.selectedDate === day.date && day.isCurrentMonth && !day.isToday
                  ? UiTokens.bgHover
                  : 'transparent')
                .borderRadius(UiTokens.radiusM)
              }
              .onClick(() => {
                this.selectDay(day)
              })
            })
          }
          .width('100%')
          .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
          .rowsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
          .height(360)

          // Selected date tasks
          Column({ space: UiTokens.gapM }) {
            Row() {
              Text(this.selectedDate)
                .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

              Text(`${this.dayTasks.length} 个日程`)
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceBetween)

            if (this.dayTasks.length === 0) {
              Column() {
                Text('这天没有安排')
                  .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                  .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
                  .textAlign(TextAlign.Center)
              }
              .width('100%')
              .padding(32)
              .backgroundColor(UiTokens.bgCard)
              .borderRadius(UiTokens.radiusXL)
            } else {
              Column({ space: 0 }) {
                ForEach(this.dayTasks, (task: Task) => {
                  ScheduleCard({
                    task: task,
                    settings: this.settings,
                    onClickCard: () => {
                      router.pushUrl({ url: 'pages/ScheduleDetail', params: { id: task.id } })
                    },
                    onToggleStatus: () => {}
                  })
                })
              }
              .width('100%')
            }
          }
          .width('100%')
          .padding({ bottom: 32 })
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
}
