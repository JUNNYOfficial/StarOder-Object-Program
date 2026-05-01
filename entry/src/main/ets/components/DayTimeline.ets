import { Task, TaskType, getTypeConfig, UserPreferences, TypeConfig } from 'commons'
import { Course, TimeSlot } from 'commons'
import { UiTokens } from 'commons'
import {
  timeToMinutes, getTaskTimeInfo, getCurrentMinutes, isToday,
  getDayTimeRange, minutesToTime, DayTimeRange, TaskTimeInfo,
  TransitionInfo, getTransitionInfo
} from 'commons'
import { getTaskEnergyCost, EnergySummary } from 'commons'

const HOUR_HEIGHT: number = 60      // 每小时 60dp，1分钟 = 1dp
const MIN_TASK_HEIGHT: number = 52  // 任务卡片最小高度
const TIMELINE_PAD: number = 4      // 任务卡片左右边距

// 柔和过渡预警色 —— 饱和度低，对感官敏感用户友好
const TRANSITION_WARN: string = '#C4B8A0'        // 柔和奶茶色（10-6分钟 预警期）
const TRANSITION_URGENT: string = '#C9A898'      // 柔和暖玫瑰（5-0分钟 紧急期）
const TRANSITION_WARN_BG: string = '#F5F2EC'     // 极淡奶茶背景
const TRANSITION_URGENT_BG: string = '#F5EEEA'   // 极淡玫瑰背景

/**
 * 时间轴上单个任务的位置信息
 */
class TimelineTaskItem {
  task: Task
  offset: number
  height: number
  columnIndex: number

  constructor(task: Task, offset: number, height: number, columnIndex: number = 0) {
    this.task = task
    this.offset = offset
    this.height = height
    this.columnIndex = columnIndex
  }
}

class TimelineCourseItem {
  course: Course
  offset: number
  height: number

  constructor(course: Course, offset: number, height: number) {
    this.course = course
    this.offset = offset
    this.height = height
  }
}

class RawTimelineItem {
  task: Task
  offset: number
  height: number
  endOffset: number
  columnIndex: number

  constructor(task: Task, offset: number, height: number, endOffset: number, columnIndex: number = 0) {
    this.task = task
    this.offset = offset
    this.height = height
    this.endOffset = endOffset
    this.columnIndex = columnIndex
  }
}

class ColumnSlot {
  offset: number
  endOffset: number

  constructor(offset: number, endOffset: number) {
    this.offset = offset
    this.endOffset = endOffset
  }
}

class TransitionBannerInfo {
  show: boolean = false
  message: string = ''
  bgColor: string = ''
}

/**
 * 时间轴专用任务卡片 —— 精简信息，强调时间感知
 */
@Component
struct TimelineTaskCard {
  @Prop task: Task
  @Prop settings: UserPreferences
  @Prop currentDate: string
  onClickCard: () => void = () => {}

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  private smallFont(): number {
    return this.settings.largeText ? UiTokens.textM : UiTokens.textS
  }

  private getInfo(): TaskTimeInfo {
    return getTaskTimeInfo(this.currentDate, this.task.startTime, this.task.endTime)
  }

  private getTypeconfig(): TypeConfig {
    return getTypeConfig(this.task.type)
  }

  private getTransitioninfo(): TransitionInfo {
    return getTransitionInfo(this.task)
  }

  private getLabelcolor(): string {
    const trans = this.getTransitioninfo()
    if (trans.isUrgent) return TRANSITION_URGENT
    if (trans.isWarning) return TRANSITION_WARN
    const info = this.getInfo()
    if (info.isOngoing) return this.getTypeconfig().color
    if (info.isEnded) return UiTokens.textTertiary
    return UiTokens.brand
  }

  private getCardbg(): string {
    if (this.settings.highContrast) return UiTokens.hcBg
    const trans = this.getTransitioninfo()
    if (trans.isUrgent) return TRANSITION_URGENT_BG
    if (trans.isWarning) return TRANSITION_WARN_BG
    const info = this.getInfo()
    if (info.isOngoing) return this.getTypeconfig().softColor
    if (info.isEnded) return UiTokens.bgHover
    return UiTokens.bgCard
  }

  private getTaskborderwidth(): number {
    const trans = this.getTransitioninfo()
    if (trans.isUrgent) return 2
    if (trans.isWarning) return 1.5
    if (this.getInfo().isOngoing) return 1.5
    return 0.5
  }

  private getTaskbordercolor(): string {
    const trans = this.getTransitioninfo()
    if (trans.isUrgent) return TRANSITION_URGENT
    if (trans.isWarning) return TRANSITION_WARN
    if (this.getInfo().isOngoing) return this.getTypeconfig().color
    if (this.settings.highContrast) return UiTokens.hcBorder
    return UiTokens.divider
  }

  private getTimelabel(): string {
    const trans = this.getTransitioninfo()
    if (trans.isUrgent) return `还有 ${trans.minutesToEnd} 分钟 · 即将切换`
    if (trans.isWarning) return `还有 ${trans.minutesToEnd} 分钟 · 准备切换`
    return this.getInfo().relativeLabel
  }

  build() {
    Column({ space: 2 }) {
      // 标题 + 相对时间
      Row({ space: 4 }) {
        Text(this.task.title)
          .fontSize(this.baseFont())
          .fontWeight(FontWeight.Medium)
          .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(this.getTimelabel())
          .fontSize(UiTokens.textXS)
          .fontColor(this.settings.highContrast ? UiTokens.hcText : this.getLabelcolor())
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')

      // 具体时间范围 + 持续时长
      Row({ space: 4 }) {
        Text(`${this.task.startTime || ''} - ${this.task.endTime || ''}`)
          .fontSize(this.smallFont())
          .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)

        if (this.task.duration > 0) {
          Text(`· ${this.task.duration}分钟`)
            .fontSize(this.smallFont())
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
        }
      }
      .width('100%')

      // 能量消耗提示（社交任务）
      if (this.task.type === TaskType.SOCIAL) {
        Row({ space: 4 }) {
          Text('能量消耗: 高')
            .fontSize(UiTokens.textXS)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : '#C9A898')
            .fontWeight(FontWeight.Medium)

          Text('· 建议前后留恢复时间')
            .fontSize(UiTokens.textXS)
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
        }
        .width('100%')
      }

      // 进行中任务：时间流逝进度条
      if (this.getInfo().isOngoing) {
        Stack() {
          Row()
            .width('100%')
            .height(3)
            .backgroundColor(this.settings.highContrast ? '#CCCCCC' : UiTokens.divider)
            .borderRadius(2)
          Row()
            .width(`${this.getInfo().progressPercent}%`)
            .height(3)
            .backgroundColor(this.settings.highContrast ? UiTokens.hcText : this.getTypeconfig().color)
            .borderRadius(2)
        }
        .width('100%')
        .height(3)
      }
    }
    .width('100%')
    .padding(8)
    .backgroundColor(this.getCardbg())
    .borderRadius(UiTokens.radiusM)
    .border({
      width: this.getTaskborderwidth(),
      color: this.getTaskbordercolor()
    })
    .opacity(this.getInfo().isEnded ? 0.55 : 1)
    .onClick(() => this.onClickCard())
  }
}

/**
 * 今日时间轴组件 —— 为时间盲用户设计的可视化日程视图
 */
@Component
export struct DayTimeline {
  @Prop tasks: Task[]
  @Prop settings: UserPreferences
  @Prop currentDate: string
  @Prop courses: Course[] = []
  @Prop courseTimeSlots: TimeSlot[] = []
  @Prop energySummary: EnergySummary = new EnergySummary(8, 0, 0, 0)
  onClickTask: (task: Task) => void = () => {}
  onClickCourse: (course: Course) => void = () => {}

  @State nowMinutes: number = getCurrentMinutes()
  private timer: number = -1
  private scroller: Scroller = new Scroller()
  private isActive: boolean = false

  aboutToAppear(): void {
    this.isActive = true
    this.updateNow()
    // 每 30 秒更新一次，刷新相对时间和指针位置
    this.timer = setInterval(() => {
      if (this.isActive) {
        this.updateNow()
      }
    }, 30000)
    // 首次显示时自动滚动到"现在"位置
    setTimeout(() => {
      if (this.isActive) {
        this.scrollToNow()
      }
    }, 300)
  }

  aboutToDisappear(): void {
    this.isActive = false
    if (this.timer !== -1) {
      clearInterval(this.timer)
      this.timer = -1
    }
  }

  private updateNow(): void {
    this.nowMinutes = getCurrentMinutes()
  }

  private scrollToNow(): void {
    if (this.getNowoffset() < 0) return
    // 把"现在指针"滚动到屏幕中间偏上，留出 120dp 上方空间
    const targetOffset = Math.max(0, this.getNowoffset() - 120)
    this.scroller.scrollTo({
      xOffset: 0,
      yOffset: targetOffset,
      animation: { duration: 400, curve: Curve.EaseInOut }
    })
  }

  private getTimerange(): DayTimeRange {
    return getDayTimeRange(this.tasks)
  }

  private getStarthour(): number {
    return this.getTimerange().startHour
  }

  private getEndhour(): number {
    return this.getTimerange().endHour
  }

  private getTotalheight(): number {
    return (this.getEndhour() - this.getStarthour()) * HOUR_HEIGHT
  }

  private getHours(): number[] {
    const result: number[] = []
    for (let h = this.getStarthour(); h <= this.getEndhour(); h++) {
      result.push(h)
    }
    return result
  }

  private getToday(): boolean {
    return isToday(this.currentDate)
  }

  private getNowoffset(): number {
    if (!this.getToday()) return -9999
    const h = Math.floor(this.nowMinutes / 60)
    const m = this.nowMinutes % 60
    if (h >= this.getStarthour() && h <= this.getEndhour()) {
      return (h - this.getStarthour()) * HOUR_HEIGHT + m
    }
    return -9999
  }

  private getTimelineitems(): TimelineTaskItem[] {
    const startHour = this.getStarthour()
    const endHour = this.getEndhour()
    const totalHeight = this.getTotalheight()
    const rawItems: RawTimelineItem[] = []

    for (let i = 0; i < this.tasks.length; i++) {
      const task = this.tasks[i]
      if (!task || !task.startTime || !task.endTime) continue

      const startMins = timeToMinutes(task.startTime)
      const endMins = timeToMinutes(task.endTime)
      if (endMins <= startMins) continue

      const taskStartHour = Math.floor(startMins / 60)
      const taskStartMinute = startMins % 60
      const duration = endMins - startMins

      let offset = (taskStartHour - startHour) * HOUR_HEIGHT + taskStartMinute
      let height = Math.max(MIN_TASK_HEIGHT, duration)

      if (offset < 0) {
        height += offset
        offset = 0
      }
      if (offset + height > totalHeight) {
        height = totalHeight - offset
      }
      if (height < MIN_TASK_HEIGHT) {
        height = MIN_TASK_HEIGHT
      }

      rawItems.push(new RawTimelineItem(task, offset, height, offset + height, 0))
    }

    // 检测重叠，分配列（最多两列）
    const column0Items: ColumnSlot[] = []
    const column1Items: ColumnSlot[] = []

    for (let i = 0; i < rawItems.length; i++) {
      const curr = rawItems[i]
      let canPlaceColumn0 = true

      for (let j = 0; j < column0Items.length; j++) {
        const prev = column0Items[j]
        if (curr.offset < prev.endOffset && curr.endOffset > prev.offset) {
          canPlaceColumn0 = false
          break
        }
      }

      if (canPlaceColumn0) {
        curr.columnIndex = 0
        column0Items.push(new ColumnSlot(curr.offset, curr.endOffset))
      } else {
        curr.columnIndex = 1
        column1Items.push(new ColumnSlot(curr.offset, curr.endOffset))
      }
    }

    const items: TimelineTaskItem[] = []
    for (let i = 0; i < rawItems.length; i++) {
      const r = rawItems[i]
      items.push(new TimelineTaskItem(r.task, r.offset, r.height, r.columnIndex))
    }

    return items
  }

  private getCoursetimelineitems(): TimelineCourseItem[] {
    const result: TimelineCourseItem[] = []
    if (!this.courses || !this.courseTimeSlots) return result
    if (this.courses.length === 0 || this.courseTimeSlots.length === 0) return result

    const startHour = this.getStarthour()

    for (let i = 0; i < this.courses.length; i++) {
      const course = this.courses[i]
      if (!course) continue
      const slots = this.courseTimeSlots

      if (course.startSlot < 1 || course.startSlot > slots.length) continue
      const startSlot = slots[course.startSlot - 1]
      const endSlotIdx = course.startSlot + course.slotCount - 2
      if (endSlotIdx < 0 || endSlotIdx >= slots.length) continue
      const endSlot = slots[endSlotIdx]
      if (!startSlot || !endSlot) continue

      const startMins = timeToMinutes(startSlot.startTime)
      const endMins = timeToMinutes(endSlot.endTime)
      if (endMins <= startMins) continue

      const taskStartHour = Math.floor(startMins / 60)
      const taskStartMinute = startMins % 60
      const duration = endMins - startMins

      let offset = (taskStartHour - startHour) * HOUR_HEIGHT + taskStartMinute
      let height = Math.max(MIN_TASK_HEIGHT, duration)

      if (offset < 0) {
        height += offset
        offset = 0
      }
      if (offset + height > this.getTotalheight()) {
        height = this.getTotalheight() - offset
      }
      if (height < MIN_TASK_HEIGHT) {
        height = MIN_TASK_HEIGHT
      }

      result.push(new TimelineCourseItem(course, offset, height))
    }

    return result
  }

  private getAlldaytasks(): Task[] {
    const result: Task[] = []
    if (!this.tasks) return result
    for (let i = 0; i < this.tasks.length; i++) {
      const task = this.tasks[i]
      if (!task || !task.startTime || !task.endTime) {
        result.push(task)
      }
    }
    return result
  }

  private getTransitionbanner(): TransitionBannerInfo {
    const result = new TransitionBannerInfo()

    if (!this.getToday() || !this.tasks) return result

    // 找当前进行中的任务
    let ongoingTask: Task | null = null
    let ongoingEndMins = 0

    for (let i = 0; i < this.tasks.length; i++) {
      if (!this.tasks) break
      const task = this.tasks[i]
      if (!task || !task.startTime || !task.endTime) continue
      const startMins = timeToMinutes(task.startTime)
      const endMins = timeToMinutes(task.endTime)
      if (this.nowMinutes >= startMins && this.nowMinutes < endMins) {
        ongoingTask = task
        ongoingEndMins = endMins
        break
      }
    }

    if (!ongoingTask) return result

    const minsToEnd = ongoingEndMins - this.nowMinutes
    if (minsToEnd > 10) return result

    // 找下一个任务
    let nextTask: Task | null = null
    let nextStartMins = Infinity

    for (let i = 0; i < this.tasks.length; i++) {
      if (!this.tasks) break
      const task = this.tasks[i]
      if (!task || !task.startTime || task.id === ongoingTask.id) continue
      const tStart = timeToMinutes(task.startTime)
      if (tStart >= ongoingEndMins && tStart < nextStartMins) {
        nextStartMins = tStart
        nextTask = task
      }
    }

    if (minsToEnd <= 5) {
      result.message = `「${ongoingTask.title}」还有 ${minsToEnd} 分钟结束`
      if (nextTask) {
        result.message += ` · 接下来是「${nextTask.title}」`
      } else {
        result.message += ` · 之后没有安排了`
      }
      result.bgColor = TRANSITION_URGENT_BG
    } else {
      result.message = `「${ongoingTask.title}」还有 ${minsToEnd} 分钟结束`
      if (nextTask) {
        result.message += ` · 准备切换到「${nextTask.title}」`
      }
      result.bgColor = TRANSITION_WARN_BG
    }

    result.show = true
    return result
  }

  private getCourseTimeText(course: Course): string {
    if (!this.courseTimeSlots || this.courseTimeSlots.length === 0) return ''
    const startIdx = course.startSlot - 1
    const endIdx = course.startSlot + course.slotCount - 2
    if (startIdx < 0 || startIdx >= this.courseTimeSlots.length) return ''
    if (endIdx < 0 || endIdx >= this.courseTimeSlots.length) return ''
    return `${this.courseTimeSlots[startIdx].startTime} - ${this.courseTimeSlots[endIdx].endTime}`
  }

  build() {
    Scroll(this.scroller) {
      Column({ space: 0 }) {
        // 能量预算条
        Row({ space: 8 }) {
          Column({ space: 4 }) {
            Row({ space: 6 }) {
              Text('今日能量')
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .fontWeight(FontWeight.Medium)

              Text(`${this.energySummary.net}/${this.energySummary.budget}`)
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .fontColor(this.energySummary.overBudget
                  ? (this.settings.highContrast ? UiTokens.hcText : '#C9A898')
                  : UiTokens.textSecondary)
            }
            .width('100%')

            Stack() {
              Row()
                .width('100%')
                .height(6)
                .backgroundColor(this.settings.highContrast ? '#CCCCCC' : UiTokens.divider)
                .borderRadius(3)
              Row()
                .width(`${Math.min(100, (this.energySummary.net / this.energySummary.budget) * 100)}%`)
                .height(6)
                .backgroundColor(this.energySummary.overBudget
                  ? (this.settings.highContrast ? UiTokens.hcText : '#C9A898')
                  : UiTokens.brand)
                .borderRadius(3)
            }
            .width('100%')
            .height(6)

            if (this.energySummary.overBudget) {
              Text('能量已透支，建议取消或推迟非必要任务')
                .fontSize(UiTokens.textXS)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : '#C9A898')
                .width('100%')
            } else if (this.energySummary.socialCount > 0) {
              Text(`社交任务 ${this.energySummary.socialCount} 个 · 注意安排恢复时间`)
                .fontSize(UiTokens.textXS)
                .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
                .width('100%')
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgCard)
          .borderRadius(UiTokens.radiusM)
        }
        .width('100%')
        .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding, top: 8, bottom: 4 })

        // 全天事项（无精确时间的任务）
        if (this.getAlldaytasks().length > 0) {
          Column({ space: UiTokens.gapS }) {
            Text('全天事项')
              .fontSize(UiTokens.textXS)
              .fontColor(UiTokens.textTertiary)
              .width('100%')

            ForEach(this.getAlldaytasks(), (task: Task) => {
              Row({ space: 6 }) {
                Circle({ width: 6, height: 6 })
                  .fill(this.settings.highContrast ? UiTokens.hcText : getTypeConfig(task.type).color)
                Text(task.title)
                  .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .layoutWeight(1)
              }
              .width('100%')
              .padding({ top: 6, bottom: 6, left: 10, right: 10 })
              .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgCard)
              .borderRadius(UiTokens.radiusM)
              .border({
                width: 0.5,
                color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.divider
              })
              .onClick(() => this.onClickTask(task))
            }, (task: Task) => task.id)
          }
          .width('100%')
          .padding({ bottom: 8 })
        }

        // 时间轴主体
        Row() {
          // 左侧：小时标签列
          Column() {
            if (this.getHours() && this.getHours().length > 0) {
              ForEach(this.getHours(), (hour: number) => {
                Row() {
                  Text(`${String(hour).padStart(2, '0')}:00`)
                    .fontSize(UiTokens.textXS)
                    .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textTertiary)
                    .fontWeight(FontWeight.Medium)
                }
                .width('100%')
                .height(HOUR_HEIGHT)
                .alignItems(VerticalAlign.Top)
                .padding({ top: 2 })
              }, (hour: number) => hour.toString())
            }
          }
          .width(44)

          // 右侧：Stack 层叠区域（刻度线 + 指针 + 任务）
          Stack() {
            // 小时虚线背景
            Column() {
              if (this.getHours() && this.getHours().length > 0) {
                ForEach(this.getHours(), (hour: number) => {
                  Row() {
                    // 空内容，只保留底部虚线边框
                  }
                  .width('100%')
                  .height(HOUR_HEIGHT)
                  .border({
                    width: { bottom: 1 },
                    color: this.settings.highContrast ? '#555555' : UiTokens.divider,
                    style: BorderStyle.Dashed
                  })
                }, (hour: number) => hour.toString())
              }
            }
            .width('100%')
            .height(this.getTotalheight())

            // 现在指针（红色横线 + 圆点）
            if (this.getNowoffset() >= 0) {
              Row({ space: 0 }) {
                Circle({ width: 10, height: 10 })
                  .fill(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                  .margin({ left: -5 })
                Row()
                  .layoutWeight(1)
                  .height(2)
                  .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                  .borderRadius(1)
              }
              .width('100%')
              .height(2)
              .position({ x: 0, y: this.getNowoffset() })
              .zIndex(10)
            }

            // 任务卡片（按时间绝对定位）
            if (this.getTimelineitems() && this.getTimelineitems().length > 0) {
              ForEach(this.getTimelineitems(), (item: TimelineTaskItem) => {
                TimelineTaskCard({
                  task: item.task,
                  settings: this.settings,
                  currentDate: this.currentDate,
                  onClickCard: () => this.onClickTask(item.task)
                })
                  .position({ x: item.columnIndex === 0 ? 0 : '50%', y: item.offset })
                  .width('48%')
                  .height(item.height)
              }, (item: TimelineTaskItem) => item.task.id)
            }

            // 课程卡片
            if (this.getCoursetimelineitems() && this.getCoursetimelineitems().length > 0) {
              ForEach(this.getCoursetimelineitems(), (item: TimelineCourseItem) => {
                Column({ space: 2 }) {
                  Text(item.course.name)
                    .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')

                  if (item.course.classroom || item.course.teacher) {
                    Text(`${item.course.classroom || ''}${item.course.teacher ? ' | ' + item.course.teacher : ''}`)
                      .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                      .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                  }

                  Text(this.getCourseTimeText(item.course))
                    .fontSize(UiTokens.textXS)
                    .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
                    .width('100%')
                }
                .width('100%')
                .padding(8)
                .backgroundColor(item.course.color + '18')
                .borderRadius(UiTokens.radiusM)
                .border({
                  width: 1,
                  color: item.course.color + '40'
                })
                .position({ x: 0, y: item.offset })
                .width('100%')
                .height(item.height)
                .onClick(() => this.onClickCourse(item.course))
              }, (item: TimelineCourseItem) => item.course.id)
            }
          }
          .layoutWeight(1)
          .height(this.getTotalheight())
          .padding({ left: TIMELINE_PAD, right: TIMELINE_PAD })
        }
        .width('100%')

        // 过渡预警提示条
        if (this.getTransitionbanner().show) {
          Row() {
            Text(this.getTransitionbanner().message)
              .fontSize(UiTokens.textXS)
              .fontColor(UiTokens.textSecondary)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .padding({ top: 8, bottom: 8, left: 12, right: 12 })
          .backgroundColor(this.getTransitionbanner().bgColor)
          .borderRadius(UiTokens.radiusM)
          .margin({ bottom: 4 })
        }

        // 底部状态栏
        if (this.getToday()) {
          Row() {
            Circle({ width: 6, height: 6 })
              .fill(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
              .margin({ right: 4 })
            Text(`现在 ${minutesToTime(this.nowMinutes)} · 时间轴每半分钟自动更新`)
              .fontSize(UiTokens.textXS)
              .fontColor(UiTokens.textTertiary)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 10, bottom: 16 })
        } else {
          Row() {
            Text(`${this.currentDate} 的时间安排`)
              .fontSize(UiTokens.textXS)
              .fontColor(UiTokens.textTertiary)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ top: 10, bottom: 16 })
        }
      }
      .width('100%')
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding, top: 8, bottom: 0 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }
}
