import { router, promptAction } from '@kit.ArkUI'
import { UserPreferences } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { parseScheduleText, createTaskFromParsed, ParsedSchedule, setSystemReminder } from '../services/VoiceScheduleService'
import { UiTokens } from '../design/UiTokens'

@Entry
@Component
struct VoiceInputPage {
  @State settings: UserPreferences = new UserPreferences()
  @State inputText: string = ''
  @State parsedResult: ParsedSchedule | null = null
  @State showResult: boolean = false

  aboutToAppear() {
    this.settings = dataStore.getUserPrefs()
  }

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  private sectionTitle(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  parseInput() {
    if (!this.inputText.trim()) {
      return
    }
    const parsed = parseScheduleText(this.inputText.trim())
    this.parsedResult = parsed
    this.showResult = true
  }

  saveParsedTask() {
    if (!this.parsedResult) {
      return
    }
    const task = createTaskFromParsed(this.parsedResult)
    dataStore.addTask(task)
    const ok = setSystemReminder(task)
    if (!ok) {
      promptAction.showToast({ message: '当前版本暂不支持系统提醒' })
    }
    router.back()
  }

  build() {
    Column() {
      // Header
      Row() {
        Button() {
          Text('取消')
            .fontSize(this.baseFont())
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
        }
        .backgroundColor('transparent')
        .onClick(() => {
          router.back()
        })

        Text('语音添加')
          .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

        Row().width(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(UiTokens.bgCard)

      Scroll() {
        Column({ space: UiTokens.gapXL }) {
          // Input area
          Column({ space: UiTokens.gapS }) {
            Text('说或输入你的日程')
              .fontSize(this.sectionTitle())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            TextArea({ placeholder: '例如：明天下午三点开会', text: $$this.inputText })
              .width('100%')
              .height(120)
              .fontSize(this.baseFont())
              .backgroundColor(UiTokens.bgHover)
              .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
              .borderRadius(UiTokens.radiusL)

            Button('解析')
              .width('100%')
              .height(48)
              .fontSize(UiTokens.textL)
              .fontWeight(FontWeight.Medium)
              .fontColor(UiTokens.textInverse)
              .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
              .borderRadius(UiTokens.radiusXL)
              .onClick(() => {
                this.parseInput()
              })
          }
          .width('100%')

          // Parsed result
          if (this.showResult && this.parsedResult) {
            Column({ space: UiTokens.gapM }) {
              Text('识别结果')
                .fontSize(this.sectionTitle())
                .fontWeight(FontWeight.Medium)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .width('100%')

              Column({ space: UiTokens.gapS }) {
                Text(this.parsedResult.title)
                  .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

                Text(`${this.parsedResult.date}  ${this.parsedResult.startTime} - ${this.parsedResult.endTime}`)
                  .fontSize(this.baseFont())
                  .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
              }
              .width('100%')
              .padding(UiTokens.cardPadding)
              .backgroundColor(UiTokens.bgCard)
              .borderRadius(UiTokens.radiusXL)
              .shadow({
                radius: this.settings.highContrast ? 0 : 8,
                color: '#0A000000',
                offsetX: 0,
                offsetY: 2
              })

              Button('确认添加')
                .width('100%')
                .height(52)
                .fontSize(UiTokens.textL)
                .fontWeight(FontWeight.Medium)
                .fontColor(UiTokens.textInverse)
                .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                .borderRadius(UiTokens.radiusXL)
                .onClick(() => {
                  this.saveParsedTask()
                })
            }
            .width('100%')
          }

          // Tips
          Text('提示：支持"明天下午三点开会""后天早上跑步"等自然语言')
            .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 8, bottom: 32 })
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
