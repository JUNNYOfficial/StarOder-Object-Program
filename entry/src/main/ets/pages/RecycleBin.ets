import { router } from '@kit.ArkUI'
import { Task, UserPreferences } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { UiTokens } from '../design/UiTokens'

@Entry
@Component
struct RecycleBin {
  @State settings: UserPreferences = new UserPreferences()
  @State deletedTasks: Task[] = []
  @State emptyMsg: string = ''

  async aboutToAppear() {
    this.settings = await dataStore.getUserPrefs()
    await this.loadData()
  }

  async onPageShow() {
    await this.loadData()
  }

  async loadData() {
    this.deletedTasks = await dataStore.getDeletedTasks()
    this.emptyMsg = this.deletedTasks.length === 0 ? '回收站是空的' : ''
  }

  async restoreTask(taskId: string) {
    await dataStore.restoreTask(taskId)
    await this.loadData()
  }

  async permanentlyDelete(taskId: string) {
    await dataStore.permanentlyDeleteTask(taskId)
    await this.loadData()
  }

  async clearAll() {
    const all = await dataStore.getDeletedTasks()
    for (let i = 0; i < all.length; i++) {
      await dataStore.permanentlyDeleteTask(all[i].id)
    }
    await this.loadData()
  }

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
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

        Text('回收站')
          .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

        if (this.deletedTasks.length > 0) {
          Button() {
            Text('清空')
              .fontSize(this.baseFont())
              .fontColor(UiTokens.paused)
          }
          .backgroundColor('transparent')
          .onClick(async () => {
            await this.clearAll()
          })
        } else {
          Row().width(40)
        }
      }
      .width('100%')
      .height(56)
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(UiTokens.bgCard)

      if (this.deletedTasks.length === 0) {
        Column() {
          Text(this.emptyMsg)
            .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
            .margin({ bottom: 6 })
          Text('删除的日程会在这里保留 3 天')
            .fontSize(this.baseFont())
            .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
            .textAlign(TextAlign.Center)
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .padding(32)
      } else {
        List({ space: 0 }) {
          ForEach(this.deletedTasks, (task: Task) => {
            ListItem() {
              Column({ space: UiTokens.gapS }) {
                Row() {
                  Column({ space: 4 }) {
                    Text(task.title)
                      .fontSize(this.baseFont())
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })

                    Text(`${task.date}  ${task.startTime} - ${task.endTime}`)
                      .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                      .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Row({ space: 8 }) {
                    Button('恢复')
                      .height(36)
                      .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                      .fontColor(UiTokens.brand)
                      .backgroundColor(UiTokens.brandSoft)
                      .borderRadius(UiTokens.radiusM)
                      .padding({ left: 12, right: 12 })
                      .onClick(async () => {
                        await this.restoreTask(task.id)
                      })

                    Button('删除')
                      .height(36)
                      .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                      .fontColor(UiTokens.paused)
                      .backgroundColor(UiTokens.bgHover)
                      .borderRadius(UiTokens.radiusM)
                      .padding({ left: 12, right: 12 })
                      .onClick(async () => {
                        await this.permanentlyDelete(task.id)
                      })
                  }
                }
                .width('100%')
                .padding(UiTokens.cardPadding)
                .backgroundColor(UiTokens.bgCard)
                .borderRadius(UiTokens.radiusXL)
              }
              .width('100%')
              .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding, top: 6, bottom: 6 })
            }
          }, (task: Task) => task.id)
        }
        .width('100%')
        .layoutWeight(1)
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Auto)
        .padding({ top: 8, bottom: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPage)
  }
}
