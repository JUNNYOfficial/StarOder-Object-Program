import { SubTask } from '../models/ScheduleModel'
import { AppSettings } from '../models/SettingsModel'
import { UiTokens } from '../design/UiTokens'

@Component
export struct SubTaskItem {
  @Prop subTask: SubTask
  @Prop settings: AppSettings
  index: number = 0
  onToggle: () => void = () => {}

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  private stepBgColor(): string {
    if (this.subTask.isCompleted) {
      return this.settings.highContrast ? UiTokens.hcText : UiTokens.confirm
    }
    return this.settings.highContrast ? UiTokens.hcBg : UiTokens.brandSoft
  }

  private stepTextColor(): string {
    if (this.subTask.isCompleted) {
      return UiTokens.textInverse
    }
    return this.settings.highContrast ? UiTokens.hcText : UiTokens.brand
  }

  private checkBtnBgColor(): string {
    if (this.subTask.isCompleted) {
      return this.settings.highContrast ? UiTokens.hcText : UiTokens.confirm
    }
    return this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgTertiary
  }

  build() {
    Row() {
      Text(`${this.index + 1}`)
        .width(this.settings.largeText ? 36 : 28)
        .height(this.settings.largeText ? 36 : 28)
        .fontSize(this.baseFont())
        .fontColor(this.stepTextColor())
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.stepBgColor())
        .border({ width: this.settings.highContrast ? 1.5 : 0, color: UiTokens.hcBorder })
        .borderRadius(UiTokens.radiusS)

      Text(this.subTask.title)
        .fontSize(this.baseFont())
        .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
        .layoutWeight(1)
        .margin({ left: 12 })
        .decoration({ type: this.subTask.isCompleted ? TextDecorationType.LineThrough : TextDecorationType.None })

      Text(this.subTask.isCompleted ? '✓' : '')
        .fontSize(this.baseFont())
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
        .width(this.settings.largeText ? 44 : 36)
        .height(this.settings.largeText ? 44 : 36)
        .backgroundColor(this.checkBtnBgColor())
        .border({ width: this.settings.highContrast ? 1.5 : 0, color: UiTokens.hcBorder })
        .borderRadius(UiTokens.radiusS)
        .onClick(() => {
          this.onToggle()
        })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPrimary)
    .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })
    .borderRadius(UiTokens.radiusM)
    .margin({ bottom: 8 })
    .opacity(this.subTask.isCompleted ? 0.6 : 1)
  }
}
