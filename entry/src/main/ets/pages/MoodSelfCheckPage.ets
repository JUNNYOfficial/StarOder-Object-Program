import { router } from '@kit.ArkUI'
import { MoodSurveyRecord, EnergyRecord, UserPreferences } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { UiTokens } from '../design/UiTokens'
import { todayStr } from '../utils/DateUtils'

@Entry
@Component
struct MoodSelfCheckPage {
  @State settings: UserPreferences = new UserPreferences()
  @State moodRating: number = 3
  @State energyRating: number = 3
  @State anxietyRating: number = 3
  @State focusRating: number = 3
  @State note: string = ''

  aboutToAppear() {
    this.settings = dataStore.getUserPrefs()
  }

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  saveCheck() {
    const now = new Date()
    const timeStr = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`

    const moodRecord = new MoodSurveyRecord(todayStr(), timeStr, this.moodRating)
    moodRecord.trigger = `能量:${this.energyRating} 焦虑:${this.anxietyRating} 专注:${this.focusRating}`
    moodRecord.context = '自查'
    moodRecord.note = this.note.trim()
    dataStore.saveMoodSurvey(moodRecord)

    const energyRecord = new EnergyRecord(todayStr(), this.energyRating)
    energyRecord.note = `自查同步：情绪${this.moodRating}`
    dataStore.saveEnergyRecord(energyRecord)

    router.back()
  }

  @Builder
  RatingSection(title: string, rating: number, onChange: (n: number) => void) {
    Column({ space: UiTokens.gapM }) {
      Text(title)
        .fontSize(this.baseFont())
        .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
        .width('100%')

      Row({ space: UiTokens.gapM }) {
        ForEach([1, 2, 3, 4, 5], (n: number) => {
          Button(String(n))
            .width(48)
            .height(48)
            .fontSize(this.baseFont())
            .fontColor(rating === n ? UiTokens.textInverse : UiTokens.textPrimary)
            .backgroundColor(rating === n
              ? (this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
              : (this.settings.highContrast ? '#EEEEEE' : UiTokens.bgHover))
            .borderRadius(UiTokens.radiusL)
            .onClick(() => { onChange(n) })
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
  }

  build() {
    Column() {
      // Header
      Row() {
        Button() {
          Text('返回')
            .fontSize(this.baseFont())
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
        }
        .backgroundColor('transparent')
        .onClick(() => {
          router.back()
        })

        Text('情绪自查')
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
          Text('此刻感觉如何？诚实面对自己。')
            .fontSize(this.baseFont())
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
            .width('100%')

          this.RatingSection('情绪状态（1=低落，5=愉悦）', this.moodRating, (n) => { this.moodRating = n })
          this.RatingSection('能量水平（1=疲惫，5=充沛）', this.energyRating, (n) => { this.energyRating = n })
          this.RatingSection('焦虑程度（1=平静，5=焦虑）', this.anxietyRating, (n) => { this.anxietyRating = n })
          this.RatingSection('专注程度（1=涣散，5=沉浸）', this.focusRating, (n) => { this.focusRating = n })

          Column({ space: UiTokens.gapM }) {
            Text('写点什么（可选）')
              .fontSize(this.baseFont())
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            TextArea({ placeholder: '记录当下的想法...', text: $$this.note })
              .width('100%')
              .height(100)
              .fontSize(this.baseFont())
              .backgroundColor(this.settings.highContrast ? '#FFFFFF' : UiTokens.bgHover)
              .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
              .borderRadius(UiTokens.radiusL)
          }
          .width('100%')

          Button('保存自查记录')
            .width('100%')
            .height(48)
            .fontSize(this.baseFont())
            .fontColor(UiTokens.textInverse)
            .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
            .borderRadius(UiTokens.radiusXL)
            .onClick(() => { this.saveCheck() })
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
