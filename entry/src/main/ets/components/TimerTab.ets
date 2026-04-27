import { UserPreferences, FocusMode, FocusRecord, getFocusModeConfig, Task } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { UiTokens } from '../design/UiTokens'
import { todayStr } from '../utils/DateUtils'

@Component
export struct TimerTab {
  @State settings: UserPreferences = new UserPreferences()
  @State selectedMode: FocusMode = FocusMode.NORMAL
  @State remainingSeconds: number = 1500
  @State totalSeconds: number = 1500
  @State isRunning: boolean = false
  @State isPaused: boolean = false
  @State startTimeStr: string = ''
  @State showCompleteMsg: boolean = false
  @State completeMsg: string = ''
  @State todayTasks: Task[] = []
  @State selectedTaskId: string = ''
  @State showTaskPicker: boolean = false
  private timerId: number = -1

  aboutToAppear() {
    this.settings = dataStore.getUserPrefs()
    this.resetTimer()
    this.loadTodayTasks()
  }

  private loadTodayTasks() {
    const today = todayStr()
    const tasks = dataStore.getTasksByDate(today)
      .filter(t => t.status !== 'DONE')
      .sort((a, b) => a.startTime.localeCompare(b.startTime))
    this.todayTasks = tasks
  }

  private selectedTaskTitle(): string {
    if (!this.selectedTaskId) return '未关联任务'
    const task = this.todayTasks.find(t => t.id === this.selectedTaskId)
    return task ? task.title : '未关联任务'
  }

  aboutToDisappear() {
    if (this.timerId >= 0) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
  }

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  private largeFont(): number {
    return this.settings.largeText ? UiTokens.text2XL : UiTokens.textXL
  }

  private formatTime(): string {
    const m = Math.floor(this.remainingSeconds / 60)
    const s = this.remainingSeconds % 60
    const ms = String(m).padStart(2, '0')
    const ss = String(s).padStart(2, '0')
    return `${ms}:${ss}`
  }

  private resetTimer() {
    const config = getFocusModeConfig(this.selectedMode)
    this.totalSeconds = config.defaultMinutes * 60
    this.remainingSeconds = this.totalSeconds
    this.isRunning = false
    this.isPaused = false
    this.startTimeStr = ''
  }

  private selectMode(mode: FocusMode) {
    this.selectedMode = mode
    if (!this.isRunning) {
      this.resetTimer()
    }
  }

  private startTimer() {
    if (this.timerId >= 0) return
    this.isRunning = true
    this.isPaused = false
    if (this.startTimeStr === '') {
      this.startTimeStr = new Date().toISOString()
    }
    this.timerId = setInterval(() => {
      if (this.remainingSeconds > 0) {
        this.remainingSeconds = this.remainingSeconds - 1
      } else {
        this.finishTimer()
      }
    }, 1000)
  }

  private pauseTimer() {
    this.isPaused = true
    if (this.timerId >= 0) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
  }

  private stopTimer() {
    if (this.timerId >= 0) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
    this.saveRecord(false)
    this.resetTimer()
  }

  private finishTimer() {
    if (this.timerId >= 0) {
      clearInterval(this.timerId)
      this.timerId = -1
    }
    const actualMinutes = Math.floor((this.totalSeconds - this.remainingSeconds) / 60)
    this.saveRecord(true)
    this.completeMsg = `专注完成！本次专注了 ${actualMinutes} 分钟，做得好。`
    this.showCompleteMsg = true
    this.resetTimer()
    setTimeout(() => {
      this.showCompleteMsg = false
    }, 5000)
  }

  private saveRecord(completed: boolean) {
    const config = getFocusModeConfig(this.selectedMode)
    const record = new FocusRecord(this.selectedTaskId, this.selectedMode, config.defaultMinutes)
    record.actualMinutes = Math.floor((this.totalSeconds - this.remainingSeconds) / 60)
    record.startTime = this.startTimeStr
    record.endTime = new Date().toISOString()
    record.completed = completed
    record.interrupted = !completed
    dataStore.saveFocusRecord(record)
  }

  build() {
    Stack() {
      Scroll() {
      Column({ space: UiTokens.gapXL }) {
        // Timer display
        Column({ space: UiTokens.gapL }) {
          Column({ space: 6 }) {
            Text(this.formatTime())
              .fontSize(64)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .fontFamily('monospace')

            Text(this.isRunning
              ? (this.isPaused ? '已暂停' : '专注中')
              : '准备开始')
              .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
              .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
          }

          Stack() {
            Row()
              .width('100%')
              .height(4)
              .backgroundColor(UiTokens.divider)
              .borderRadius(2)
            Row()
              .width(`${((this.totalSeconds - this.remainingSeconds) / this.totalSeconds) * 100}%`)
              .height(4)
              .backgroundColor(UiTokens.brand)
              .borderRadius(2)
          }
          .width(220)
          .height(4)

          Text(`${Math.floor((this.totalSeconds - this.remainingSeconds) / 60)} / ${Math.floor(this.totalSeconds / 60)} 分钟`)
            .fontSize(UiTokens.textS)
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
        }
        .width('100%')
        .padding({ top: 32, bottom: 16 })
        .alignItems(HorizontalAlign.Center)

        if (this.showCompleteMsg) {
          Column({ space: UiTokens.gapS }) {
            Text(this.completeMsg)
              .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding(16)
              .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.brandSoft)
              .borderRadius(UiTokens.radiusXL)
          }
          .width('100%')
        }

        // Task association
        Column({ space: UiTokens.gapS }) {
          Text('关联日程')
            .fontSize(this.sectionTitle())
            .fontWeight(FontWeight.Medium)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            .width('100%')

          Button() {
            Row() {
              Text(this.selectedTaskTitle())
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              Text('选择')
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .fontColor(UiTokens.brand)
            }
            .width('100%')
          }
          .width('100%')
          .height(48)
          .padding({ left: 14, right: 14 })
          .backgroundColor(UiTokens.bgHover)
          .borderRadius(UiTokens.radiusL)
          .enabled(!this.isRunning)
          .onClick(() => {
            this.loadTodayTasks()
            this.showTaskPicker = true
          })
        }
        .width('100%')

        // Mode selector
        Column({ space: UiTokens.gapS }) {
          Text('选择模式')
            .fontSize(this.sectionTitle())
            .fontWeight(FontWeight.Medium)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            .width('100%')

          Row({ space: 10 }) {
            ForEach([
              FocusMode.MINI,
              FocusMode.NORMAL,
              FocusMode.ESTIMATE,
              FocusMode.BODY
            ], (mode: FocusMode) => {
              Column({ space: 4 }) {
                Text(getFocusModeConfig(mode).label)
                  .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.selectedMode === mode
                    ? (this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                    : (this.settings.highContrast ? '#555555' : UiTokens.textSecondary))

                Text(`${getFocusModeConfig(mode).defaultMinutes}分钟`)
                  .fontSize(UiTokens.textXS)
                  .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
              }
              .layoutWeight(1)
              .padding(12)
              .backgroundColor(this.selectedMode === mode
                ? (this.settings.highContrast ? UiTokens.hcBg : UiTokens.brandSoft)
                : (this.settings.highContrast ? '#EEEEEE' : UiTokens.bgHover))
              .borderRadius(UiTokens.radiusL)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                this.selectMode(mode)
              })
            })
          }
          .width('100%')
        }
        .width('100%')

        // Controls
        Column({ space: UiTokens.gapM }) {
          if (!this.isRunning) {
            Button('开始专注')
              .width('100%')
              .height(52)
              .fontSize(UiTokens.textL)
              .fontWeight(FontWeight.Medium)
              .fontColor(UiTokens.textInverse)
              .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
              .borderRadius(UiTokens.radiusXL)
              .onClick(() => {
                this.startTimer()
              })
          } else if (this.isPaused) {
            Row({ space: UiTokens.gapM }) {
              Button('继续')
                .layoutWeight(1)
                .height(52)
                .fontSize(UiTokens.textL)
                .fontWeight(FontWeight.Medium)
                .fontColor(UiTokens.textInverse)
                .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                .borderRadius(UiTokens.radiusXL)
                .onClick(() => {
                  this.startTimer()
                })

              Button('结束')
                .layoutWeight(1)
                .height(52)
                .fontSize(UiTokens.textL)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textSecondary)
                .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgHover)
                .borderRadius(UiTokens.radiusXL)
                .onClick(() => {
                  this.stopTimer()
                })
            }
            .width('100%')
          } else {
            Row({ space: UiTokens.gapM }) {
              Button('暂停')
                .layoutWeight(1)
                .height(52)
                .fontSize(UiTokens.textL)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.brandSoft)
                .borderRadius(UiTokens.radiusXL)
                .onClick(() => {
                  this.pauseTimer()
                })

              Button('结束')
                .layoutWeight(1)
                .height(52)
                .fontSize(UiTokens.textL)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textSecondary)
                .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgHover)
                .borderRadius(UiTokens.radiusXL)
                .onClick(() => {
                  this.stopTimer()
                })
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
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Auto)

      if (this.showTaskPicker) {
        Column() {
          Column()
            .width('100%')
            .layoutWeight(1)
            .backgroundColor('rgba(0,0,0,0.4)')
            .onClick(() => { this.showTaskPicker = false })

          Column({ space: UiTokens.gapM }) {
            Text('选择要专注的日程')
              .fontSize(UiTokens.textXL)
              .fontWeight(FontWeight.Bold)
              .fontColor(UiTokens.textPrimary)
              .width('100%')

            if (this.todayTasks.length === 0) {
              Text('今天没有待完成的日程')
                .fontSize(this.baseFont())
                .fontColor(UiTokens.textSecondary)
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding(24)
            } else {
              Column({ space: 0 }) {
                ForEach(this.todayTasks, (task: Task, index: number) => {
                  Row({ space: UiTokens.gapM }) {
                    Column() {
                      Text(task.title)
                        .fontSize(this.baseFont())
                        .fontColor(this.selectedTaskId === task.id ? UiTokens.brand : UiTokens.textPrimary)
                        .fontWeight(this.selectedTaskId === task.id ? FontWeight.Medium : FontWeight.Regular)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })

                      if (task.startTime && task.endTime) {
                        Text(`${task.startTime} - ${task.endTime}`)
                          .fontSize(UiTokens.textXS)
                          .fontColor(UiTokens.textTertiary)
                      }
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)

                    if (this.selectedTaskId === task.id) {
                      Text('✓')
                        .fontSize(UiTokens.textM)
                        .fontColor(UiTokens.brand)
                        .fontWeight(FontWeight.Bold)
                    }
                  }
                  .width('100%')
                  .padding(14)
                  .backgroundColor(this.selectedTaskId === task.id ? UiTokens.brandSoft : 'transparent')
                  .borderRadius(UiTokens.radiusL)
                  .onClick(() => {
                    this.selectedTaskId = task.id
                    this.showTaskPicker = false
                  })

                  if (index < this.todayTasks.length - 1) {
                    Divider()
                      .strokeWidth(0.5)
                      .color(UiTokens.divider)
                      .margin({ left: 14 })
                  }
                })
              }
              .width('100%')
            }

            Button('不关联任何日程')
              .width('100%')
              .height(44)
              .fontSize(this.baseFont())
              .fontColor(UiTokens.textSecondary)
              .backgroundColor(UiTokens.bgHover)
              .borderRadius(UiTokens.radiusL)
              .onClick(() => {
                this.selectedTaskId = ''
                this.showTaskPicker = false
              })

            Row({ space: UiTokens.gapM }) {
              Button('取消')
                .layoutWeight(1)
                .height(44)
                .fontColor(UiTokens.textSecondary)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusL)
                .onClick(() => { this.showTaskPicker = false })
            }
            .width('100%')
          }
          .width('100%')
          .padding(UiTokens.pagePadding)
          .padding({ bottom: 32 })
          .backgroundColor(UiTokens.bgCard)
          .borderRadius({ topLeft: 24, topRight: 24 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.End)
      }
    }
    .width('100%')
    .height('100%')
  }

  private sectionTitle(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }
}
