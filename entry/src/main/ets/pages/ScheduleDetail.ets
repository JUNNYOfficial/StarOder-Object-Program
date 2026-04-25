import { router } from '@kit.ArkUI'
import { Schedule, SubTask, getColorTag } from '../models/ScheduleModel'
import { AppSettings } from '../models/SettingsModel'
import { storage } from '../utils/StorageUtil'
import { SubTaskItem } from '../components/SubTaskItem'
import { UiTokens } from '../design/UiTokens'

@Entry
@Component
struct ScheduleDetail {
  @State schedule: Schedule | null = null
  @State settings: AppSettings = new AppSettings()
  @State allSchedules: Schedule[] = []

  aboutToAppear() {
    this.settings = storage.getSettings()
    this.allSchedules = storage.getSchedules()
    const params = router.getParams() as Record<string, string>
    const id = params?.['id']
    if (id) {
      const found = this.allSchedules.find(s => s.id === id)
      if (found) {
        this.schedule = found
      }
    }
  }

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  private largeFont(): number {
    return this.settings.largeText ? UiTokens.text2XL : UiTokens.textXL
  }

  private tagLabel(): string {
    if (!this.schedule) return ''
    return getColorTag(this.schedule.colorTag).label
  }

  private tagColor(): string {
    if (!this.schedule) return ''
    return getColorTag(this.schedule.colorTag).color
  }

  private tagBg(): string {
    if (!this.schedule) return ''
    return getColorTag(this.schedule.colorTag).bg
  }

  toggleSubTask(subTaskId: string) {
    if (!this.schedule) return
    const all = storage.getSchedules()
    const sIdx = all.findIndex(s => s.id === this.schedule!.id)
    if (sIdx >= 0) {
      const tIdx = all[sIdx].subTasks.findIndex(t => t.id === subTaskId)
      if (tIdx >= 0) {
        all[sIdx].subTasks[tIdx].isCompleted = !all[sIdx].subTasks[tIdx].isCompleted
        storage.saveSchedules(all)
        this.schedule = all[sIdx]
        this.allSchedules = all
      }
    }
  }

  toggleScheduleComplete() {
    if (!this.schedule) return
    const all = storage.getSchedules()
    const idx = all.findIndex(s => s.id === this.schedule!.id)
    if (idx >= 0) {
      all[idx].isCompleted = !all[idx].isCompleted
      storage.saveSchedules(all)
      this.schedule = all[idx]
      this.allSchedules = all
    }
  }

  deleteSchedule() {
    if (!this.schedule) return
    const all = storage.getSchedules().filter(s => s.id !== this.schedule!.id)
    storage.saveSchedules(all)
    router.back()
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

        Text('日程详情')
          .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

        Button() {
          Text('删除')
            .fontSize(this.baseFont())
            .fontColor(UiTokens.warning)
        }
        .backgroundColor('transparent')
        .onClick(() => {
          this.deleteSchedule()
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgSecondary)
      .border({ width: { bottom: this.settings.highContrast ? 2 : 1 }, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })

      if (this.schedule) {
        Scroll() {
          Column({ space: UiTokens.gapL }) {
            // Main info card
            Column({ space: 12 }) {
              Row() {
                Text(this.tagLabel())
                  .fontSize(this.settings.largeText ? 18 : 14)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : this.tagColor())
                  .fontWeight(FontWeight.Bold)
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : this.tagBg())
                  .borderRadius(6)
                  .margin({ right: 12 })

                Column({ space: 4 }) {
                  Text(this.schedule.title)
                    .fontSize(this.largeFont())
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })

                  Row({ space: 8 }) {
                    Text('时间')
                      .fontSize(UiTokens.textXS)
                      .fontColor(this.settings.highContrast ? '#333333' : UiTokens.textSecondary)
                      .padding({ left: 4, right: 4, top: 1, bottom: 1 })
                      .backgroundColor(UiTokens.bgTertiary)
                      .borderRadius(4)
                    Text(`${this.schedule.date}  ${this.schedule.startTime} - ${this.schedule.endTime}`)
                      .fontSize(this.baseFont())
                      .fontColor(this.settings.highContrast ? '#333333' : UiTokens.textSecondary)
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)
              }
              .width('100%')

              // Tag
              Text(this.tagLabel())
                .fontSize(UiTokens.textXS)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : this.tagColor())
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : this.tagBg())
                .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.settings.highContrast ? UiTokens.hcBorder : this.tagColor() })
                .borderRadius(6)

              if (this.schedule.notes) {
                Text(this.schedule.notes)
                  .fontSize(this.baseFont())
                  .fontColor(this.settings.highContrast ? '#333333' : UiTokens.textSecondary)
                  .width('100%')
                  .margin({ top: 4 })
              }
            }
            .width('100%')
            .padding(UiTokens.cardPadding)
            .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPrimary)
            .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })
            .borderRadius(UiTokens.radiusM)

            // Prepare items
            if (this.schedule.prepareItems.length > 0) {
              Column({ space: 10 }) {
                Row({ space: 8 }) {
                  Text('备')
                    .fontSize(UiTokens.textXS)
                    .fontColor(UiTokens.brand)
                    .fontWeight(FontWeight.Bold)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .backgroundColor(UiTokens.brandSoft)
                    .borderRadius(4)
                  Text('准备事项')
                    .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                }
                .width('100%')

                Column({ space: 8 }) {
                  ForEach(this.schedule.prepareItems, (item: string, index: number) => {
                    Row() {
                      Text(`${index + 1}`)
                        .width(24)
                        .height(24)
                        .fontSize(UiTokens.textS)
                        .fontColor(UiTokens.brand)
                        .fontWeight(FontWeight.Bold)
                        .textAlign(TextAlign.Center)
                        .backgroundColor(UiTokens.brandSoft)
                        .borderRadius(6)
                        .margin({ right: 10 })
                      Text(item)
                        .fontSize(this.baseFont())
                        .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                        .layoutWeight(1)
                    }
                    .width('100%')
                    .padding(12)
                    .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgSecondary)
                    .border({ width: this.settings.highContrast ? 1.5 : 1, color: this.settings.highContrast ? UiTokens.hcBorder : UiTokens.border })
                    .borderRadius(UiTokens.radiusS)
                  })
                }
                .width('100%')
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }

            // Sub tasks
            if (this.schedule.subTasks.length > 0) {
              Column({ space: 10 }) {
                Row({ space: 8 }) {
                  Text('步')
                    .fontSize(UiTokens.textXS)
                    .fontColor(UiTokens.brand)
                    .fontWeight(FontWeight.Bold)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .backgroundColor(UiTokens.brandSoft)
                    .borderRadius(4)
                  Text('分步执行')
                    .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                }
                .width('100%')

                Text('一步一步来，不用着急')
                  .fontSize(this.baseFont())
                  .fontColor(this.settings.highContrast ? '#333333' : UiTokens.textSecondary)
                  .width('100%')

                Column({ space: 0 }) {
                  ForEach(this.schedule.subTasks, (subTask: SubTask, index: number) => {
                    SubTaskItem({
                      subTask: subTask,
                      settings: this.settings,
                      index: index,
                      onToggle: () => {
                        this.toggleSubTask(subTask.id)
                      }
                    })
                  })
                }
                .width('100%')
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }

            // Complete button
            Button(this.schedule.isCompleted ? '已完成' : '标记为完成')
              .width('100%')
              .height(this.settings.largeText ? 56 : 48)
              .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
              .fontWeight(FontWeight.Bold)
              .fontColor(UiTokens.textInverse)
              .backgroundColor(this.schedule.isCompleted
                ? UiTokens.confirm
                : this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
              .borderRadius(UiTokens.radiusM)
              .margin({ top: 12, bottom: 32 })
              .onClick(() => {
                this.toggleScheduleComplete()
              })
          }
          .width('100%')
          .padding(UiTokens.pagePadding)
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      } else {
        Column() {
          Text('找不到该日程')
            .fontSize(this.largeFont())
            .fontColor(this.settings.highContrast ? '#333333' : UiTokens.textSecondary)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgSecondary)
  }
}
