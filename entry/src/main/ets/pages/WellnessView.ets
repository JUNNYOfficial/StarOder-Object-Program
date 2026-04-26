import { router } from '@kit.ArkUI'
import { UserPreferences, MoodSurveyRecord, EnergyRecord, Task, TaskStatus } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { UiTokens } from '../design/UiTokens'
import { todayStr } from '../utils/DateUtils'

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
  @State weekdayLabels: string[] = ['日', '一', '二', '三', '四', '五', '六']
  @State showEnergyInput: boolean = false
  @State showMoodInput: boolean = false
  @State energyRating: number = 3
  @State energyNote: string = ''
  @State moodRating: number = 3
  @State moodTrigger: string = ''
  @State moodContext: string = ''

  // Focus stats enhancement
  @State dailyFocusData: Array<{ label: string, minutes: number }> = []
  @State weeklyFocusData: Array<{ label: string, totalMinutes: number, sessions: number }> = []
  @State maxDailyMinutes: number = 1
  @State maxWeeklyMinutes: number = 1
  @State taskCompletionRate: number = 0
  @State totalTasksThisWeek: number = 0
  @State completedTasksThisWeek: number = 0

  aboutToAppear() {
    this.settings = dataStore.getUserPrefs()
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
    this.loadFocusTrends()
    this.loadTaskCompletion()
    this.hasAnyData = this.totalFocusMinutes > 0 || this.moodRecords.length > 0 ||
      this.dayEnergies.filter(d => d.hasData).length > 0 ||
      this.dailyFocusData.some(d => d.minutes > 0)
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

  private loadFocusTrends() {
    this.dailyFocusData = dataStore.getFocusDailyStats(7)
    this.weeklyFocusData = dataStore.getFocusWeeklyStats(4)
    this.maxDailyMinutes = Math.max(1, ...this.dailyFocusData.map(d => d.minutes))
    this.maxWeeklyMinutes = Math.max(1, ...this.weeklyFocusData.map(d => d.totalMinutes))
  }

  private loadTaskCompletion() {
    const now = new Date()
    const startOfWeek = new Date(now)
    const dayOfWeek = now.getDay() === 0 ? 7 : now.getDay()
    startOfWeek.setDate(now.getDate() - dayOfWeek + 1)
    const startStr = this.formatDate(startOfWeek)
    const endStr = this.formatDate(now)

    let total = 0
    let completed = 0
    const allTasks = dataStore.getActiveTasks()
    for (let i = 0; i < allTasks.length; i++) {
      const t = allTasks[i]
      if (t.date >= startStr && t.date <= endStr) {
        total++
        if (t.status === TaskStatus.DONE) {
          completed++
        }
      }
    }
    this.totalTasksThisWeek = total
    this.completedTasksThisWeek = completed
    this.taskCompletionRate = total > 0 ? Math.round((completed / total) * 100) : 0
  }

  saveEnergyRecord() {
    const record = new EnergyRecord(todayStr(), this.energyRating)
    record.note = this.energyNote.trim()
    dataStore.saveEnergyRecord(record)
    this.energyNote = ''
    this.energyRating = 3
    this.showEnergyInput = false
    this.loadData()
  }

  saveMoodRecord() {
    const now = new Date()
    const timeStr = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
    const record = new MoodSurveyRecord(todayStr(), timeStr, this.moodRating)
    record.trigger = this.moodTrigger.trim()
    record.context = this.moodContext.trim()
    dataStore.saveMoodSurvey(record)
    this.moodTrigger = ''
    this.moodContext = ''
    this.moodRating = 3
    this.showMoodInput = false
    this.loadData()
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
            // Task completion rate
            if (this.totalTasksThisWeek > 0) {
              Column({ space: UiTokens.gapM }) {
                Text('本周完成率')
                  .fontSize(this.sectionTitle())
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                  .width('100%')

                Row({ space: UiTokens.gapM }) {
                  Column({ space: 4 }) {
                    Text(`${this.taskCompletionRate}%`)
                      .fontSize(this.largeFont())
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                    Text(`${this.completedTasksThisWeek}/${this.totalTasksThisWeek} 日程`)
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

                  Stack() {
                    Column()
                      .width('100%')
                      .height(8)
                      .backgroundColor(UiTokens.divider)
                      .borderRadius(4)
                    Column()
                      .width(`${this.taskCompletionRate}%`)
                      .height(8)
                      .backgroundColor(UiTokens.brand)
                      .borderRadius(4)
                  }
                  .layoutWeight(2)
                  .height(8)
                }
                .width('100%')
                .alignItems(VerticalAlign.Center)
              }
              .width('100%')
            }

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

            // Daily focus chart
            if (this.dailyFocusData.some(d => d.minutes > 0)) {
              Column({ space: UiTokens.gapM }) {
                Text('最近7天专注时长')
                  .fontSize(this.sectionTitle())
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                  .width('100%')

                Row({ space: 6 }) {
                  ForEach(this.dailyFocusData, (day: { label: string, minutes: number }) => {
                    Column({ space: 4 }) {
                      Stack({ alignContent: Alignment.Bottom }) {
                        Column()
                          .width('100%')
                          .height(100)
                          .backgroundColor(UiTokens.divider)
                          .borderRadius(UiTokens.radiusS)

                        if (day.minutes > 0) {
                          Column()
                            .width('100%')
                            .height(`${(day.minutes / this.maxDailyMinutes) * 100}%`)
                            .backgroundColor(UiTokens.brand)
                            .borderRadius(UiTokens.radiusS)
                        }
                      }
                      .width('100%')
                      .height(100)

                      Text(day.label)
                        .fontSize(UiTokens.textXS)
                        .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
                        .textAlign(TextAlign.Center)

                      if (day.minutes > 0) {
                        Text(`${day.minutes}`)
                          .fontSize(UiTokens.textXS)
                          .fontColor(UiTokens.brand)
                          .fontWeight(FontWeight.Medium)
                          .textAlign(TextAlign.Center)
                      }
                    }
                    .layoutWeight(1)
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

            // Weekly focus trend
            if (this.weeklyFocusData.some(w => w.totalMinutes > 0)) {
              Column({ space: UiTokens.gapM }) {
                Text('周专注趋势')
                  .fontSize(this.sectionTitle())
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                  .width('100%')

                Column({ space: UiTokens.gapS }) {
                  ForEach(this.weeklyFocusData, (week: { label: string, totalMinutes: number, sessions: number }) => {
                    Row({ space: 10 }) {
                      Text(week.label)
                        .width(70)
                        .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                        .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textSecondary)

                      Stack() {
                        Row()
                          .width('100%')
                          .height(8)
                          .backgroundColor(UiTokens.divider)
                          .borderRadius(4)
                        if (week.totalMinutes > 0) {
                          Row()
                            .width(`${(week.totalMinutes / this.maxWeeklyMinutes) * 100}%`)
                            .height(8)
                            .backgroundColor(UiTokens.brand)
                            .borderRadius(4)
                        }
                      }
                      .layoutWeight(1)
                      .height(8)

                      Text(`${week.totalMinutes}分`)
                        .width(50)
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
                        .fontColor(day.date === todayStr()
                          ? (this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                          : (this.settings.highContrast ? '#555555' : UiTokens.textTertiary))
                        .fontWeight(day.date === todayStr() ? FontWeight.Bold : FontWeight.Regular)
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
                  }, (day: DayEnergy) => day.date)
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
                  }, (record: MoodSurveyRecord) => record.date + '_' + record.time)
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

            // Record entry
            Column({ space: UiTokens.gapM }) {
              Text('记录当下')
                .fontSize(this.sectionTitle())
                .fontWeight(FontWeight.Medium)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .width('100%')

              Row({ space: UiTokens.gapM }) {
                Button('记录能量')
                  .layoutWeight(1)
                  .height(48)
                  .fontSize(this.baseFont())
                  .fontColor(UiTokens.textInverse)
                  .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                  .borderRadius(UiTokens.radiusXL)
                  .onClick(() => {
                    this.showEnergyInput = !this.showEnergyInput
                    this.showMoodInput = false
                  })

                Button('记录情绪')
                  .layoutWeight(1)
                  .height(48)
                  .fontSize(this.baseFont())
                  .fontColor(UiTokens.textInverse)
                  .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                  .borderRadius(UiTokens.radiusXL)
                  .onClick(() => {
                    this.showMoodInput = !this.showMoodInput
                    this.showEnergyInput = false
                  })
              }
              .width('100%')

              if (this.showEnergyInput) {
                Column({ space: UiTokens.gapM }) {
                  Text('今天感觉有多少能量？')
                    .fontSize(this.baseFont())
                    .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                    .width('100%')

                  Row({ space: UiTokens.gapM }) {
                    ForEach([1, 2, 3, 4, 5], (n: number) => {
                      Button(String(n))
                        .width(48)
                        .height(48)
                        .fontSize(this.baseFont())
                        .fontColor(this.energyRating === n ? UiTokens.textInverse : UiTokens.textPrimary)
                        .backgroundColor(this.energyRating === n
                          ? (this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                          : (this.settings.highContrast ? '#EEEEEE' : UiTokens.bgHover))
                        .borderRadius(UiTokens.radiusL)
                        .onClick(() => { this.energyRating = n })
                    })
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)

                  TextInput({ placeholder: '可选：写点什么', text: $$this.energyNote })
                    .width('100%')
                    .height(44)
                    .fontSize(this.baseFont())
                    .backgroundColor(UiTokens.bgHover)
                    .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                    .borderRadius(UiTokens.radiusL)

                  Button('保存能量记录')
                    .width('100%')
                    .height(48)
                    .fontSize(this.baseFont())
                    .fontColor(UiTokens.textInverse)
                    .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                    .borderRadius(UiTokens.radiusXL)
                    .onClick(() => { this.saveEnergyRecord() })
                }
                .width('100%')
                .padding(UiTokens.cardPadding)
                .backgroundColor(UiTokens.bgCard)
                .borderRadius(UiTokens.radiusXL)
              }

              if (this.showMoodInput) {
                Column({ space: UiTokens.gapM }) {
                  Text('此刻心情怎么样？')
                    .fontSize(this.baseFont())
                    .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                    .width('100%')

                  Row({ space: UiTokens.gapM }) {
                    ForEach([1, 2, 3, 4, 5], (n: number) => {
                      Button(String(n))
                        .width(48)
                        .height(48)
                        .fontSize(this.baseFont())
                        .fontColor(this.moodRating === n ? UiTokens.textInverse : UiTokens.textPrimary)
                        .backgroundColor(this.moodRating === n
                          ? (this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                          : (this.settings.highContrast ? '#EEEEEE' : UiTokens.bgHover))
                        .borderRadius(UiTokens.radiusL)
                        .onClick(() => { this.moodRating = n })
                    })
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceBetween)

                  TextInput({ placeholder: '什么触发了这个情绪？', text: $$this.moodTrigger })
                    .width('100%')
                    .height(44)
                    .fontSize(this.baseFont())
                    .backgroundColor(UiTokens.bgHover)
                    .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                    .borderRadius(UiTokens.radiusL)

                  TextInput({ placeholder: '当时在做什么？', text: $$this.moodContext })
                    .width('100%')
                    .height(44)
                    .fontSize(this.baseFont())
                    .backgroundColor(UiTokens.bgHover)
                    .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                    .borderRadius(UiTokens.radiusL)

                  Button('保存情绪记录')
                    .width('100%')
                    .height(48)
                    .fontSize(this.baseFont())
                    .fontColor(UiTokens.textInverse)
                    .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                    .borderRadius(UiTokens.radiusXL)
                    .onClick(() => { this.saveMoodRecord() })
                }
                .width('100%')
                .padding(UiTokens.cardPadding)
                .backgroundColor(UiTokens.bgCard)
                .borderRadius(UiTokens.radiusXL)
              }
            }
            .width('100%')

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
