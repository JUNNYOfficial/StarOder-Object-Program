import { router } from '@kit.ArkUI'
import { UiTokens } from 'commons'

@Entry
@Component
struct UserAgreementPage {
  build() {
    Column() {
      // Header
      Row() {
        Button() {
          Text('返回')
            .fontSize(UiTokens.textM)
            .fontColor(UiTokens.textSecondary)
        }
        .backgroundColor('transparent')
        .onClick(() => router.back())

        Text('用户协议')
          .fontSize(UiTokens.textXL)
          .fontWeight(FontWeight.Bold)
          .fontColor(UiTokens.textPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Blank().width(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column({ space: UiTokens.gapM }) {
          SectionTitle('更新日期')
          SectionBody('2025年4月29日')

          SectionTitle('一、协议范围')
          SectionBody('本协议是您（以下简称"用户"或"您"）与星序（以下简称"本应用"或"我们"）之间关于使用本应用及相关服务所订立的协议。请您仔细阅读本协议，一旦您开始使用本应用，即视为您已充分理解并同意接受本协议所有条款的约束。')

          SectionTitle('二、服务说明')
          SectionBody('星序是一款为神经多样性人士（包括但不限于 ADHD、自闭症谱系、阅读障碍、焦虑症等）设计的时间管理与日程规划工具。核心功能包括：\n\n• 日程任务创建、管理与进度追踪\n• 周课程表管理与可视化展示\n• 专注计时器与使用统计\n• 能量与心情状态记录\n• 语音/自然语言输入\n• 数据备份与恢复\n• 外部日历同步（CalDAV、飞书、华为日历，需用户主动配置）\n\n本应用为 HarmonyOS 原子化服务，所有核心数据默认仅存储于用户设备本地。')

          SectionTitle('三、账号与数据')
          SectionSubTitle('3.1 无需注册')
          SectionBody('本应用无需注册账号即可使用全部功能。我们不会收集您的手机号、邮箱、身份证号等个人身份识别信息。')

          SectionSubTitle('3.2 数据所有权')
          SectionBody('您在本应用内创建的所有数据（任务、课程、记录等）归您所有。您有权随时导出、修改或删除这些数据。')

          SectionSubTitle('3.3 数据安全')
          SectionBody('我们采用本地加密存储技术保护您的数据。但请您理解，任何存储方式都无法做到绝对安全。建议您定期使用应用内的"导出数据"功能进行备份。')

          SectionTitle('四、使用规范')
          SectionBody('您在使用本应用时，应当遵守法律法规，不得利用本应用从事以下行为：\n\n• 发布、传播违法违规内容\n• 干扰、破坏本应用的正常运行\n• 逆向工程、反编译或以其他方式试图获取本应用的源代码\n• 将本应用用于任何商业目的（除非获得书面授权）\n• 侵犯他人知识产权或其他合法权益')

          SectionTitle('五、免责声明')
          SectionSubTitle('5.1 服务可用性')
          SectionBody('本应用按"现状"提供，我们不承诺服务不会中断。由于不可抗力、系统维护、网络故障等原因导致的服务中断，我们不承担相应责任。')

          SectionSubTitle('5.2 健康相关')
          SectionBody('本应用为通用时间管理工具，不构成医疗建议、诊断或治疗。如有身心健康方面的疑虑，请咨询专业医生或治疗师。应用内的身心状态记录功能仅供个人参考，不可替代专业评估。')

          SectionSubTitle('5.3 外部同步风险')
          SectionBody('您自行配置的 CalDAV、飞书等外部同步服务由相应第三方提供。我们对这些服务的可用性、数据安全性不承担保证责任。建议您在使用外部同步前充分了解相关服务的条款。')

          SectionSubTitle('5.4 数据丢失')
          SectionBody('虽然我们努力保障数据安全，但因设备损坏、系统故障、误操作等原因可能导致数据丢失。我们强烈建议您定期进行数据导出备份。对于未备份的数据丢失，我们不承担赔偿责任。')

          SectionTitle('六、知识产权')
          SectionBody('本应用的界面设计、代码、图标、文案等知识产权归我们所有。未经授权，您不得复制、修改、传播或用于其他商业目的。本应用使用的开源组件遵循其 respective 开源许可证。')

          SectionTitle('七、协议更新')
          SectionBody('我们保留随时修改本协议的权利。修改后的协议将在应用内公布，重大变更会显著提示。如果您不同意修改后的协议，请停止使用本应用。继续使用视为接受修改后的协议。')

          SectionTitle('八、协议终止')
          SectionBody('您可以通过卸载本应用随时终止本协议。协议终止后，您保存在设备本地的数据将随应用卸载而清除（除非您已导出备份）。')

          SectionTitle('九、适用法律与争议解决')
          SectionBody('本协议适用中华人民共和国法律。因本协议引起的或与本协议有关的任何争议，双方应友好协商解决；协商不成的，任何一方均可向有管辖权的人民法院提起诉讼。')

          SectionTitle('十、联系我们')
          SectionBody('如您对本协议有任何疑问，请联系：\n\n电子邮箱：junny_huang@hotmail.com')

          Blank().height(32)
        }
        .width('100%')
        .padding(UiTokens.pagePadding)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(UiTokens.bgPage)
  }
}

@Builder
function SectionTitle(text: string) {
  Text(text)
    .fontSize(UiTokens.textL)
    .fontWeight(FontWeight.Bold)
    .fontColor(UiTokens.textPrimary)
    .width('100%')
    .margin({ top: 8 })
}

@Builder
function SectionSubTitle(text: string) {
  Text(text)
    .fontSize(UiTokens.textM)
    .fontWeight(FontWeight.Medium)
    .fontColor(UiTokens.textPrimary)
    .width('100%')
    .margin({ top: 4 })
}

@Builder
function SectionBody(text: string) {
  Text(text)
    .fontSize(UiTokens.textS)
    .fontColor(UiTokens.textSecondary)
    .width('100%')
    .lineHeight(22)
}
