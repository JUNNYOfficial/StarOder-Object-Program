import { SubTask } from '../models/DataModels'
import { UserPreferences } from '../models/DataModels'
import { UiTokens } from '../design/UiTokens'

@Component
export struct SubTaskItem {
  @Prop subTask: SubTask
  @Prop settings: UserPreferences
  index: number = 0
  onToggle: () => void = () => {}

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  build() {
    Row() {
      // Check circle
      Stack() {
        Circle()
          .width(this.settings.largeText ? 28 : 22)
          .height(this.settings.largeText ? 28 : 22)
          .fill(this.subTask.completed
            ? (this.settings.highContrast ? UiTokens.hcText : UiTokens.done)
            : 'transparent')
          .stroke(this.settings.highContrast ? UiTokens.hcBorder : UiTokens.divider)
          .strokeWidth(this.subTask.completed ? 0 : 1.5)

        if (this.subTask.completed) {
          Text('完成')
            .fontSize(this.settings.largeText ? 14 : 12)
            .fontColor(UiTokens.textInverse)
            .fontWeight(FontWeight.Bold)
        }
      }
      .width(this.settings.largeText ? 32 : 26)
      .height(this.settings.largeText ? 32 : 26)

      Text(this.subTask.title)
        .fontSize(this.baseFont())
        .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
        .layoutWeight(1)
        .margin({ left: 12 })
        .decoration({ type: this.subTask.completed ? TextDecorationType.LineThrough : TextDecorationType.None })
        .fontColor(this.subTask.completed
          ? (this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
          : (this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary))
    }
    .width('100%')
    .padding({ top: 12, bottom: 12 })
    .backgroundColor(UiTokens.bgCard)
    .borderRadius(UiTokens.radiusL)
    .margin({ bottom: 8 })
    .onClick(() => {
      this.onToggle()
    })
  }
}
