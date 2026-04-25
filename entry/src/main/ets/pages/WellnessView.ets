import { router } from '@kit.ArkUI'
import { UserPreferences, MoodSurveyRecord } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { UiTokens } from '../design/UiTokens'

class DayEnergy {
  date: string
  label: string
  rating: number
  hasData: boolean
  constructor(date: string, label: string, rating: number, hasData: boolean) {
    this.date = date
    this.label = label
    this.rating = rating
    this.hasData = hasData
  }
}

@Entry
@Component
struct WellnessView {
  @State settings: UserPreferences = new UserPreferences()
  @State dayEnergies: DayEnergy[] = []
  @State totalFocusMinutes: number = 0
  @State completedFocusSessions: number = 0
  @State moodRecords: MoodSurveyRecord[] = []
  @State hasAnyData: boolean = false
  @State todayStr: string = ''
  @State weekdayLabels: string[] = ['日', '一', '二', '三', '四', '五', '六']

  aboutToAppear() {
    this.settings = dataStore.getUserPrefs()
    this.todayStr = this.formatDate(new Date())
    this.loadData()
  }

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  private largeFont(): number {
    return this.settings.largeText ? UiTokens.text2XL : UiTokens.textXL
  }

  private formatDate(d: Date): string {
    const y = d.getFullYear()
    const m = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  private loadData() {
    this.loadEnergyData()
    this.loadFocusStats()
    this.loadMoodData()
    this.hasAnyData = this.totalFocusMinutes > 0 || this.moodRecords.length > 0 ||
      this.dayEnergies.filter(d => d.hasData).length > 0
  }

  private loadEnergyData() {
    const allEnergy = dataStore.getEnergyRecords()
    const today = new Date()
    const days: DayEnergy[] = []
    for (let i = 6; i >= 0; i--) {
      const d = new Date(today)
      d.setDate(d.getDate() - i)
      const dateStr = this.formatDate(d)
      let rating = 0
      let hasData = false
      for (let j = 0; j < allEnergy.length; j++) {
        if (allEnergy[j].date === dateStr) {
          rating = allEnergy[j].rating
          hasData = true
          break
        }
      }
      days.push(new DayEnergy(dateStr, this.weekdayLabels[d.getDay()], rating, hasData))
    }
    this.dayEnergies = days
  }

  private loadFocusStats() {
    const all = dataStore.getFocusRecords()
    let totalMinutes = 0
    let sessions = 0
    for (let i = 0; i < all.length; i++) {
      totalMinutes = totalMinutes + all[i].actualMinutes
      if (all[i].completed) {
        sessions = sessions + 1
      }
    }
    this.totalFocusMinutes = totalMinutes
    this.completedFocusSessions = sessions
  }

  private loadMoodData() {
    const all = dataStore.getMoodSurveys()
    const recent: MoodSurveyRecord[] = []
    const startIdx = all.length > 5 ? all.length - 5 : 0
    for (let i = startIdx; i < all.length; i++) {
      recent.push(all[i])
    }
    this.moodRecords = recent
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

        Text('数据回顾')
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
          if (!this.hasAnyData) {
            Column() {
              Text('还没有记录')
                .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .margin({ bottom: 6 })
              Text('使用专注计时或记录能量后，数据会出现在这里')
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding(48)
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            // Focus stats
            Column({ space: UiTokens.gapM }) {
              Text('专注统计')
                .fontSize(this.sectionTitle())
                .fontWeight(FontWeight.Medium)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .width('100%')

              Row({ space: UiTokens.gapM }) {
                Column({ space: 4 }) {
                  Text(`${this.totalFocusMinutes}`)
                    .fontSize(this.largeFont())
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                  Text('总专注分钟')
                    .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                    .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
                }
                .layoutWeight(1)
                .padding(16)
                .backgroundColor(UiTokens.bgCard)
                .borderRadius(UiTokens.radiusXL)
                .alignItems(HorizontalAlign.Start)
                .shadow({
                  radius: this.settings.highContrast ? 0 : 8,
                  color: '#0A000000',
                  offsetX: 0,
                  offsetY: 2
                })

                Column({ space: 4 }) {
                  Text(`${this.completedFocusSessions}`)
                    .fontSize(this.largeFont())
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                  Text('完成次数')
                    .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                    .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
                }
                .layoutWeight(1)
                .padding(16)
                .backgroundColor(UiTokens.bgCard)
                .borderRadius(UiTokens.radiusXL)
                .alignItems(HorizontalAlign.Start)
                .shadow({
                  radius: this.settings.highContrast ? 0 : 8,
                  color: '#0A000000',
                  offsetX: 0,
                  offsetY: 2
                })
              }
              .width('100%')
            }
            .width('100%')

            // Energy chart
            if (this.dayEnergies.filter(d => d.hasData).length > 0) {
              Column({ space: UiTokens.gapM }) {
                Text('最近7天能量')
                  .fontSize(this.sectionTitle())
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                  .width('100%')

                Column({ space: UiTokens.gapS }) {
                  ForEach(this.dayEnergies, (day: DayEnergy) => {
                    Row({ space: 10 }) {
                      Text(day.label)
                        .width(22)
                        .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                        .fontColor(day.date === this.todayStr
                          ? (this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                          : (this.settings.highContrast ? '#555555' : UiTokens.textTertiary))
                        .fontWeight(day.date === this.todayStr ? FontWeight.Bold : FontWeight.Regular)
                        .textAlign(TextAlign.Center)

                      Stack() {
                        Row()
                          .width('100%')
                          .height(8)
                          .backgroundColor(UiTokens.divider)
                          .borderRadius(4)
                        if (day.hasData) {
                          Row()
                            .width(`${(day.rating / 5) * 100}%`)
                            .height(8)
                            .backgroundColor(UiTokens.brand)
                            .borderRadius(4)
                        }
                      }
                      .layoutWeight(1)
                      .height(8)

                      Text(day.hasData ? String(day.rating) : '-')
                        .width(18)
                        .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                        .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
                        .textAlign(TextAlign.End)
                    }
                    .width('100%')
                    .padding({ top: 8, bottom: 8 })
                  })
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
              }
              .width('100%')
            }

            // Mood overview
            if (this.moodRecords.length > 0) {
              Column({ space: UiTokens.gapM }) {
                Text('情绪记录')
                  .fontSize(this.sectionTitle())
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                  .width('100%')

                Column({ space: 0 }) {
                  ForEach(this.moodRecords, (record: MoodSurveyRecord, index: number) => {
                    Row({ space: UiTokens.gapM }) {
                      Column({ space: 2 }) {
                        Text(record.date)
                          .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                          .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                        Text(record.time)
                          .fontSize(UiTokens.textXS)
                          .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)

                      Text(`${record.mood}/5`)
                        .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                    }
                    .width('100%')
                    .padding(14)

                    if (index < this.moodRecords.length - 1) {
                      Divider()
                        .strokeWidth(0.5)
                        .color(UiTokens.divider)
                        .margin({ left: 14 })
                    }
                  })
                }
                .width('100%')
                .padding({ top: 6, bottom: 6 })
                .backgroundColor(UiTokens.bgCard)
                .borderRadius(UiTokens.radiusXL)
                .shadow({
                  radius: this.settings.highContrast ? 0 : 8,
                  color: '#0A000000',
                  offsetX: 0,
                  offsetY: 2
                })
              }
              .width('100%')
            }

            // Bottom hint
            Text('数据仅保存在本地，保护你的隐私')
              .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
              .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 8, bottom: 32 })
          }
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

  private sectionTitle(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }
}
