import { postCardAction } from '@kit.FormKit'

@Entry
@Component
struct ScheduleQuickForm {
  @LocalStorageProp('formData') formData: object = {}

  private getTodayCount(): number {
    if (this.formData && (this.formData as Record<string, object>)['todayCount']) {
      return Number((this.formData as Record<string, object>)['todayCount'])
    }
    return 0
  }

  private getNextTask(): string {
    if (this.formData && (this.formData as Record<string, string>)['nextTask']) {
      return String((this.formData as Record<string, string>)['nextTask'])
    }
    return ''
  }

  private getNextTime(): string {
    if (this.formData && (this.formData as Record<string, string>)['nextTime']) {
      return String((this.formData as Record<string, string>)['nextTime'])
    }
    return ''
  }

  build() {
    Column({ space: 8 }) {
      // Header
      Row() {
        Text('星序')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Bold)

        Text(`${this.getTodayCount()} 项待办`)
          .fontSize(11)
          .fontColor('rgba(255,255,255,0.7)')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      // Next task preview
      if (this.getNextTask()) {
        Column({ space: 2 }) {
          Text(this.getNextTask())
            .fontSize(13)
            .fontColor('#FFFFFF')
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          if (this.getNextTime()) {
            Text(this.getNextTime())
              .fontSize(11)
              .fontColor('rgba(255,255,255,0.7)')
              .width('100%')
          }
        }
        .width('100%')
        .padding({ top: 2, bottom: 2 })
      } else {
        Text('今天还没有安排')
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.6)')
          .width('100%')
          .padding({ top: 4, bottom: 4 })
      }

      // Quick actions
      Row({ space: 8 }) {
        Button() {
          Text('+ 日程')
            .fontSize(11)
            .fontColor('#334A75')
            .fontWeight(FontWeight.Medium)
        }
        .layoutWeight(1)
        .height(32)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .onClick(() => {
          postCardAction(this, {
            action: 'router',
            abilityName: 'EntryAbility',
            params: { url: '@bundle:com.atomicservice.6917603804064535609/feature_schedule/ets/pages/AddSchedule' }
          })
        })

        Button() {
          Text('专注')
            .fontSize(11)
            .fontColor('#334A75')
            .fontWeight(FontWeight.Medium)
        }
        .layoutWeight(1)
        .height(32)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .onClick(() => {
          postCardAction(this, {
            action: 'router',
            abilityName: 'EntryAbility',
            params: { url: '@bundle:com.atomicservice.6917603804064535609/feature_schedule/ets/pages/TimerPage' }
          })
        })

        Button() {
          Text('语音')
            .fontSize(11)
            .fontColor('#334A75')
            .fontWeight(FontWeight.Medium)
        }
        .layoutWeight(1)
        .height(32)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .onClick(() => {
          postCardAction(this, {
            action: 'router',
            abilityName: 'EntryAbility',
            params: { url: '@bundle:com.atomicservice.6917603804064535609/feature_schedule/ets/pages/VoiceInputPage' }
          })
        })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor('#334A75')
    .borderRadius(16)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(HorizontalAlign.Start)
  }
}
