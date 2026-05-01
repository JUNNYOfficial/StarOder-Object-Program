import { Task, TimeBlock, getTimeBlockConfig } from 'commons'
import { UserPreferences } from 'commons'
import { VisualTaskCard } from 'commons'
import { UiTokens } from 'commons'

@Component
export struct VisualScheduleView {
  @Prop tasks: Task[]
  @Prop settings: UserPreferences
  onClickTask: (task: Task) => void = () => {}

  private blockTasks(block: TimeBlock): Task[] {
    const result: Task[] = []
    for (let i = 0; i < this.tasks.length; i++) {
      const t = this.tasks[i]
      if (t && t.timeBlock === block) {
        result.push(t)
      }
    }
    return result
  }

  private hasBlockTasks(block: TimeBlock): boolean {
    for (let i = 0; i < this.tasks.length; i++) {
      const t = this.tasks[i]
      if (t && t.timeBlock === block) {
        return true
      }
    }
    return false
  }

  private sectionFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  @Builder
  BlockSection(block: TimeBlock) {
    Column({ space: UiTokens.gapS }) {
      // Section header
      Row({ space: UiTokens.gapS }) {
        Text(getTimeBlockConfig(block).label)
          .fontSize(this.sectionFont())
          .fontWeight(FontWeight.Medium)
          .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

        Text(`${this.blockTasks(block).length}`)
          .fontSize(UiTokens.textXS)
          .fontColor(UiTokens.textInverse)
          .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(UiTokens.radiusS)
      }
      .width('100%')
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })

      // Task cards grid
      Grid() {
        ForEach(this.blockTasks(block), (task: Task) => {
          GridItem() {
            VisualTaskCard({
              task: task,
              settings: this.settings,
              onClickCard: () => { this.onClickTask(task) }
            })
          }
          .padding(4)
        }, (task: Task) => task.id)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .padding({ left: UiTokens.pagePadding - 4, right: UiTokens.pagePadding - 4 })
      .layoutDirection(GridDirection.Row)
    }
    .width('100%')
  }

  build() {
    Scroll() {
      Column({ space: UiTokens.gapXL }) {
        if (this.tasks.length === 0) {
          Column() {
            Text('今天还没有安排任务')
              .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textTertiary)
            Text('点击右下角 + 添加第一个任务吧')
              .fontSize(UiTokens.textS)
              .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
              .margin({ top: UiTokens.gapS })
          }
          .width('100%')
          .padding({ top: 80, bottom: 80 })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          if (this.hasBlockTasks(TimeBlock.DAWN)) {
            this.BlockSection(TimeBlock.DAWN)
          }
          if (this.hasBlockTasks(TimeBlock.MORNING)) {
            this.BlockSection(TimeBlock.MORNING)
          }
          if (this.hasBlockTasks(TimeBlock.AFTERNOON)) {
            this.BlockSection(TimeBlock.AFTERNOON)
          }
          if (this.hasBlockTasks(TimeBlock.EVENING)) {
            this.BlockSection(TimeBlock.EVENING)
          }
          if (this.hasBlockTasks(TimeBlock.NIGHT)) {
            this.BlockSection(TimeBlock.NIGHT)
          }

          // Bottom padding
          Blank().height(32)
        }
      }
      .width('100%')
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
  }
}
