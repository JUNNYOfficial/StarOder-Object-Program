import { Task, TaskStatus, getTypeConfig, getTimeBlockConfig } from '../models/DataModels'
import { UserPreferences } from '../models/DataModels'
import { UiTokens } from '../design/UiTokens'

@Component
export struct ScheduleCard {
  @Prop task: Task
  @Prop settings: UserPreferences
  onClickCard: () => void = () => {}
  onToggleStatus: () => void = () => {}

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  private smallFont(): number {
    return this.settings.largeText ? UiTokens.textM : UiTokens.textS
  }

  private statusText(): string {
    switch (this.task.status) {
      case TaskStatus.TODO: return '待开始'
      case TaskStatus.STARTED: return '进行中'
      case TaskStatus.MOSTLY: return '快完成'
      case TaskStatus.DONE: return '已完成'
      case TaskStatus.PAUSED: return '已暂停'
      default: return ''
    }
  }

  private statusTextColor(): string {
    switch (this.task.status) {
      case TaskStatus.TODO: return UiTokens.textTertiary
      case TaskStatus.STARTED: return UiTokens.active
      case TaskStatus.MOSTLY: return UiTokens.brand
      case TaskStatus.DONE: return UiTokens.done
      case TaskStatus.PAUSED: return UiTokens.paused
      default: return UiTokens.textTertiary
    }
  }

  private completedCount(): number {
    return this.task.subTasks.filter(s => s.completed).length
  }

  private subTaskTotal(): number {
    return this.task.subTasks.length
  }

  private progressWidth(): string {
    const total = this.subTaskTotal()
    if (total > 0) {
      return `${(this.completedCount() / total) * 100}%`
    }
    // 无子任务时按状态映射进度
    switch (this.task.status) {
      case TaskStatus.TODO: return '0%'
      case TaskStatus.STARTED: return '33%'
      case TaskStatus.MOSTLY: return '66%'
      case TaskStatus.DONE: return '100%'
      case TaskStatus.PAUSED: return '0%'
      default: return '0%'
    }
  }

  private progressLabel(): string {
    const total = this.subTaskTotal()
    if (total > 0) {
      return `步骤 ${this.completedCount()}/${total}`
    }
    switch (this.task.status) {
      case TaskStatus.TODO: return '待开始'
      case TaskStatus.STARTED: return '进行中'
      case TaskStatus.MOSTLY: return '快完成'
      case TaskStatus.DONE: return '已完成'
      case TaskStatus.PAUSED: return '已暂停'
      default: return ''
    }
  }

  build() {
    Row() {
      if (this.task.startTime || this.task.endTime) {
        // Time
        Column() {
          Text(this.task.startTime || '-')
            .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
          Text(this.task.endTime || '-')
            .fontSize(this.smallFont())
            .fontColor(this.settings.highContrast ? '#333333' : UiTokens.textTertiary)
            .margin({ top: 2 })
        }
        .width(52)
        .alignItems(HorizontalAlign.Start)
      }

      // Card
      Column({ space: UiTokens.gapS }) {
        // Title row
        Row() {
          Text(this.task.title)
            .fontSize(this.baseFont())
            .fontWeight(FontWeight.Medium)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.statusText())
            .fontSize(UiTokens.textXS)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : this.statusTextColor())
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')

        // Meta row: 类型 · 时间段
        Row({ space: 4 }) {
          Text(getTypeConfig(this.task.type).label)
            .fontSize(this.smallFont())
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
          Text('·')
            .fontSize(this.smallFont())
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
          Text(getTimeBlockConfig(this.task.timeBlock).label)
            .fontSize(this.smallFont())
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
        }
        .width('100%')

        // Progress
        Row() {
          Text(this.progressLabel())
            .fontSize(this.smallFont())
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)

          Stack() {
            Row()
              .width('100%')
              .height(4)
              .backgroundColor(this.settings.highContrast ? '#CCCCCC' : UiTokens.divider)
              .borderRadius(2)
            Row()
              .width(this.progressWidth())
              .height(4)
              .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
              .borderRadius(2)
              .animation({
                duration: 300,
                curve: Curve.EaseInOut
              })
          }
          .width(60)
          .height(4)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        // Prepare items
        if (this.settings.showPrepareHints && this.task.prepareItems.length > 0) {
          Text(`准备 ${this.task.prepareItems.join('、')}`)
            .fontSize(this.smallFont())
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')
        }
      }
      .layoutWeight(1)
      .padding(UiTokens.cardPadding)
      .backgroundColor(UiTokens.bgCard)
      .borderRadius(UiTokens.radiusXL)
      .margin({ left: 16 })
      .shadow({
        radius: this.settings.highContrast ? 0 : 8,
        color: '#0A000000',
        offsetX: 0,
        offsetY: 2
      })
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
    .onClick(() => {
      this.onClickCard()
    })
  }
}
