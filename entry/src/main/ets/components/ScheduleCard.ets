import { Schedule, getColorTag } from '../models/ScheduleModel'
import { AppSettings } from '../models/SettingsModel'
import { UiTokens } from '../design/UiTokens'

@Component
export struct ScheduleCard {
  @Prop schedule: Schedule
  @Prop settings: AppSettings
  onClickCard: () => void = () => {}
  onToggleComplete: () => void = () => {}

  private scheduleBorderColor(): string {
    const tag = getColorTag(this.schedule.colorTag)
    return this.settings.highContrast ? tag.hcColor : tag.color
  }

  private bgColor(): string {
    const tag = getColorTag(this.schedule.colorTag)
    return this.settings.highContrast ? UiTokens.hcBg : tag.bg
  }

  private cardTextPrimary(): string {
    return this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary
  }

  private cardTextSecondary(): string {
    return this.settings.highContrast ? '#333333' : UiTokens.textSecondary
  }

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textXL : UiTokens.textM
  }

  private smallFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textS
  }

  private completedCount(): number {
    return this.schedule.subTasks.filter(s => s.isCompleted).length
  }

  private subTaskTotal(): number {
    return this.schedule.subTasks.length
  }

  private progressWidth(): string {
    const total = this.subTaskTotal()
    if (total === 0) return '0%'
    return `${(this.completedCount() / total) * 100}%`
  }

  private prepareText(): string {
    return `准备: ${this.schedule.prepareItems.join('、')}`
  }

  build() {
    Row() {
      // Time column
      Column() {
        Text(this.schedule.startTime)
          .fontSize(this.baseFont())
          .fontWeight(FontWeight.Bold)
          .fontColor(this.cardTextPrimary())
        Text(this.schedule.endTime)
          .fontSize(this.smallFont())
          .fontColor(this.cardTextSecondary())
          .margin({ top: 4 })
      }
      .width(64)
      .alignItems(HorizontalAlign.Start)

      // Card body
      Column() {
        Row() {
          Text(this.schedule.title)
            .fontSize(this.baseFont())
            .fontWeight(FontWeight.Medium)
            .fontColor(this.cardTextPrimary())
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .decoration({ type: this.schedule.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })

          Text(this.schedule.isCompleted ? '✓' : '')
            .fontSize(this.settings.largeText ? 20 : 16)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
            .width(this.settings.largeText ? 40 : 32)
            .height(this.settings.largeText ? 40 : 32)
            .backgroundColor(this.schedule.isCompleted ? UiTokens.confirm : UiTokens.bgTertiary)
            .borderRadius(UiTokens.radiusS)
            .onClick(() => {
              this.onToggleComplete()
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // Tag pill
        Text(getColorTag(this.schedule.colorTag).label)
          .fontSize(UiTokens.textXS)
          .fontColor(this.settings.highContrast ? UiTokens.hcText : getColorTag(this.schedule.colorTag).color)
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .backgroundColor(this.bgColor())
          .border({ width: this.settings.highContrast ? 1.5 : 0, color: this.scheduleBorderColor() })
          .borderRadius(6)
          .margin({ top: 8 })

        // Subtask progress
        if (this.schedule.subTasks.length > 0) {
          Row() {
            Text(`步骤 ${this.completedCount()}/${this.subTaskTotal()}`)
              .fontSize(this.smallFont())
              .fontColor(this.cardTextSecondary())

            Stack() {
              Row()
                .width('100%')
                .height(6)
                .backgroundColor(this.settings.highContrast ? '#CCCCCC' : UiTokens.border)
                .borderRadius(3)

              Row()
                .width(this.progressWidth())
                .height(6)
                .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                .borderRadius(3)
            }
            .width(80)
            .height(6)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: 10 })
        }

        // Prepare items hint
        if (this.settings.showPrepareHints && this.schedule.prepareItems.length > 0) {
          Row() {
            Text('备')
              .fontSize(UiTokens.textXS)
              .fontColor(this.cardTextSecondary())
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .backgroundColor(UiTokens.bgTertiary)
              .borderRadius(4)
              .margin({ right: 6 })
            Text(this.prepareText())
              .fontSize(this.smallFont())
              .fontColor(this.cardTextSecondary())
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
          .margin({ top: 8 })
        }
      }
      .layoutWeight(1)
      .padding(UiTokens.cardPadding)
      .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPrimary)
      .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.scheduleBorderColor() })
      .borderRadius(UiTokens.radiusM)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
    .onClick(() => {
      this.onClickCard()
    })
  }
}
