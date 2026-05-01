import { router } from '@kit.ArkUI'
import { UiTokens } from 'commons'

@Entry
@Component
struct PrivacyPolicyPage {
  @State scrollY: number = 0

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

        Text('隐私政策')
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

          SectionTitle('引言')
          SectionBody('星序（以下简称"本应用"）深知个人信息对您的重要性，并会尽全力保护您的个人信息安全。本应用是一款为神经多样性人士设计的时间管理工具，秉承认知友好、非惩罚式的设计理念。我们致力于维持您对我们的信任，恪守以下原则保护您的个人信息：权责一致原则、目的明确原则、选择同意原则、最少够用原则、确保安全原则、主体参与原则、公开透明原则等。')

          SectionTitle('一、我们如何收集和使用您的个人信息')
          SectionBody('本应用为原子化服务（Atomic Service），所有数据默认存储在您的设备本地，不会上传至我们的服务器。')

          SectionSubTitle('1.1 您主动提供的信息')
          SectionBody('• 日程任务信息：任务标题、时间、类型、优先级、备注、子任务等\n• 课程表信息：课程名称、教室、教师、上课时间、周次、颜色标记等\n• 身心状态记录：能量评级、心情调查结果、专注时长记录等\n• 应用设置偏好：显示设置、辅助功能选项等')

          SectionSubTitle('1.2 系统权限使用')
          SectionBody('• 日历权限（READ_CALENDAR / WRITE_CALENDAR）：用于将课程同步到系统日历，仅在您主动操作时执行\n• 网络权限（INTERNET）：用于连接您自行配置的 CalDAV 服务器或飞书日历同步\n• 麦克风权限（MICROPHONE）：用于语音输入创建日程，仅在您主动使用语音功能时请求')

          SectionSubTitle('1.3 数据存储方式')
          SectionBody('所有核心数据均通过 HarmonyOS 本地 Preferences 存储在您的设备中。除非您主动配置并启用外部同步（如 CalDAV、飞书、华为日历），否则数据不会离开您的设备。')

          SectionTitle('二、数据共享与披露')
          SectionBody('我们不会将您的个人信息出售、交易或以其他方式转让给任何第三方。仅在以下情况下可能涉及数据流动：\n\n• 您主动配置的 CalDAV 同步：数据将以 ICS 标准格式上传到您指定的服务器\n• 您主动配置的飞书同步：数据将通过飞书开放平台 API 同步到您指定的飞书日历\n• 您主动配置的系统日历同步：数据将写入您设备的系统日历数据库\n\n上述同步行为完全由您主动发起和控制，本应用不会擅自传输数据。')

          SectionTitle('三、您的权利')
          SectionBody('• 访问与更正：您可以随时在应用内查看和修改所有数据\n• 删除：您可以删除任何任务、课程或记录；应用设置中提供"清空所有数据"功能\n• 导出：您可以将全部数据导出为 JSON 格式备份\n• 撤回同意：您可以通过卸载应用撤回所有授权，本地数据将随卸载一并清除')

          SectionTitle('四、数据安全')
          SectionBody('我们采用以下措施保护您的数据安全：\n\n• 所有数据通过应用级 AES-256-CBC 加密存储在设备本地，密钥由设备信息派生生成，不会离开您的设备\n• 不收集任何个人身份识别信息（如姓名、手机号、邮箱等）\n• 不向任何第三方服务器传输数据（除非您主动配置外部同步）\n• 定期数据备份提醒，防止意外丢失')

          SectionTitle('五、第三方服务')
          SectionBody('本应用可能集成以下第三方服务，其隐私政策由相应服务提供方独立制定：\n\n• 飞书开放平台（Lark）：用于日历同步，遵守《飞书隐私政策》\n• CalDAV 协议服务：用于连接您自托管或第三方的日历服务器（如 Nextcloud、iCloud 等）\n• 华为日历服务：用于将课程写入系统本地日历')

          SectionTitle('五、面部照片处理')
          SectionBody('本应用提供可选的面部情绪识别功能，该功能仅在您的设备本地运行：\n\n• 拍摄的照片仅用于本地像素分析，不会上传至任何服务器\n• 分析完成后，照片默认不保留；您可在设置中选择保留照片用于回顾\n• 保留的照片与其他数据一样进行本地加密存储\n• 您可随时在设置中关闭照片保留功能，关闭后新拍摄的照片将不再保存')

          SectionTitle('六、隐私政策更新')
          SectionBody('我们可能会不时更新本隐私政策。当政策发生重大变更时，我们会在应用内显著位置提示您，并要求您重新阅读并同意更新后的政策。')

          SectionTitle('七、联系我们')
          SectionBody('如您对本隐私政策有任何疑问、意见或建议，请通过应用内反馈渠道或以下方式联系我们：\n\n电子邮箱：junny_huang@hotmail.com')

          // Bottom padding
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
