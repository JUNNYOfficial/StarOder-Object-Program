import { router } from '@kit.ArkUI'
import { Schedule, SubTask, getColorTag, COLOR_TAG_KEYS } from '../models/ScheduleModel'
import { AppSettings } from '../models/SettingsModel'
import { storage } from '../utils/StorageUtil'
import { UiTokens } from '../design/UiTokens'

@Entry
@Component
struct AddSchedule {
  @State settings: AppSettings = new AppSettings()
  @State title: string = ''
  @State date: string = ''
  @State startTime: string = '09:00'
  @State endTime: string = '10:00'
  @State selectedTag: string = 'calm'
  @State notes: string = ''
  @State prepareItems: string[] = []
  @State newPrepare: string = ''
  @State subTasks: string[] = []
  @State newSubTask: string = ''

  aboutToAppear() {
    this.settings = storage.getSettings()
    const now = new Date()
    const y = now.getFullYear()
    const m = String(now.getMonth() + 1).padStart(2, '0')
    const d = String(now.getDate()).padStart(2, '0')
    this.date = `${y}-${m}-${d}`
  }

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  private labelFont(): number {
    return this.settings.largeText ? UiTokens.textM : UiTokens.textS
  }

  saveSchedule() {
    if (!this.title.trim()) {
      return
    }

    const schedule = new Schedule(this.title.trim(), this.date, this.startTime, this.endTime)
    schedule.colorTag = this.selectedTag
    schedule.notes = this.notes.trim()
    schedule.prepareItems = this.prepareItems.filter(i => i.trim())
    schedule.subTasks = this.subTasks.filter(t => t.trim()).map(t => new SubTask(t.trim()))

    const all = storage.getSchedules()
    all.push(schedule)
    storage.saveSchedules(all)

    router.back()
  }

  build() {
    Column() {
      // Header
      Row() {
        Button() {
          Text('取消')
            .fontSize(this.baseFont())
            .fontColor(this.settings.highContrast ? '#333333' : UiTokens.textSecondary)
        }
        .backgroundColor('transparent')
        .onClick(() => {
          router.back()
        })

        Text('新日程')
          .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

        Button('保存')
          .fontSize(this.baseFont())
          .fontColor(UiTokens.textInverse)
          .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
          .borderRadius(UiTokens.radiusS)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            this.saveSchedule()
          })
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
          // Title
          Column({ space: 6 }) {
            Text('日程名称 *')
              .fontSize(this.labelFont())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

            TextInput({ placeholder: '例如：吃早餐、看医生' })
              .fontSize(this.baseFont())
              .height(this.settings.largeText ? 56 : 48)
              .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPrimary)
              .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })
              .borderRadius(UiTokens.radiusM)
              .padding({ left: 12, right: 12 })
              .onChange((val) => {
                this.title = val
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // Date & Time
          Row({ space: 12 }) {
            Column({ space: 6 }) {
              Text('日期')
                .fontSize(this.labelFont())
                .fontWeight(FontWeight.Medium)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              TextInput({ text: this.date })
                .fontSize(this.baseFont())
                .height(this.settings.largeText ? 56 : 48)
                .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPrimary)
                .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })
                .borderRadius(UiTokens.radiusM)
                .onChange((val) => {
                  this.date = val
                })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Column({ space: 6 }) {
              Text('开始')
                .fontSize(this.labelFont())
                .fontWeight(FontWeight.Medium)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              TextInput({ text: this.startTime })
                .fontSize(this.baseFont())
                .height(this.settings.largeText ? 56 : 48)
                .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPrimary)
                .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })
                .borderRadius(UiTokens.radiusM)
                .onChange((val) => {
                  this.startTime = val
                })
            }
            .width(80)
            .alignItems(HorizontalAlign.Start)

            Column({ space: 6 }) {
              Text('结束')
                .fontSize(this.labelFont())
                .fontWeight(FontWeight.Medium)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              TextInput({ text: this.endTime })
                .fontSize(this.baseFont())
                .height(this.settings.largeText ? 56 : 48)
                .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPrimary)
                .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })
                .borderRadius(UiTokens.radiusM)
                .onChange((val) => {
                  this.endTime = val
                })
            }
            .width(80)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')

          // Color tag
          Column({ space: 6 }) {
            Text('感受标签')
              .fontSize(this.labelFont())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

            Row({ space: 8 }) {
              ForEach(COLOR_TAG_KEYS, (key: string) => {
                Button(getColorTag(key).label)
                  .fontSize(this.labelFont())
                  .height(this.settings.largeText ? 44 : 36)
                  .padding({ left: 16, right: 16 })
                  .backgroundColor(this.selectedTag === key
                    ? (this.settings.highContrast ? UiTokens.hcText : getColorTag(key).color)
                    : (this.settings.highContrast ? UiTokens.hcBg : getColorTag(key).bg))
                  .fontColor(this.selectedTag === key ? '#FFFFFF' : (this.settings.highContrast ? UiTokens.hcText : getColorTag(key).color))
                  .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.settings.highContrast ? UiTokens.hcBorder : getColorTag(key).color })
                  .borderRadius(UiTokens.radiusS)
                  .onClick(() => {
                    this.selectedTag = key
                  })
              })
            }
            .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // Prepare items
          Column({ space: 6 }) {
            Text('准备事项')
              .fontSize(this.labelFont())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            Text('提前列出需要带的东西，减少出门焦虑')
              .fontSize(UiTokens.textXS)
              .fontColor(this.settings.highContrast ? '#333333' : UiTokens.textSecondary)

            if (this.prepareItems.length > 0) {
              Column({ space: 6 }) {
                ForEach(this.prepareItems, (item: string, index: number) => {
                  Row() {
                    Text(item)
                      .fontSize(this.baseFont())
                      .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                      .layoutWeight(1)
                    Text('×')
                      .fontSize(this.baseFont())
                      .fontColor(this.settings.highContrast ? '#555555' : UiTokens.tertiaryText)
                      .onClick(() => {
                        this.prepareItems.splice(index, 1)
                        this.prepareItems = [...this.prepareItems]
                      })
                  }
                  .width('100%')
                  .padding(10)
                  .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgSecondary)
                  .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })
                  .borderRadius(UiTokens.radiusS)
                })
              }
              .width('100%')
            }

            Row({ space: 8 }) {
              TextInput({ text: this.newPrepare, placeholder: '例如：带身份证' })
                .fontSize(this.baseFont())
                .height(this.settings.largeText ? 48 : 40)
                .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPrimary)
                .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })
                .borderRadius(UiTokens.radiusS)
                .layoutWeight(1)
                .onChange((val) => {
                  this.newPrepare = val
                })
              Button('添加')
                .fontSize(this.labelFont())
                .height(this.settings.largeText ? 48 : 40)
                .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                .fontColor(UiTokens.textInverse)
                .padding({ left: 12, right: 12 })
                .onClick(() => {
                  if (this.newPrepare.trim()) {
                    this.prepareItems.push(this.newPrepare.trim())
                    this.prepareItems = [...this.prepareItems]
                    this.newPrepare = ''
                  }
                })
            }
            .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // Sub tasks
          Column({ space: 6 }) {
            Text('分解步骤')
              .fontSize(this.labelFont())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            Text('把大任务拆成小步骤，降低执行焦虑')
              .fontSize(UiTokens.textXS)
              .fontColor(this.settings.highContrast ? '#333333' : UiTokens.textSecondary)

            if (this.subTasks.length > 0) {
              Column({ space: 6 }) {
                ForEach(this.subTasks, (task: string, index: number) => {
                  Row() {
                    Text(`${index + 1}. ${task}`)
                      .fontSize(this.baseFont())
                      .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                      .layoutWeight(1)
                    Text('×')
                      .fontSize(this.baseFont())
                      .fontColor(this.settings.highContrast ? '#555555' : UiTokens.tertiaryText)
                      .onClick(() => {
                        this.subTasks.splice(index, 1)
                        this.subTasks = [...this.subTasks]
                      })
                  }
                  .width('100%')
                  .padding(10)
                  .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgSecondary)
                  .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })
                  .borderRadius(UiTokens.radiusS)
                })
              }
              .width('100%')
            }

            Row({ space: 8 }) {
              TextInput({ text: this.newSubTask, placeholder: '例如：先找出衣服' })
                .fontSize(this.baseFont())
                .height(this.settings.largeText ? 48 : 40)
                .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPrimary)
                .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })
                .borderRadius(UiTokens.radiusS)
                .layoutWeight(1)
                .onChange((val) => {
                  this.newSubTask = val
                })
              Button('添加')
                .fontSize(this.labelFont())
                .height(this.settings.largeText ? 48 : 40)
                .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                .fontColor(UiTokens.textInverse)
                .padding({ left: 12, right: 12 })
                .onClick(() => {
                  if (this.newSubTask.trim()) {
                    this.subTasks.push(this.newSubTask.trim())
                    this.subTasks = [...this.subTasks]
                    this.newSubTask = ''
                  }
                })
            }
            .width('100%')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // Notes
          Column({ space: 6 }) {
            Text('备注')
              .fontSize(this.labelFont())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

            TextArea({ placeholder: '其他需要注意的事...' })
              .fontSize(this.baseFont())
              .height(100)
              .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPrimary)
              .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })
              .borderRadius(UiTokens.radiusM)
              .padding(12)
              .onChange((val) => {
                this.notes = val
              })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)

          // Save button
          Button('保存日程')
            .width('100%')
            .height(this.settings.largeText ? 56 : 48)
            .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
            .fontWeight(FontWeight.Bold)
            .fontColor(UiTokens.textInverse)
            .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
            .borderRadius(UiTokens.radiusM)
            .margin({ top: 12, bottom: 32 })
            .onClick(() => {
              this.saveSchedule()
            })
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
