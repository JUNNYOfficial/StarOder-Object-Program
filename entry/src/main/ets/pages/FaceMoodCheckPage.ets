import { router } from '@kit.ArkUI'
import { cameraPicker, camera } from '@kit.CameraKit'
import { image } from '@kit.ImageKit'
import { FaceMoodAnalyzer, FaceMoodAnalysisResult } from '../services/FaceMoodAnalyzer'
import { FaceMoodRecord, UserPreferences } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { UiTokens } from '../design/UiTokens'
import { todayStr } from '../utils/DateUtils'

@Entry
@Component
struct FaceMoodCheckPage {
  @State settings: UserPreferences = new UserPreferences()
  @State capturedImage: image.PixelMap | null = null
  @State imageUri: string = ''
  @State analysisResult: FaceMoodAnalysisResult | null = null
  @State isAnalyzing: boolean = false
  @State userScore: number = 3
  @State showConfirm: boolean = false

  async aboutToAppear() {
    this.settings = await dataStore.getUserPrefs()
  }

  private baseFont(): number {
    return this.settings.largeText ? UiTokens.textL : UiTokens.textM
  }

  async takePhoto() {
    try {
      const profile: cameraPicker.PickerProfile = {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_FRONT
      }
      const result = await cameraPicker.pick(
        getContext(),
        [cameraPicker.PickerMediaType.PHOTO],
        profile
      )

      if (result.resultCode === 0 && result.resultUri) {
        this.imageUri = result.resultUri
        const imageSource = image.createImageSource(result.resultUri)
        this.capturedImage = await imageSource.createPixelMap()
        this.showConfirm = false
        this.analysisResult = null
        await this.analyzeImage()
      }
    } catch (e) {
      console.error('Camera picker failed:', JSON.stringify(e))
    }
  }

  async analyzeImage() {
    if (!this.capturedImage) return
    this.isAnalyzing = true

    try {
      this.analysisResult = await FaceMoodAnalyzer.analyze(this.capturedImage)
      this.userScore = this.analysisResult.score
      this.showConfirm = true
    } catch (e) {
      console.error('Analysis failed:', JSON.stringify(e))
    } finally {
      this.isAnalyzing = false
    }
  }

  async saveRecord() {
    const now = new Date()
    const timeStr = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
    const record = new FaceMoodRecord(todayStr(), timeStr, this.analysisResult?.score || 3, this.analysisResult?.confidence || 0)
    record.analysisReason = this.analysisResult?.reason || ''
    record.imageUri = this.imageUri
    record.userConfirmed = true
    record.userAdjustedScore = this.userScore
    await dataStore.saveFaceMoodRecord(record)
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

        Text('情绪摄像头检测')
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
          if (!this.capturedImage) {
            Column({ space: UiTokens.gapM }) {
              Text('📷')
                .fontSize(60)

              Text('点击按钮拍摄一张自拍照')
                .fontSize(this.baseFont())
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .textAlign(TextAlign.Center)

              Text('系统会根据画面整体色调给出参考性的情绪分析')
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)
                .textAlign(TextAlign.Center)
            }
            .width('100%')
            .padding(48)
            .alignItems(HorizontalAlign.Center)
          } else {
            Image(this.capturedImage)
              .width('100%')
              .height(300)
              .objectFit(ImageFit.Cover)
              .borderRadius(UiTokens.radiusXL)

            if (this.isAnalyzing) {
              Column({ space: UiTokens.gapM }) {
                LoadingProgress()
                  .width(40)
                  .height(40)
                  .color(UiTokens.brand)

                Text('正在分析画面情绪...')
                  .fontSize(this.baseFont())
                  .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
              }
              .width('100%')
              .padding(24)
              .alignItems(HorizontalAlign.Center)
            } else if (this.analysisResult) {
              Column({ space: UiTokens.gapM }) {
                Text(`参考情绪评分：${this.analysisResult.score}/5`)
                  .fontSize(this.settings.largeText ? UiTokens.text2XL : UiTokens.textXL)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)

                Text(this.analysisResult.reason)
                  .fontSize(this.baseFont())
                  .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
                  .textAlign(TextAlign.Center)

                Text(`分析置信度：${Math.round(this.analysisResult.confidence * 100)}%`)
                  .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                  .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textTertiary)

                Divider()
                  .strokeWidth(0.5)
                  .color(UiTokens.divider)
                  .margin({ top: 8, bottom: 8 })

                Text('你觉得准吗？请调整最终评分：')
                  .fontSize(this.baseFont())
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                  .width('100%')

                Row({ space: UiTokens.gapM }) {
                  ForEach([1, 2, 3, 4, 5], (n: number) => {
                    Button(String(n))
                      .width(48)
                      .height(48)
                      .fontSize(this.baseFont())
                      .fontColor(this.userScore === n ? UiTokens.textInverse : UiTokens.textPrimary)
                      .backgroundColor(this.userScore === n
                        ? (this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                        : (this.settings.highContrast ? '#EEEEEE' : UiTokens.bgHover))
                      .borderRadius(UiTokens.radiusL)
                      .onClick(() => { this.userScore = n })
                  })
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceBetween)

                Button('保存记录')
                  .width('100%')
                  .height(48)
                  .fontSize(this.baseFont())
                  .fontColor(UiTokens.textInverse)
                  .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                  .borderRadius(UiTokens.radiusXL)
                  .onClick(async () => { await this.saveRecord() })
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
            }
          }

          Button(this.capturedImage ? '重新拍摄' : '打开相机')
            .width('100%')
            .height(48)
            .fontSize(this.baseFont())
            .fontColor(UiTokens.textInverse)
            .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
            .borderRadius(UiTokens.radiusXL)
            .onClick(async () => { await this.takePhoto() })
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
