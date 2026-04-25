import { router, promptAction } from '@kit.ArkUI'
import { dataStore } from '../models/DataStore'
import { TimeSlot, CourseScheduleState } from '../models/CourseModels'
import { UiTokens } from '../design/UiTokens'

@Entry
@Component
struct TimeSlotSettingsPage {
  @State slots: TimeSlot[] = []

  aboutToAppear() {
    const state = dataStore.getCourseState()
    this.slots = state.timeSlots.map(s => new TimeSlot(s.slotNumber, s.startTime, s.endTime))
  }

  private saveSlots() {
    const state = dataStore.getCourseState()
    state.timeSlots = this.slots.map(s => new TimeSlot(s.slotNumber, s.startTime, s.endTime))
    dataStore.saveCourseState(state)
    promptAction.showToast({ message: '时间段已保存' })
    router.back()
  }

  private addSlot() {
    const nextNum = this.slots.length + 1
    this.slots.push(new TimeSlot(nextNum, '08:00', '08:45'))
  }

  private removeSlot(index: number) {
    this.slots.splice(index, 1)
    // 重新编号
    for (let i = 0; i < this.slots.length; i++) {
      this.slots[i].slotNumber = i + 1
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Button() {
          Text('<')
            .fontSize(UiTokens.textL)
            .fontColor(UiTokens.textPrimary)
        }
        .width(36)
        .height(36)
        .backgroundColor(UiTokens.bgHover)
        .borderRadius(UiTokens.radiusM)
        .onClick(() => router.back())

        Text('课表时间段')
          .fontSize(UiTokens.textXL)
          .fontWeight(FontWeight.Bold)
          .fontColor(UiTokens.textPrimary)
          .layoutWeight(1)

        Button('保存')
          .fontSize(UiTokens.textM)
          .fontColor(UiTokens.brand)
          .backgroundColor('transparent')
          .onClick(() => this.saveSlots())
      }
      .width('100%')
      .height(48)
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })

      Text('点击时间可修改，左右滑动可删除')
        .fontSize(UiTokens.textS)
        .fontColor(UiTokens.textSecondary)
        .width('100%')
        .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding, top: 4, bottom: 12 })

      List() {
        ForEach(this.slots, (slot: TimeSlot, index: number) => {
          ListItem() {
            Row({ space: UiTokens.gapM }) {
              Text(`第 ${slot.slotNumber} 节`)
                .fontSize(UiTokens.textM)
                .fontColor(UiTokens.textPrimary)
                .width(60)

              TextInput({ text: $$slot.startTime })
                .layoutWeight(1)
                .height(40)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusL)

              Text('至')
                .fontSize(UiTokens.textS)
                .fontColor(UiTokens.textSecondary)

              TextInput({ text: $$slot.endTime })
                .layoutWeight(1)
                .height(40)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusL)
            }
            .width('100%')
            .padding(12)
            .backgroundColor(UiTokens.bgCard)
            .borderRadius(UiTokens.radiusL)
          }
          .swipeAction({ end: this.DeleteBuilder(index) })
          .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding, bottom: 8 })
        })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)

      Button('+ 添加一节')
        .width('90%')
        .height(48)
        .fontSize(UiTokens.textM)
        .fontColor(UiTokens.brand)
        .backgroundColor(UiTokens.brandSoft)
        .borderRadius(UiTokens.radiusXL)
        .margin({ bottom: 20 })
        .onClick(() => this.addSlot())
    }
    .width('100%')
    .height('100%')
    .backgroundColor(UiTokens.bgPage)
  }

  @Builder
  DeleteBuilder(index: number) {
    Button() {
      Text('删除')
        .fontColor('#FFFFFF')
        .fontSize(UiTokens.textM)
    }
    .width(60)
    .height('100%')
    .backgroundColor(UiTokens.error)
    .borderRadius(UiTokens.radiusL)
    .onClick(() => this.removeSlot(index))
  }
}
