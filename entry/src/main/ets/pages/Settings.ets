import { router } from '@kit.ArkUI'
import { AppSettings } from '../models/SettingsModel'
import { storage } from '../utils/StorageUtil'
import { UiTokens } from '../design/UiTokens'

@Entry
@Component
struct Settings {
  @State settings: AppSettings = new AppSettings()

  aboutToAppear() {
    this.settings = storage.getSettings()
  }

  saveSettings() {
    storage.saveSettings(this.settings)
  }

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  private labelFont(): number {
    return this.settings.largeText ? UiTokens.textM : UiTokens.textS
  }

  @Builder
  SettingItem(title: string, desc: string, isOn: boolean, onChange: (val: boolean) => void) {
    Row() {
      Column({ space: 4 }) {
        Text(title)
          .fontSize(this.labelFont())
          .fontWeight(FontWeight.Medium)
          .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
        Text(desc)
          .fontSize(this.settings.largeText ? UiTokens.textS : UiTokens.textXS)
          .fontColor(this.settings.highContrast ? '#333333' : UiTokens.textSecondary)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
        .onChange((val) => {
          onChange(val)
          this.saveSettings()
        })
    }
    .width('100%')
    .padding(UiTokens.cardPadding)
    .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPrimary)
    .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })
    .borderRadius(UiTokens.radiusM)
    .alignItems(VerticalAlign.Center)
  }

  build() {
    Column() {
      // Header
      Row() {
        Button() {
          Text('返回')
            .fontSize(this.baseFont())
            .fontColor(this.settings.highContrast ? '#333333' : UiTokens.textSecondary)
        }
        .backgroundColor('transparent')
        .onClick(() => {
          router.back()
        })

        Text('设置')
          .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

        Blank().width(60)
      }
      .width('100%')
      .height(56)
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgSecondary)
      .border({ width: { bottom: this.settings.highContrast ? 2 : 1 }, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })

      Scroll() {
        Column({ space: UiTokens.gapL }) {
          Text('无障碍')
            .fontSize(UiTokens.textXS)
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.tertiaryText)
            .width('100%')
            .margin({ top: 4 })

          this.SettingItem(
            '高对比度模式',
            '使用黑白高对比，方便视觉敏感用户',
            this.settings.highContrast,
            (val) => { this.settings.highContrast = val }
          )

          this.SettingItem(
            '大字体模式',
            '增大所有文字和按钮尺寸',
            this.settings.largeText,
            (val) => { this.settings.largeText = val }
          )

          this.SettingItem(
            '减少动画',
            '关闭不必要的动效，保持界面稳定',
            this.settings.reduceAnimations,
            (val) => { this.settings.reduceAnimations = val }
          )

          this.SettingItem(
            '显示准备提示',
            '在日程卡片上显示需要准备的事项',
            this.settings.showPrepareHints,
            (val) => { this.settings.showPrepareHints = val }
          )

          // About
          Column({ space: 6 }) {
            Row({ space: 8 }) {
              Text('星')
                .fontSize(this.settings.largeText ? 22 : 18)
                .fontColor(UiTokens.brand)
                .fontWeight(FontWeight.Bold)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(UiTokens.brandSoft)
                .borderRadius(4)
              Text('关于星序')
                .fontSize(this.labelFont())
                .fontWeight(FontWeight.Medium)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .width('100%')
            }
            .width('100%')

            Text('星序是一款为神经多样性人群（自闭症谱系、ADHD 等）设计的友好日程工具。我们相信每个人都值得按自己的节奏生活。')
              .fontSize(this.baseFont())
              .fontColor(this.settings.highContrast ? '#333333' : UiTokens.textSecondary)
              .width('100%')
              .lineHeight(this.settings.largeText ? 28 : 22)

            Text('把大任务拆成小步骤，可以减少执行焦虑哦')
              .fontSize(this.baseFont())
              .fontColor(UiTokens.brand)
              .width('100%')
              .margin({ top: 8 })
          }
          .width('100%')
          .padding(UiTokens.cardPadding)
          .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPrimary)
          .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })
          .borderRadius(UiTokens.radiusM)
          .margin({ top: 8 })
        }
        .width('100%')
        .padding(UiTokens.pagePadding)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgSecondary)
  }
}
