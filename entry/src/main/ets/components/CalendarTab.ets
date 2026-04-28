import { Task, UserPreferences, TaskStatus } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { ScheduleCard } from './ScheduleCard'
import { UiTokens } from '../design/UiTokens'
import { router } from '@kit.ArkUI'
import { CourseScheduleState, Course, WeekType } from '../models/CourseModels'
import { formatDate, formatYMD } from '../utils/DateUtils'
import { getCourseTimeText } from '../utils/UiHelper'

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

@Component
export struct CalendarTab {
  @State settings: UserPreferences = new UserPreferences()
  @State currentYear: number = 0
  @State currentMonth: number = 0
  @State selectedDate: string = ''
  @State todayStr: string = ''
  @State calendarDays: CalendarDay[] = []
  @State dayTasks: Task[] = []
  @State dayCourses: Course[] = []
  @State courseState: CourseScheduleState = new CourseScheduleState()
  @State monthNames: string[] = ['一月', '二月', '三月', '四月', '五月', '六月', '七月', '八月', '九月', '十月', '十一月', '十二月']
  @State weekdayLabels: string[] = ['一', '二', '三', '四', '五', '六', '日']

  aboutToAppear() {
    this.settings = dataStore.getUserPrefs()
    this.courseState = dataStore.getCourseState()
    const now = new Date()
    this.currentYear = now.getFullYear()
    this.currentMonth = now.getMonth() + 1
    this.todayStr = formatDate(now)
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

    // 合并课程统计
    if (this.courseState.courses.length > 0 && this.courseState.semesterStartDate) {
      const start = new Date(this.courseState.semesterStartDate)
      for (let d = 1; d <= daysInMonth; d++) {
        const dateStr = formatYMD(this.currentYear, this.currentMonth, d)
        const date = new Date(dateStr)
        const diffDays = Math.floor((date.getTime() - start.getTime()) / (24 * 60 * 60 * 1000))
        const week = Math.floor(diffDays / 7) + 1
        if (week >= 1 && week <= this.courseState.totalWeeks) {
          const dayOfWeek = date.getDay() === 0 ? 7 : date.getDay()
          let courseCount = 0
          for (let i = 0; i < this.courseState.courses.length; i++) {
            const c = this.courseState.courses[i]
            if (c.dayOfWeek !== dayOfWeek) continue
            if (week < c.startWeek || week > c.endWeek) continue
            if (c.weekType === WeekType.ODD && week % 2 === 0) continue
            if (c.weekType === WeekType.EVEN && week % 2 === 1) continue
            courseCount++
          }
          if (courseCount > 0) {
            const prev = taskCountByDate[dateStr]
            taskCountByDate[dateStr] = prev ? prev + courseCount : courseCount
          }
        }
      }
    }

    const days: CalendarDay[] = []
    for (let i = 0; i < offset; i++) {
      days.push(new CalendarDay('', 0, false, false, 0))
    }
    for (let d = 1; d <= daysInMonth; d++) {
      const dateStr = formatYMD(this.currentYear, this.currentMonth, d)
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
    this.dayCourses = this.getCoursesForDate(this.selectedDate)
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
      this.loadDayTasks()
    }
  }

  private getCoursesForDate(dateStr: string): Course[] {
    const state = this.courseState
    if (state.courses.length === 0 || !state.semesterStartDate) return []
    const date = new Date(dateStr)
    const start = new Date(state.semesterStartDate)
    const diffDays = Math.floor((date.getTime() - start.getTime()) / (24 * 60 * 60 * 1000))
    const week = Math.floor(diffDays / 7) + 1
    if (week < 1 || week > state.totalWeeks) return []
    const dayOfWeek = date.getDay() === 0 ? 7 : date.getDay()
    const result: Course[] = []
    for (let i = 0; i < state.courses.length; i++) {
      const c = state.courses[i]
      if (c.dayOfWeek !== dayOfWeek) continue
      if (week < c.startWeek || week > c.endWeek) continue
      if (c.weekType === WeekType.ODD && week % 2 === 0) continue
      if (c.weekType === WeekType.EVEN && week % 2 === 1) continue
      result.push(c)
    }
    result.sort((a, b) => a.startSlot - b.startSlot)
    return result
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

            Text(`${this.dayTasks.length + this.dayCourses.length} 个日程`)
              .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
              .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)

          if (this.dayTasks.length === 0 && this.dayCourses.length === 0) {
            Column() {
              Text('这天没有安排')
                .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding(32)
            .backgroundColor(UiTokens.bgCard)
            .borderRadius(UiTokens.radiusXL)
          } else {
            Column({ space: 0 }) {
              if (this.dayCourses.length > 0) {
                ForEach(this.dayCourses, (course: Course) => {
                  Row({ space: UiTokens.gapM }) {
                    Column() {
                      Text(getCourseTimeText(course, this.courseState.timeSlots))
                        .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                    }
                    .width(72)
                    .alignItems(HorizontalAlign.Start)

                    Column({ space: 2 }) {
                      Text(course.name)
                        .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')

                      if (course.classroom || course.teacher) {
                        Text(`${course.classroom || ''}${course.teacher ? ' | ' + course.teacher : ''}`)
                          .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                          .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .width('100%')
                      }
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor(course.color + '18')
                  .borderRadius(UiTokens.radiusL)
                  .border({ width: 1, color: course.color + '40' })
                  .margin({ bottom: 8 })
                  .onClick(() => {
                    router.pushUrl({ url: 'pages/CourseSchedulePage' })
                  })
                })
              }

              ForEach(this.dayTasks, (task: Task) => {
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
              }, (task: Task) => task.id)
            }
            .width('100%')
          }
        }
        .width('100%')
        .padding({ bottom: 32 })
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
}
