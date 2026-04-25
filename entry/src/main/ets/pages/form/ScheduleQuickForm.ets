import { postCardAction } from '@kit.FormKit'

@Entry
@Component
struct ScheduleQuickForm {
  build() {
    Column() {
      Button() {
        Text('语音')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
      }
      .width(60)
      .height(60)
      .backgroundColor('#334A75')
      .borderRadius(30)
      .onClick(() => {
        postCardAction(this, {
          action: 'router',
          abilityName: 'EntryAbility',
          params: { url: 'pages/VoiceInputPage' }
        })
      })

      Text('语音添加')
        .fontSize(12)
        .fontColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0D2A67')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
