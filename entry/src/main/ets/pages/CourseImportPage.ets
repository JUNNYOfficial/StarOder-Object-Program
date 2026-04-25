import { router } from '@kit.ArkUI'
import { UserPreferences } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { CourseItem, parseCourseCSV, generateTasksFromCourses } from '../services/CourseParser'
import { UiTokens } from '../design/UiTokens'

// 文件选择器导入
import picker from '@ohos.file.picker'
// 原子化服务不支持 @kit.CoreVisionKit 的 textRecognition
// import { textRecognition } from '@kit.CoreVisionKit'
// import image from '@ohos.multimedia.image'
// import fileIo from '@ohos.file.fs'
// import { BusinessError } from '@kit.BasicServicesKit'

@Entry
@Component
struct CourseImportPage {
  @State settings: UserPreferences = new UserPreferences()
  @State pasteText: string = ''
  @State courses: CourseItem[] = []
  @State showPreview: boolean = false
  @State importMsg: string = ''
  @State baseDate: string = ''

  aboutToAppear() {
    this.settings = dataStore.getUserPrefs()
    this.baseDate = this.todayStr()
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

  selectImage() {
    try {
      const options = new picker.DocumentSelectOptions()
      options.maxSelectNumber = 1
      const documentViewPicker = new picker.DocumentViewPicker()
      documentViewPicker.select(options).then((result: string[]) => {
        if (result.length > 0) {
          this.recognizeImage(result[0])
        }
      }).catch((err: Error) => {
        this.importMsg = `选择文件失败: ${err.message}`
      })
    } catch (e) {
      this.importMsg = '文件选择器暂不可用'
    }
  }

  recognizeImage(uri: string) {
    // 原子化服务暂不支持 OCR，直接提示用户手动粘贴
    this.importMsg = '原子化服务暂不支持图片识别，请手动粘贴课表内容'
  }

  parseText() {
    if (!this.pasteText.trim()) {
      this.importMsg = '请输入课表内容'
      return
    }
    this.courses = parseCourseCSV(this.pasteText.trim())
    this.showPreview = true
    this.importMsg = `解析到 ${this.courses.length} 门课程`
  }

  importCourses() {
    const count = generateTasksFromCourses(this.courses, this.baseDate)
    this.importMsg = `成功导入 ${count} 个日程`
    setTimeout(() => {
      router.back()
    }, 800)
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

        Text('导入课表')
          .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

        Row().width(40)
      }
      .width('100%')
      .height(56)
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(UiTokens.bgCard)

      Scroll() {
        Column({ space: UiTokens.gapXL }) {
          // Image recognition
          Column({ space: UiTokens.gapS }) {
            Text('图片识别（推荐）')
              .fontSize(this.sectionTitle())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            Text('截图或拍照课表，自动识别文字内容')
              .fontSize(this.baseFont())
              .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
              .width('100%')

            Button('选择图片识别')
              .width('100%')
              .height(48)
              .fontSize(UiTokens.textL)
              .fontWeight(FontWeight.Medium)
              .fontColor(UiTokens.textInverse)
              .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
              .borderRadius(UiTokens.radiusXL)
              .onClick(() => {
                this.selectImage()
              })
          }
          .width('100%')

          // Divider
          Row() {
            Divider()
              .strokeWidth(0.5)
              .color(UiTokens.divider)
              .layoutWeight(1)

            Text('或者手动粘贴')
              .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
              .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
              .margin({ left: 12, right: 12 })

            Divider()
              .strokeWidth(0.5)
              .color(UiTokens.divider)
              .layoutWeight(1)
          }
          .width('100%')

          // Template info
          Column({ space: UiTokens.gapS }) {
            Text('CSV 格式说明')
              .fontSize(this.sectionTitle())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            Text('每行一门课，格式如下：')
              .fontSize(this.baseFont())
              .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
              .width('100%')

            Text('课程名称,教师,地点,星期(1-7),开始时间,结束时间')
              .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
              .fontWeight(FontWeight.Medium)
              .width('100%')

            Text('例如：高等数学,张老师,教学楼A301,1,08:00,09:35')
              .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
              .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
              .width('100%')
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

          // Text input
          Column({ space: UiTokens.gapS }) {
            Text('粘贴课表内容')
              .fontSize(this.sectionTitle())
              .fontWeight(FontWeight.Medium)
              .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              .width('100%')

            TextArea({ placeholder: '从教务系统复制课表后粘贴到这里...', text: $$this.pasteText })
              .width('100%')
              .height(180)
              .fontSize(this.baseFont())
              .backgroundColor(UiTokens.bgHover)
              .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
              .borderRadius(UiTokens.radiusL)

            Button('解析课表')
              .width('100%')
              .height(48)
              .fontSize(UiTokens.textL)
              .fontWeight(FontWeight.Medium)
              .fontColor(UiTokens.textInverse)
              .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
              .borderRadius(UiTokens.radiusXL)
              .onClick(() => {
                this.parseText()
              })
          }
          .width('100%')

          // Preview
          if (this.showPreview) {
            Column({ space: UiTokens.gapM }) {
              Text('解析预览')
                .fontSize(this.sectionTitle())
                .fontWeight(FontWeight.Medium)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .width('100%')

              if (this.courses.length === 0) {
                Text('未解析到课程，请检查格式')
                  .fontSize(this.baseFont())
                  .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
                  .width('100%')
                  .textAlign(TextAlign.Center)
                  .padding(24)
              } else {
                Column({ space: 0 }) {
                  ForEach(this.courses, (course: CourseItem, index: number) => {
                    Row() {
                      Column({ space: 2 }) {
                        Text(course.name)
                          .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                          .fontWeight(FontWeight.Medium)
                          .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                        Text(`${course.teacher} · ${course.location}`)
                          .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                          .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)

                      Text(`周${course.weekday}  ${course.startTime}-${course.endTime}`)
                        .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                        .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                    }
                    .width('100%')
                    .padding(14)

                    if (index < this.courses.length - 1) {
                      Divider()
                        .strokeWidth(0.5)
                        .color(UiTokens.divider)
                        .margin({ left: 14 })
                    }
                  })
                }
                .width('100%')
                .padding({ top: 6, bottom: 6 })
                .backgroundColor(UiTokens.bgCard)
                .borderRadius(UiTokens.radiusXL)
                .shadow({
                  radius: this.settings.highContrast ? 0 : 8,
                  color: '#0A000000',
                  offsetX: 0,
                  offsetY: 2
                })

                Text(`以 ${this.baseDate} 所在周为基准导入`)
                  .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                  .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
                  .width('100%')
                  .textAlign(TextAlign.Center)

                Button('确认导入本周')
                  .width('100%')
                  .height(52)
                  .fontSize(UiTokens.textL)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(UiTokens.textInverse)
                  .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                  .borderRadius(UiTokens.radiusXL)
                  .onClick(() => {
                    this.importCourses()
                  })
              }
            }
            .width('100%')
          }

          // Message
          if (this.importMsg) {
            Text(this.importMsg)
              .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
              .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 8, bottom: 32 })
          }
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
