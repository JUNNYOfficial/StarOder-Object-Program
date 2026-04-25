import { router } from '@kit.ArkUI'
import {
  Task, SubTask, UserPreferences, TaskTemplate,
  TaskType, TaskIntensity, TimeBlock, Priority, RepeatMode,
  getTypeConfig, getIntensityConfig, getTimeBlockConfig
} from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { UiTokens } from '../design/UiTokens'

@Entry
@Component
struct AddSchedule {
  @State title: string = ''
  @State selectedType: TaskType = TaskType.THINK
  @State selectedIntensity: TaskIntensity = TaskIntensity.LOW
  @State selectedTimeBlock: TimeBlock = TimeBlock.MORNING
  @State selectedPriority: Priority = Priority.MEDIUM
  @State selectedRepeat: RepeatMode = RepeatMode.NONE
  @State prepareInput: string = ''
  @State subTaskInput: string = ''
  @State prepareItems: string[] = []
  @State subTasks: string[] = []
  @State startTime: string = '09:00'
  @State endTime: string = '10:00'
  @State settings: UserPreferences = new UserPreferences()
  @State templates: TaskTemplate[] = []

  aboutToAppear() {
    this.settings = dataStore.getUserPrefs()
    const now = new Date()
    const h = now.getHours()
    if (h < 9) this.selectedTimeBlock = TimeBlock.MORNING
    else if (h < 14) this.selectedTimeBlock = TimeBlock.MORNING
    else if (h < 18) this.selectedTimeBlock = TimeBlock.AFTERNOON
    else this.selectedTimeBlock = TimeBlock.EVENING
    this.initTemplates()
  }

  private initTemplates() {
    const t1 = new TaskTemplate('晨间例行', TaskType.HOME, TaskIntensity.LOW, TimeBlock.MORNING, 30)
    t1.prepareItems.push('准备早餐材料')
    t1.prepareItems.push('打开窗户')
    t1.subTasks.push('洗漱')
    t1.subTasks.push('吃早餐')
    t1.subTasks.push('整理床铺')

    const t2 = new TaskTemplate('深度工作', TaskType.THINK, TaskIntensity.HIGH, TimeBlock.MORNING, 120)
    t2.prepareItems.push('关闭通知')
    t2.prepareItems.push('准备水杯')
    t2.subTasks.push('明确目标')
    t2.subTasks.push('专注执行')
    t2.subTasks.push('简短记录')

    const t3 = new TaskTemplate('运动恢复', TaskType.EXERCISE, TaskIntensity.MEDIUM, TimeBlock.AFTERNOON, 45)
    t3.prepareItems.push('换运动服')
    t3.prepareItems.push('准备水壶')
    t3.subTasks.push('热身')
    t3.subTasks.push('主训练')
    t3.subTasks.push('拉伸放松')

    const t4 = new TaskTemplate('阅读时间', TaskType.THINK, TaskIntensity.LOW, TimeBlock.EVENING, 60)
    t4.prepareItems.push('选择一本书')
    t4.prepareItems.push('调到舒适灯光')
    t4.subTasks.push('找到阅读位置')
    t4.subTasks.push('阅读 20 分钟')
    t4.subTasks.push('做简单笔记')

    const t5 = new TaskTemplate('社交时间', TaskType.SOCIAL, TaskIntensity.MEDIUM, TimeBlock.EVENING, 90)
    t5.prepareItems.push('确认时间和地点')
    t5.prepareItems.push('准备话题')
    t5.subTasks.push('出门')
    t5.subTasks.push('到达会面地点')
    t5.subTasks.push('享受交流')

    this.templates.push(t1)
    this.templates.push(t2)
    this.templates.push(t3)
    this.templates.push(t4)
    this.templates.push(t5)
  }

  private applyTemplate(tmpl: TaskTemplate) {
    this.title = tmpl.title
    this.selectedType = tmpl.type
    this.selectedIntensity = tmpl.intensity
    this.selectedTimeBlock = tmpl.timeBlock
    this.prepareItems = tmpl.prepareItems
    this.subTasks = tmpl.subTasks

    const parts = this.startTime.split(':')
    const h = parseInt(parts[0])
    const m = parseInt(parts[1])
    const endMinutes = h * 60 + m + tmpl.durationMinutes
    const endH = Math.floor(endMinutes / 60)
    const endM = endMinutes % 60
    this.endTime = `${String(endH).padStart(2, '0')}:${String(endM).padStart(2, '0')}`
  }

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  private sectionTitle(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  private todayStr(): string {
    const d = new Date()
    const y = d.getFullYear()
    const m = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  addSubTask() {
    if (this.subTaskInput.trim()) {
      this.subTasks.push(this.subTaskInput.trim())
      this.subTaskInput = ''
    }
  }

  addPrepareItem() {
    if (this.prepareInput.trim()) {
      this.prepareItems.push(this.prepareInput.trim())
      this.prepareInput = ''
    }
  }

  saveTask() {
    if (!this.title.trim()) return
    const task = new Task(this.title.trim(), this.todayStr(), this.startTime, this.endTime)
    task.type = this.selectedType
    task.intensity = this.selectedIntensity
    task.timeBlock = this.selectedTimeBlock
    task.priority = this.selectedPriority
    task.repeatMode = this.selectedRepeat
    task.prepareItems = [...this.prepareItems]
    task.subTasks = this.subTasks.map((title, i) => new SubTask(title, String(i)))
    dataStore.addTask(task)
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

        Text('新建日程')
          .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

        Button() {
          Text('保存')
            .fontSize(this.baseFont())
            .fontWeight(FontWeight.Medium)
            .fontColor(UiTokens.brand)
        }
        .backgroundColor('transparent')
        .onClick(() => {
          this.saveTask()
        })
      }
      .width('100%')
      .height(56)
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(UiTokens.bgCard)

      Scroll() {
        Column({ space: UiTokens.gapXL }) {
          // Templates
          Column({ space: UiTokens.gapS }) {
            Text('快速模板')
              .fontSize(this.sectionTitle())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            List({ space: 10 }) {
              ForEach(this.templates, (tmpl: TaskTemplate) => {
                ListItem() {
                  Column({ space: 4 }) {
                    Text(tmpl.title)
                      .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                    Text(`${tmpl.durationMinutes}分钟`)
                      .fontSize(UiTokens.textXS)
                      .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
                  }
                  .width(90)
                  .padding(12)
                  .backgroundColor(this.settings.highContrast ? '#EEEEEE' : UiTokens.bgHover)
                  .borderRadius(UiTokens.radiusL)
                  .alignItems(HorizontalAlign.Center)
                }
                .onClick(() => {
                  this.applyTemplate(tmpl)
                })
              })
            }
            .width('100%')
            .listDirection(Axis.Horizontal)
            .scrollBar(BarState.Off)
          }
          .width('100%')

          // Title input
          Column({ space: UiTokens.gapS }) {
            Text('日程名称')
              .fontSize(this.sectionTitle())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            TextInput({ placeholder: '例如：完成数学作业', text: $$this.title })
              .width('100%')
              .height(50)
              .fontSize(this.baseFont())
              .backgroundColor(UiTokens.bgHover)
              .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
              .borderRadius(UiTokens.radiusL)
              .padding({ left: 14, right: 14 })
          }
          .width('100%')

          // Time
          Column({ space: UiTokens.gapS }) {
            Text('时间')
              .fontSize(this.sectionTitle())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            Row({ space: UiTokens.gapM }) {
              TextInput({ placeholder: '开始', text: $$this.startTime })
                .layoutWeight(1)
                .height(48)
                .fontSize(this.baseFont())
                .backgroundColor(UiTokens.bgHover)
                .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                .borderRadius(UiTokens.radiusL)
                .textAlign(TextAlign.Center)

              Text('至')
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)

              TextInput({ placeholder: '结束', text: $$this.endTime })
                .layoutWeight(1)
                .height(48)
                .fontSize(this.baseFont())
                .backgroundColor(UiTokens.bgHover)
                .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                .borderRadius(UiTokens.radiusL)
                .textAlign(TextAlign.Center)
            }
            .width('100%')
          }
          .width('100%')

          // Type
          Column({ space: UiTokens.gapS }) {
            Text('类型')
              .fontSize(this.sectionTitle())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            Row({ space: 10 }) {
              ForEach([
                TaskType.THINK,
                TaskType.SOCIAL,
                TaskType.HOME,
                TaskType.REST,
                TaskType.EXERCISE
              ], (type: TaskType) => {
                Button() {
                  Text(getTypeConfig(type).label)
                    .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                    .fontColor(this.selectedType === type
                      ? (this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                      : (this.settings.highContrast ? '#555555' : UiTokens.textSecondary))
                }
                .layoutWeight(1)
                .height(42)
                .backgroundColor(this.selectedType === type
                  ? (this.settings.highContrast ? UiTokens.hcBg : UiTokens.brandSoft)
                  : (this.settings.highContrast ? '#EEEEEE' : UiTokens.bgHover))
                .borderRadius(UiTokens.radiusL)
                .onClick(() => {
                  this.selectedType = type
                })
              })
            }
            .width('100%')
          }
          .width('100%')

          // Intensity
          Column({ space: UiTokens.gapS }) {
            Text('强度')
              .fontSize(this.sectionTitle())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            Row({ space: 10 }) {
              ForEach([
                TaskIntensity.LOW,
                TaskIntensity.MEDIUM,
                TaskIntensity.HIGH
              ], (intensity: TaskIntensity) => {
                Button() {
                  Text(getIntensityConfig(intensity).label)
                    .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                    .fontColor(this.selectedIntensity === intensity
                      ? (this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                      : (this.settings.highContrast ? '#555555' : UiTokens.textSecondary))
                }
                .layoutWeight(1)
                .height(42)
                .backgroundColor(this.selectedIntensity === intensity
                  ? (this.settings.highContrast ? UiTokens.hcBg : UiTokens.brandSoft)
                  : (this.settings.highContrast ? '#EEEEEE' : UiTokens.bgHover))
                .borderRadius(UiTokens.radiusL)
                .onClick(() => {
                  this.selectedIntensity = intensity
                })
              })
            }
            .width('100%')
          }
          .width('100%')

          // Time block
          Column({ space: UiTokens.gapS }) {
            Text('时间段')
              .fontSize(this.sectionTitle())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            Row({ space: 10 }) {
              ForEach([
                TimeBlock.MORNING,
                TimeBlock.MORNING,
                TimeBlock.AFTERNOON,
                TimeBlock.EVENING
              ], (block: TimeBlock) => {
                Button() {
                  Text(getTimeBlockConfig(block).label)
                    .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                    .fontColor(this.selectedTimeBlock === block
                      ? (this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                      : (this.settings.highContrast ? '#555555' : UiTokens.textSecondary))
                }
                .layoutWeight(1)
                .height(42)
                .backgroundColor(this.selectedTimeBlock === block
                  ? (this.settings.highContrast ? UiTokens.hcBg : UiTokens.brandSoft)
                  : (this.settings.highContrast ? '#EEEEEE' : UiTokens.bgHover))
                .borderRadius(UiTokens.radiusL)
                .onClick(() => {
                  this.selectedTimeBlock = block
                })
              })
            }
            .width('100%')
          }
          .width('100%')

          // Prepare items
          Column({ space: UiTokens.gapS }) {
            Text('准备事项')
              .fontSize(this.sectionTitle())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            Row({ space: 10 }) {
              TextInput({ placeholder: '添加准备项，如：带上书本', text: $$this.prepareInput })
                .layoutWeight(1)
                .height(48)
                .fontSize(this.baseFont())
                .backgroundColor(UiTokens.bgHover)
                .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                .borderRadius(UiTokens.radiusL)

              Button('+')
                .width(48)
                .height(48)
                .fontSize(22)
                .fontColor(UiTokens.brand)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusL)
                .onClick(() => {
                  this.addPrepareItem()
                })
            }
            .width('100%')

            if (this.prepareItems.length > 0) {
              Column({ space: UiTokens.gapS }) {
                ForEach(this.prepareItems, (item: string) => {
                  Row() {
                    Text(item)
                      .fontSize(this.baseFont())
                      .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                      .layoutWeight(1)

                    Button() {
                      Text('×')
                        .fontSize(18)
                        .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
                    }
                    .width(32)
                    .height(32)
                    .backgroundColor('transparent')
                    .onClick(() => {
                      const idx = this.prepareItems.indexOf(item)
                      if (idx >= 0) this.prepareItems.splice(idx, 1)
                    })
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor(UiTokens.bgHover)
                  .borderRadius(UiTokens.radiusM)
                })
              }
              .width('100%')
            }
          }
          .width('100%')

          // Sub tasks
          Column({ space: UiTokens.gapS }) {
            Text('分步执行')
              .fontSize(this.sectionTitle())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            Row({ space: 10 }) {
              TextInput({ placeholder: '添加步骤，如：先查资料', text: $$this.subTaskInput })
                .layoutWeight(1)
                .height(48)
                .fontSize(this.baseFont())
                .backgroundColor(UiTokens.bgHover)
                .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                .borderRadius(UiTokens.radiusL)

              Button('+')
                .width(48)
                .height(48)
                .fontSize(22)
                .fontColor(UiTokens.brand)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusL)
                .onClick(() => {
                  this.addSubTask()
                })
            }
            .width('100%')

            if (this.subTasks.length > 0) {
              Column({ space: UiTokens.gapS }) {
                ForEach(this.subTasks, (item: string, index: number) => {
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

                    Button() {
                      Text('×')
                        .fontSize(18)
                        .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
                    }
                    .width(32)
                    .height(32)
                    .backgroundColor('transparent')
                    .onClick(() => {
                      this.subTasks.splice(index, 1)
                    })
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor(UiTokens.bgHover)
                  .borderRadius(UiTokens.radiusM)
                })
              }
              .width('100%')
            }
          }
          .width('100%')

          // Save button
          Button('保存日程')
            .width('100%')
            .height(52)
            .fontSize(UiTokens.textL)
            .fontWeight(FontWeight.Medium)
            .fontColor(UiTokens.textInverse)
            .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
            .borderRadius(UiTokens.radiusXL)
            .margin({ top: 8, bottom: 40 })
            .onClick(() => {
              this.saveTask()
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
    .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPage)
  }
}
