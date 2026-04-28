import { router } from '@kit.ArkUI'
import { Task, SubTask, TaskStatus, UserPreferences, getTypeConfig, getTimeBlockConfig } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { SubTaskItem } from '../components/SubTaskItem'
import { UiTokens } from '../design/UiTokens'

@Entry
@Component
struct ScheduleDetail {
  @State task: Task | null = null
  @State settings: UserPreferences = new UserPreferences()

  aboutToAppear() {
    this.settings = dataStore.getUserPrefs()
    const params = router.getParams() as Record<string, string>
    const id = params?.['id']
    if (id) {
      let found = dataStore.getActiveTasks().find(t => t.id === id)
      if (!found) {
        // 可能是重复任务实例（id 格式为 originalId_YYYY-MM-DD），回退到原始任务
        found = dataStore.getTaskById(id)
      }
      if (found) {
        this.task = found
      }
    }
  }

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  private largeFont(): number {
    return this.settings.largeText ? UiTokens.text2XL : UiTokens.textXL
  }

  private isExternalTask(): boolean {
    return this.task ? this.task.source !== 'manual' && this.task.source !== '' : false
  }

  private sourceLabel(): string {
    if (!this.task) return ''
    if (this.task.source === 'feishu') return '来自飞书'
    return '外部日程'
  }

  private statusText(): string {
    if (!this.task) return ''
    switch (this.task.status) {
      case TaskStatus.TODO: return '待开始'
      case TaskStatus.STARTED: return '进行中'
      case TaskStatus.MOSTLY: return '快完成'
      case TaskStatus.DONE: return '已完成'
      case TaskStatus.PAUSED: return '已暂停'
      default: return ''
    }
  }

  private statusColor(): string {
    if (!this.task) return ''
    switch (this.task.status) {
      case TaskStatus.TODO: return UiTokens.textTertiary
      case TaskStatus.STARTED: return UiTokens.active
      case TaskStatus.MOSTLY: return UiTokens.brand
      case TaskStatus.DONE: return UiTokens.done
      case TaskStatus.PAUSED: return UiTokens.paused
      default: return UiTokens.textTertiary
    }
  }

  toggleSubTask(subTaskId: string) {
    if (!this.task) return
    const all = dataStore.getActiveTasks()
    // 重复任务实例的 id 格式为 originalId_YYYY-MM-DD，需要找到原始任务
    let taskId = this.task.id
    const underscoreIdx = taskId.lastIndexOf('_')
    if (underscoreIdx > 0) {
      const suffix = taskId.substring(underscoreIdx + 1)
      if (suffix.length === 10 && suffix.charAt(4) === '-' && suffix.charAt(7) === '-') {
        taskId = taskId.substring(0, underscoreIdx)
      }
    }
    const sIdx = all.findIndex(t => t.id === taskId)
    if (sIdx >= 0) {
      const tIdx = all[sIdx].subTasks.findIndex(t => t.id === subTaskId)
      if (tIdx >= 0) {
        all[sIdx].subTasks[tIdx].completed = !all[sIdx].subTasks[tIdx].completed
        dataStore.saveTasks(all)
        // 同步当前显示的 task 实例中的子任务状态
        const currentStIdx = this.task.subTasks.findIndex(t => t.id === subTaskId)
        if (currentStIdx >= 0) {
          this.task.subTasks[currentStIdx].completed = all[sIdx].subTasks[tIdx].completed
        }
      }
    }
  }

  advanceStatus() {
    if (!this.task) return
    if (dataStore.advanceTaskStatus(this.task.id)) {
      const updated = dataStore.getTaskById(this.task.id)
      if (updated) {
        this.task.status = updated.status
      }
    }
  }

  deleteTask() {
    if (!this.task) return
    dataStore.softDeleteTask(this.task.id)
    router.back()
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

        Text('日程详情')
          .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

        Row({ space: 8 }) {
          if (!this.isExternalTask()) {
            Button() {
              Text('编辑')
                .fontSize(this.baseFont())
                .fontColor(UiTokens.brand)
            }
            .backgroundColor('transparent')
            .onClick(() => {
              if (this.task) {
                router.pushUrl({ url: 'pages/AddSchedule', params: { id: this.task.id } })
              }
            })

            Button() {
              Text('删除')
                .fontSize(this.baseFont())
                .fontColor(UiTokens.paused)
            }
            .backgroundColor('transparent')
            .onClick(() => {
              this.deleteTask()
            })
          } else {
            Text(this.sourceLabel())
              .fontSize(UiTokens.textS)
              .fontColor(UiTokens.brand)
              .fontWeight(FontWeight.Medium)
              .backgroundColor(UiTokens.brandSoft)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(UiTokens.radiusS)
          }
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(UiTokens.bgCard)

      if (this.task) {
        Scroll() {
          Column({ space: UiTokens.gapXL }) {
            // Main info
            Column({ space: UiTokens.gapM }) {
              Text(this.task.title)
                .fontSize(this.largeFont())
                .fontWeight(FontWeight.Bold)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .width('100%')

              Row({ space: 10 }) {
                Text(this.statusText())
                  .fontSize(UiTokens.textS)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : this.statusColor())
                  .fontWeight(FontWeight.Medium)

                Text(`${getTypeConfig(this.task.type).label} · ${getTimeBlockConfig(this.task.timeBlock).label}`)
                  .fontSize(UiTokens.textS)
                  .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)

                Text(this.task.startTime || this.task.endTime
                  ? `${this.task.date}  ${this.task.startTime || '-'} - ${this.task.endTime || '-'}`
                  : this.task.date)
                  .fontSize(UiTokens.textS)
                  .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)

                if (this.isExternalTask()) {
                  Text(this.sourceLabel())
                    .fontSize(UiTokens.textXS)
                    .fontColor(UiTokens.brand)
                    .fontWeight(FontWeight.Medium)
                    .backgroundColor(UiTokens.brandSoft)
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .borderRadius(UiTokens.radiusS)
                }
              }
              .width('100%')

              if (this.task.notes) {
                Text(this.task.notes)
                  .fontSize(this.baseFont())
                  .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
                  .width('100%')
                  .margin({ top: 4 })
              }
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

            // Prepare items
            if (this.task.prepareItems.length > 0) {
              Column({ space: UiTokens.gapM }) {
                Text('准备事项')
                  .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                  .width('100%')

                Column({ space: UiTokens.gapS }) {
                  ForEach(this.task.prepareItems, (item: string, index: number) => {
                    Row() {
                      Text(`${index + 1}`)
                        .width(22)
                        .height(22)
                        .fontSize(UiTokens.textXS)
                        .fontColor(UiTokens.textSecondary)
                        .fontWeight(FontWeight.Medium)
                        .textAlign(TextAlign.Center)
                        .backgroundColor(UiTokens.bgHover)
                        .borderRadius(6)
                        .margin({ right: 10 })
                      Text(item)
                        .fontSize(this.baseFont())
                        .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                        .layoutWeight(1)
                    }
                    .width('100%')
                    .padding(14)
                    .backgroundColor(UiTokens.bgCard)
                    .borderRadius(UiTokens.radiusL)
                  })
                }
                .width('100%')
              }
              .width('100%')
              .alignItems(HorizontalAlign.Start)
            }

            // Sub tasks
            if (this.task.subTasks.length > 0) {
              Column({ space: UiTokens.gapM }) {
                Text('分步执行')
                  .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                  .width('100%')

                Text('一步一步来，不用着急')
                  .fontSize(this.baseFont())
                  .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
                  .width('100%')

                Column({ space: 0 }) {
                  ForEach(this.task.subTasks, (subTask: SubTask, index: number) => {
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

            // Status button
            Button(this.statusText())
              .width('100%')
              .height(52)
              .fontSize(UiTokens.textL)
              .fontWeight(FontWeight.Medium)
              .fontColor(UiTokens.textInverse)
              .backgroundColor(this.settings.highContrast ? UiTokens.hcText : this.statusColor())
              .borderRadius(UiTokens.radiusXL)
              .margin({ top: 8, bottom: 32 })
              .onClick(() => {
                this.advanceStatus()
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
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPage)
  }
}
