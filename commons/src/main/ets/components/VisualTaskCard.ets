import { Task, TaskStatus, TaskType, getTypeConfig } from '../models/DataModels'
import { UserPreferences } from '../models/DataModels'
import { UiTokens } from '../design/UiTokens'

@Component
export struct VisualTaskCard {
  @Prop task: Task
  @Prop settings: UserPreferences
  onClickCard: () => void = () => {}

  private typeLabel(): string {
    switch (this.task.type) {
      case TaskType.THINK: return '思'
      case TaskType.SOCIAL: return '社'
      case TaskType.HOME: return '居'
      case TaskType.REST: return '休'
      case TaskType.EXERCISE: return '动'
      default: return '务'
    }
  }

  private timeLabel(): string {
    if (this.task.startTime && this.task.endTime) {
      return `${this.task.startTime}-${this.task.endTime}`
    }
    if (this.task.startTime) {
      return this.task.startTime
    }
    return ''
  }

  private isDone(): boolean {
    return this.task.status === TaskStatus.DONE
  }

  private opacityValue(): number {
    return this.isDone() ? 0.5 : 1.0
  }

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textM : UiTokens.textS
  }

  private iconFont(): number {
    return this.settings.largeText ? UiTokens.textXL : UiTokens.text2XL
  }

  build() {
    Column({ space: UiTokens.gapS }) {
      // Type icon circle
      Text(this.typeLabel())
        .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .width(this.settings.largeText ? 48 : 40)
        .height(this.settings.largeText ? 48 : 40)
        .textAlign(TextAlign.Center)
        .backgroundColor(getTypeConfig(this.task.type).color)
        .borderRadius(this.settings.largeText ? 24 : 20)
        .opacity(this.opacityValue())

      // Title
      Text(this.task.title)
        .fontSize(this.baseFont())
        .fontWeight(FontWeight.Medium)
        .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
        .width('100%')
        .opacity(this.opacityValue())

      // Time label
      if (this.timeLabel().length > 0) {
        Text(this.timeLabel())
          .fontSize(UiTokens.textXS)
          .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
          .opacity(this.opacityValue())
      }
    }
    .width('100%')
    .aspectRatio(1)
    .padding(UiTokens.gapM)
    .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : getTypeConfig(this.task.type).softColor)
    .borderRadius(UiTokens.radiusXL)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .shadow({
      radius: this.settings.highContrast ? 0 : 6,
      color: '#0A000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.onClickCard()
    })
  }
}
