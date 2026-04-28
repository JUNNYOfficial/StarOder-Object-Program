import { router, promptAction } from '@kit.ArkUI'
import { Task, TaskStatus, UserPreferences, YesterdaySummary } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { ScheduleCard } from '../components/ScheduleCard'
import { CalendarTab } from '../components/CalendarTab'
import { TimerTab } from '../components/TimerTab'
import { SettingsTab } from '../components/SettingsTab'
import { UiTokens } from '../design/UiTokens'
import { addDays, todayStr, formatDate, formatTime } from '../utils/DateUtils'
import { getCourseTimeText } from '../utils/UiHelper'
import { DayTimeline } from '../components/DayTimeline'
import { VisualScheduleView } from '../components/VisualScheduleView'
import { CourseScheduleState, Course, WeekType } from '../models/CourseModels'
import { EnergySummary, getTodayEnergySummary } from '../utils/EnergyBank'

@Entry
@Component
struct Index {
  @State tasks: Task[] = []
  @State filteredTasks: Task[] = []
  @State settings: UserPreferences = new UserPreferences()
  @State currentDate: string = ''
  @State greeting: string = ''
  @State searchQuery: string = ''
  @State activeTab: number = 0

  @State courseState: CourseScheduleState = new CourseScheduleState()
  @State todayCourses: Course[] = []
  @State showTermsDialog: boolean = false
  @State showYesterdaySummary: boolean = false
  @State yesterdaySummary: YesterdaySummary = new YesterdaySummary('', 0, 0, 0)
  @State showMoodPrompt: boolean = false
  @State currentTimeStr: string = ''
  @State viewMode: number = 1 // 0=list, 1=timeline, 2=visual
  @State showBadDayDialog: boolean = false
  @State energySummary: EnergySummary = new EnergySummary(8, 0, 0, 0)
  private clockTimer: number = -1

  async aboutToAppear(): Promise<void> {
    const now = new Date()
    this.currentDate = formatDate(now)
    this.greeting = this.getGreeting(now)
    await this.loadData()
    if (!(await dataStore.isTermsVersionAccepted())) {
      this.showTermsDialog = true
    }
    await this.checkYesterdaySummary()
    await this.checkMoodPrompt()
    this.startClock()
  }

  private async checkMoodPrompt(): Promise<void> {
    const today = todayStr()
    // 今天已经提示过，不再提示
    if ((await dataStore.getLastMoodPromptDate()) === today) {
      return
    }
    // 今天已经有情绪记录，不再提示
    if (await dataStore.hasMoodRecordToday()) {
      return
    }
    // 30% 概率触发抽查
    if (Math.random() < 0.3) {
      this.showMoodPrompt = true
      await dataStore.setLastMoodPromptDate(today)
    }
  }

  private async checkYesterdaySummary(): Promise<void> {
    if (await dataStore.shouldShowYesterdaySummary()) {
      this.yesterdaySummary = await dataStore.getStoredYesterdaySummary()
      this.showYesterdaySummary = true
      await dataStore.setShouldShowYesterdaySummary(false)
    }
  }

  async onPageShow(): Promise<void> {
    await this.loadData()
  }

  async loadData(): Promise<void> {
    this.settings = await dataStore.getUserPrefs()
    this.tasks = await dataStore.getTasksByDate(this.currentDate)
    this.applyFilter()
    this.courseState = await dataStore.getCourseState()
    this.todayCourses = this.getTodayCourses()
    const energyRecords = await dataStore.getEnergyRecords()
    this.energySummary = getTodayEnergySummary(this.tasks, energyRecords)
  }

  private getCurrentWeek(state: CourseScheduleState): number {
    if (state.semesterStartDate) {
      const start = new Date(state.semesterStartDate)
      const now = new Date()
      const diffDays = Math.floor((now.getTime() - start.getTime()) / (24 * 60 * 60 * 1000))
      const week = Math.floor(diffDays / 7) + 1
      if (week < 1) return 1
      if (week > state.totalWeeks) return state.totalWeeks
      return week
    }
    return state.currentWeek
  }

  private getTodayCourses(): Course[] {
    const state = this.courseState
    if (state.courses.length === 0) return []
    const currentWeek = this.getCurrentWeek(state)
    const now = new Date()
    const dayOfWeek = now.getDay() === 0 ? 7 : now.getDay()
    const result: Course[] = []
    for (let i = 0; i < state.courses.length; i++) {
      const c = state.courses[i]
      if (c.dayOfWeek !== dayOfWeek) continue
      if (currentWeek < c.startWeek || currentWeek > c.endWeek) continue
      if (c.weekType === WeekType.ODD && currentWeek % 2 === 0) continue
      if (c.weekType === WeekType.EVEN && currentWeek % 2 === 1) continue
      result.push(c)
    }
    result.sort((a, b) => a.startSlot - b.startSlot)
    return result
  }

  async prevDay(): Promise<void> {
    this.currentDate = addDays(this.currentDate, -1)
    await this.loadData()
  }

  async nextDay(): Promise<void> {
    this.currentDate = addDays(this.currentDate, 1)
    await this.loadData()
  }

  async goToday(): Promise<void> {
    this.currentDate = formatDate(new Date())
    await this.loadData()
  }

  applyFilter() {
    if (this.searchQuery.length === 0) {
      this.filteredTasks = this.tasks
    } else {
      const q = this.searchQuery.toLowerCase()
      const result: Task[] = []
      for (let i = 0; i < this.tasks.length; i++) {
        if (this.tasks[i].title.toLowerCase().includes(q)) {
          result.push(this.tasks[i])
        }
      }
      this.filteredTasks = result
    }
  }

  private startClock(): void {
    this.updateClock()
    this.clockTimer = setInterval(() => this.updateClock(), 1000)
  }

  private updateClock(): void {
    this.currentTimeStr = formatTime(new Date())
  }

  aboutToDisappear(): void {
    if (this.clockTimer !== -1) {
      clearInterval(this.clockTimer)
      this.clockTimer = -1
    }
  }

  getGreeting(d: Date): string {
    const h = d.getHours()
    if (h < 6) return '夜深了，注意休息'
    if (h < 9) return '早上好，今天从简单的事开始吧'
    if (h < 12) return '上午好，按自己的节奏来'
    if (h < 14) return '中午好，记得休息一下'
    if (h < 18) return '下午好，已经完成一部分了'
    return '晚上好，准备结束今天吧'
  }

  private getUndoneTaskCount(): number {
    let count = 0
    for (let i = 0; i < this.filteredTasks.length; i++) {
      if (this.filteredTasks[i].status !== TaskStatus.DONE) {
        count++
      }
    }
    return count
  }

  async advanceStatus(task: Task): Promise<void> {
    if (await dataStore.advanceTaskStatus(task.id)) {
      await this.loadData()
    }
  }

  private async postponeToday(): Promise<void> {
    const moved = await dataStore.postponeTodayTasks()
    promptAction.showToast({ message: `已把 ${moved} 个任务移到明天，今天好好休息` })
    await this.loadData()
  }

  build() {
    Stack() {
      Column() {
      // Header
      Column({ space: 4 }) {
        Text(this.greeting)
          .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
          .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)

        Row() {
          Text('星序')
            .fontSize(this.settings.largeText ? 24 : 20)
            .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
            .fontWeight(FontWeight.Bold)
            .margin({ right: 8 })

          if (this.activeTab === 0) {
            Row({ space: 8 }) {
              Button() {
                Text('<')
                  .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              }
              .width(32)
              .height(32)
              .backgroundColor(UiTokens.bgHover)
              .borderRadius(UiTokens.radiusM)
              .onClick(async () => { await this.prevDay() })

              Text(this.currentDate)
                .fontSize(this.settings.largeText ? UiTokens.text2XL : UiTokens.textXL)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)

              Button() {
                Text('>')
                  .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
              }
              .width(32)
              .height(32)
              .backgroundColor(UiTokens.bgHover)
              .borderRadius(UiTokens.radiusM)
              .onClick(async () => { await this.nextDay() })

              if (this.currentDate !== todayStr()) {
                Button() {
                  Text('回今天')
                    .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                    .fontColor(UiTokens.brand)
                    .fontWeight(FontWeight.Medium)
                }
                .backgroundColor(UiTokens.brandSoft)
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .borderRadius(UiTokens.radiusM)
                .onClick(async () => { await this.goToday() })
              }

              // 实时时钟（仅今天显示）
              if (this.currentDate === todayStr() && this.currentTimeStr.length > 0) {
                Text(this.currentTimeStr)
                  .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textSecondary)
                  .fontFamily('monospace')
              }
            }
          }
        }
        .width('100%')
        .height(40)
        .alignItems(VerticalAlign.Center)

      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding, top: 20, bottom: 4 })

      // Content
      if (this.activeTab === 0) {
        if (this.filteredTasks.length === 0) {
          Column() {
            Row() {
              TextInput({ placeholder: '搜索日程', text: $$this.searchQuery })
                .width('100%')
                .height(40)
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .backgroundColor(UiTokens.bgHover)
                .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                .borderRadius(UiTokens.radiusL)
                .padding({ left: 14, right: 14 })
                .onChange(() => {
                  this.applyFilter()
                })
            }
            .width('100%')
            .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding, top: 8, bottom: 4 })

            // 坏日子保护按钮（仅今天显示）
            if (this.currentDate === todayStr()) {
              Row() {
                Button() {
                  Text('🤍 今天状态不好')
                    .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                    .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textSecondary)
                }
                .height(36)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusM)
                .padding({ left: 12, right: 12 })
                .onClick(() => {
                  this.showBadDayDialog = true
                })
              }
              .width('100%')
              .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding, top: 2, bottom: 6 })
            }

            if (this.todayCourses.length > 0) {
              Column({ space: UiTokens.gapS }) {
                Text('今日课程')
                  .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                  .width('100%')
                  .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })

                ForEach(this.todayCourses, (course: Course) => {
                  Row({ space: UiTokens.gapM }) {
                    Column() {
                      Text(getCourseTimeText(course, this.courseState.timeSlots))
                        .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                    }
                    .width(72)
                    .alignItems(HorizontalAlign.Start)

                    Column({ space: 2 }) {
                      Text(course.name)
                        .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')

                      if (course.classroom || course.teacher) {
                        Text(`${course.classroom || ''}${course.teacher ? ' | ' + course.teacher : ''}`)
                          .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                          .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .width('100%')
                      }
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor(course.color + '18')
                  .borderRadius(UiTokens.radiusL)
                  .border({ width: 1, color: course.color + '40' })
                  .onClick(() => {
                    router.pushUrl({ url: 'pages/CourseSchedulePage' })
                  })
                }, (course: Course) => course.id)
              }
              .width('100%')
              .padding({ top: 4, bottom: 4 })
            }

            Column() {
              Text(this.currentDate === todayStr() ? '今天还没有安排' : '这天还没有安排')
                .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                .margin({ bottom: 6 })
              Text('点击下方按钮添加第一个日程')
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
            }
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .padding(32)
          }
          .layoutWeight(1)
        } else {
          Column({ space: 0 }) {
            // 搜索框 + 视图切换按钮
            Row({ space: 8 }) {
              TextInput({ placeholder: '搜索日程', text: $$this.searchQuery })
                .layoutWeight(1)
                .height(40)
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .backgroundColor(UiTokens.bgHover)
                .placeholderColor(this.settings.highContrast ? '#999999' : UiTokens.textTertiary)
                .borderRadius(UiTokens.radiusL)
                .padding({ left: 14, right: 14 })
                .onChange(() => {
                  this.applyFilter()
                })

              if (this.currentDate === todayStr()) {
                Button() {
                  Text(this.viewMode === 0 ? '轴' : this.viewMode === 1 ? '卡片' : '列表')
                    .fontSize(UiTokens.textXS)
                    .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
                }
                .width(40)
                .height(40)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusM)
                .onClick(() => {
                  this.viewMode = (this.viewMode + 1) % 3
                })
              }
            }
            .width('100%')
            .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding, top: 8, bottom: 4 })

            if (this.todayCourses.length > 0) {
              Column({ space: UiTokens.gapS }) {
                Text('今日课程')
                  .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                  .width('100%')

                ForEach(this.todayCourses, (course: Course) => {
                  Row({ space: UiTokens.gapM }) {
                    Column() {
                      Text(getCourseTimeText(course, this.courseState.timeSlots))
                        .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                    }
                    .width(72)
                    .alignItems(HorizontalAlign.Start)

                    Column({ space: 2 }) {
                      Text(course.name)
                        .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.textPrimary)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')

                      if (course.classroom || course.teacher) {
                        Text(`${course.classroom || ''}${course.teacher ? ' | ' + course.teacher : ''}`)
                          .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                          .fontColor(this.settings.highContrast ? '#555555' : UiTokens.textSecondary)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .width('100%')
                      }
                    }
                    .layoutWeight(1)
                    .alignItems(HorizontalAlign.Start)
                  }
                  .width('100%')
                  .padding(12)
                  .backgroundColor(course.color + '18')
                  .borderRadius(UiTokens.radiusL)
                  .border({ width: 1, color: course.color + '40' })
                  .onClick(() => {
                    router.pushUrl({ url: 'pages/CourseSchedulePage' })
                  })
                }, (course: Course) => course.id)
              }
              .width('100%')
              .padding({ top: 4, bottom: 4 })
            }

            // 任务区域：三种视图切换
            if (this.viewMode === 1 && this.currentDate === todayStr()) {
              DayTimeline({
                tasks: this.filteredTasks,
                settings: this.settings,
                currentDate: this.currentDate,
                courses: this.todayCourses,
                courseTimeSlots: this.courseState.timeSlots,
                energySummary: this.energySummary,
                onClickTask: (task: Task) => {
                  router.pushUrl({ url: 'pages/ScheduleDetail', params: { id: task.id } })
                },
                onClickCourse: () => {
                  router.pushUrl({ url: 'pages/CourseSchedulePage' })
                }
              })
            } else if (this.viewMode === 2 && this.currentDate === todayStr()) {
              VisualScheduleView({
                tasks: this.filteredTasks,
                settings: this.settings,
                onClickTask: (task: Task) => {
                  router.pushUrl({ url: 'pages/ScheduleDetail', params: { id: task.id } })
                }
              })
            } else {
              List({ space: 0 }) {
                ForEach(this.filteredTasks, (task: Task) => {
                  ListItem() {
                    ScheduleCard({
                      task: task,
                      settings: this.settings,
                      onClickCard: () => {
                        router.pushUrl({ url: 'pages/ScheduleDetail', params: { id: task.id } })
                      },
                      onToggleStatus: async () => {
                        await this.advanceStatus(task)
                      }
                    })
                  }
                  .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })
                  .swipeAction({
                    end: this.SwipeActionBuilder(task)
                  })
                }, (task: Task) => task.id)
              }
              .width('100%')
              .layoutWeight(1)
              .edgeEffect(EdgeEffect.Spring)
              .scrollBar(BarState.Auto)
              .padding({ top: 0, bottom: 8 })
            }
          }
          .width('100%')
          .layoutWeight(1)
        }
      } else if (this.activeTab === 1) {
        CalendarTab()
          .layoutWeight(1)
      } else if (this.activeTab === 2) {
        TimerTab()
          .layoutWeight(1)
      } else if (this.activeTab === 3) {
        SettingsTab()
          .layoutWeight(1)
      }

      // Bottom Navigation
      Row() {
        this.NavItem('今日', 0)
        this.NavItem('日历', 1)

        // 添加（中间突出）
        Column() {
          Button() {
            Text('+')
              .fontSize(24)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Medium)
          }
          .width(52)
          .height(52)
          .backgroundColor(this.settings.highContrast ? UiTokens.hcText : UiTokens.brand)
          .borderRadius(UiTokens.radiusL)
        }
        .layoutWeight(1)
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          router.pushUrl({ url: 'pages/AddSchedule' })
        })

        this.NavItem('专注', 2)
        this.NavItem('设置', 3)
      }
      .width('100%')
      .height(72)
      .padding({ left: 16, right: 16 })
      .backgroundColor(UiTokens.bgCard)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.settings.highContrast ? UiTokens.hcBg : UiTokens.bgPage)

    if (this.showTermsDialog) {
      Column() {
        Column()
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('rgba(0,0,0,0.4)')

        Column({ space: UiTokens.gapM }) {
          Text('欢迎使用星序')
            .fontSize(UiTokens.textXL)
            .fontWeight(FontWeight.Bold)
            .fontColor(UiTokens.textPrimary)
            .width('100%')
            .textAlign(TextAlign.Center)

          Text('在使用本应用前，请您阅读并同意以下协议：')
            .fontSize(UiTokens.textS)
            .fontColor(UiTokens.textSecondary)
            .width('100%')
            .textAlign(TextAlign.Center)

          Row({ space: UiTokens.gapS }) {
            Text('《用户协议》')
              .fontSize(UiTokens.textS)
              .fontColor(UiTokens.brand)
              .onClick(() => {
                router.pushUrl({ url: 'pages/UserAgreementPage' })
              })
            Text('《隐私政策》')
              .fontSize(UiTokens.textS)
              .fontColor(UiTokens.brand)
              .onClick(() => {
                router.pushUrl({ url: 'pages/PrivacyPolicyPage' })
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)

          Row({ space: UiTokens.gapS }) {
            Button('不同意')
              .layoutWeight(1)
              .height(44)
              .fontColor(UiTokens.textSecondary)
              .backgroundColor(UiTokens.bgHover)
              .borderRadius(UiTokens.radiusL)
              .onClick(() => {
                promptAction.showToast({ message: '您需要同意协议才能继续使用' })
              })

            Button('同意并继续')
              .layoutWeight(1)
              .height(44)
              .fontColor('#FFFFFF')
              .backgroundColor(UiTokens.brand)
              .borderRadius(UiTokens.radiusL)
              .onClick(async () => {
                await dataStore.setAgreedToTerms()
                this.showTermsDialog = false
              })
          }
          .width('100%')
        }
        .width('100%')
        .padding(UiTokens.pagePadding)
        .backgroundColor(UiTokens.bgCard)
        .borderRadius({ topLeft: 24, topRight: 24 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
    }

    if (this.showMoodPrompt) {
      Column() {
        Column()
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('rgba(0,0,0,0.4)')
          .onClick(() => {
            this.showMoodPrompt = false
          })

        Column({ space: UiTokens.gapM }) {
          Text('🎯 随机情绪抽查')
            .fontSize(UiTokens.textXL)
            .fontWeight(FontWeight.Bold)
            .fontColor(UiTokens.textPrimary)
            .width('100%')
            .textAlign(TextAlign.Center)

          Text('关注一下此刻的心情吧，只需要几秒钟。')
            .fontSize(UiTokens.textS)
            .fontColor(UiTokens.textSecondary)
            .width('100%')
            .textAlign(TextAlign.Center)

          Row({ space: UiTokens.gapS }) {
            Button('📷 摄像头检测')
              .layoutWeight(1)
              .height(44)
              .fontColor('#FFFFFF')
              .backgroundColor(UiTokens.brand)
              .borderRadius(UiTokens.radiusL)
              .onClick(() => {
                this.showMoodPrompt = false
                router.pushUrl({ url: 'pages/FaceMoodCheckPage' })
              })

            Button('✏️ 手动自查')
              .layoutWeight(1)
              .height(44)
              .fontColor('#FFFFFF')
              .backgroundColor(UiTokens.done)
              .borderRadius(UiTokens.radiusL)
              .onClick(() => {
                this.showMoodPrompt = false
                router.pushUrl({ url: 'pages/MoodSelfCheckPage' })
              })
          }
          .width('100%')

          Button('稍后再说')
            .width('100%')
            .height(44)
            .fontColor(UiTokens.textSecondary)
            .backgroundColor(UiTokens.bgHover)
            .borderRadius(UiTokens.radiusL)
            .onClick(() => {
              this.showMoodPrompt = false
            })
        }
        .width('100%')
        .padding(UiTokens.pagePadding)
        .backgroundColor(UiTokens.bgCard)
        .borderRadius({ topLeft: 24, topRight: 24 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
    }

    if (this.showBadDayDialog) {
      Column() {
        Column()
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('rgba(0,0,0,0.4)')
          .onClick(() => {
            this.showBadDayDialog = false
          })

        Column({ space: UiTokens.gapM }) {
          Text('🤍 今天状态不好')
            .fontSize(UiTokens.textXL)
            .fontWeight(FontWeight.Bold)
            .fontColor(UiTokens.textPrimary)
            .width('100%')
            .textAlign(TextAlign.Center)

          Text('没有关系，每个人都会有这样的日子。')
            .fontSize(UiTokens.textS)
            .fontColor(UiTokens.textSecondary)
            .width('100%')
            .textAlign(TextAlign.Center)

          Text('我会帮你把今天未完成的任务全部移到明天，不会有任何惩罚标记。')
            .fontSize(UiTokens.textS)
            .fontColor(UiTokens.textSecondary)
            .width('100%')
            .textAlign(TextAlign.Center)

          Text(`今天未完成任务：${this.getUndoneTaskCount()} 个`)
            .fontSize(this.settings.largeText ? UiTokens.textL : UiTokens.textM)
            .fontColor(UiTokens.brand)
            .width('100%')
            .textAlign(TextAlign.Center)

          Row({ space: UiTokens.gapS }) {
            Button('取消')
              .layoutWeight(1)
              .height(44)
              .fontColor(UiTokens.textSecondary)
              .backgroundColor(UiTokens.bgHover)
              .borderRadius(UiTokens.radiusL)
              .onClick(() => {
                this.showBadDayDialog = false
              })

            Button('确认移动')
              .layoutWeight(1)
              .height(44)
              .fontColor('#FFFFFF')
              .backgroundColor(UiTokens.brand)
              .borderRadius(UiTokens.radiusL)
              .onClick(async () => {
                this.showBadDayDialog = false
                await this.postponeToday()
              })
          }
          .width('100%')
        }
        .width('100%')
        .padding(UiTokens.pagePadding)
        .backgroundColor(UiTokens.bgCard)
        .borderRadius({ topLeft: 24, topRight: 24 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
    }

    if (this.showYesterdaySummary) {
      Column() {
        Column()
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('rgba(0,0,0,0.4)')
          .onClick(() => {
            this.showYesterdaySummary = false
          })

        Column({ space: UiTokens.gapM }) {
          Text(`昨天 (${this.yesterdaySummary.date}) 的完成情况`)
            .fontSize(UiTokens.textL)
            .fontWeight(FontWeight.Bold)
            .fontColor(UiTokens.textPrimary)
            .width('100%')
            .textAlign(TextAlign.Center)

          Row({ space: UiTokens.gapM }) {
            Column({ space: 4 }) {
              Text(`${this.yesterdaySummary.completedTasks}/${this.yesterdaySummary.totalTasks}`)
                .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
                .fontWeight(FontWeight.Bold)
                .fontColor(UiTokens.brand)
              Text('完成任务')
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .fontColor(UiTokens.textSecondary)
            }
            .layoutWeight(1)
            .padding(16)
            .backgroundColor(UiTokens.bgHover)
            .borderRadius(UiTokens.radiusXL)
            .alignItems(HorizontalAlign.Center)

            Column({ space: 4 }) {
              Text(`${this.yesterdaySummary.completionRate}%`)
                .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
                .fontWeight(FontWeight.Bold)
                .fontColor(UiTokens.brand)
              Text('完成率')
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .fontColor(UiTokens.textSecondary)
            }
            .layoutWeight(1)
            .padding(16)
            .backgroundColor(UiTokens.bgHover)
            .borderRadius(UiTokens.radiusXL)
            .alignItems(HorizontalAlign.Center)

            Column({ space: 4 }) {
              Text(`${this.yesterdaySummary.focusMinutes}`)
                .fontSize(this.settings.largeText ? UiTokens.textXL : UiTokens.textL)
                .fontWeight(FontWeight.Bold)
                .fontColor(UiTokens.brand)
              Text('专注分钟')
                .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
                .fontColor(UiTokens.textSecondary)
            }
            .layoutWeight(1)
            .padding(16)
            .backgroundColor(UiTokens.bgHover)
            .borderRadius(UiTokens.radiusXL)
            .alignItems(HorizontalAlign.Center)
          }
          .width('100%')

          Button('知道了')
            .width('100%')
            .height(48)
            .fontColor('#FFFFFF')
            .backgroundColor(UiTokens.brand)
            .borderRadius(UiTokens.radiusXL)
            .onClick(() => {
              this.showYesterdaySummary = false
            })
        }
        .width('100%')
        .padding(UiTokens.pagePadding)
        .backgroundColor(UiTokens.bgCard)
        .borderRadius({ topLeft: 24, topRight: 24 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.End)
    }
  }
  .width('100%')
  .height('100%')
  }

  @Builder
  SwipeActionBuilder(task: Task) {
    Row({ space: 8 }) {
      Button() {
        Text('完成')
          .fontSize(UiTokens.textS)
          .fontColor('#FFFFFF')
      }
      .width(60)
      .height('100%')
      .backgroundColor(UiTokens.done)
      .borderRadius(UiTokens.radiusM)
      .onClick(async () => {
        const all = await dataStore.getActiveTasks()
        const idx = all.findIndex(t => t.id === task.id)
        if (idx >= 0) {
          all[idx].status = TaskStatus.DONE
          all[idx].updatedAt = Date.now()
          await dataStore.saveTasks(all)
          await this.loadData()
        }
      })

      Button() {
        Text('删除')
          .fontSize(UiTokens.textS)
          .fontColor('#FFFFFF')
      }
      .width(60)
      .height('100%')
      .backgroundColor(UiTokens.error)
      .borderRadius(UiTokens.radiusM)
      .onClick(async () => {
        await dataStore.softDeleteTask(task.id)
        await this.loadData()
      })
    }
    .padding({ left: 4, right: UiTokens.pagePadding })
    .height(72)
  }

  @Builder
  NavItem(label: string, tabIndex: number) {
    Column() {
      Text(label)
        .fontSize(this.settings.largeText ? UiTokens.textM : UiTokens.textS)
        .fontColor(this.activeTab === tabIndex
          ? UiTokens.brand
          : (this.settings.highContrast ? '#555555' : UiTokens.textSecondary))
        .fontWeight(this.activeTab === tabIndex ? FontWeight.Medium : FontWeight.Regular)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.activeTab = tabIndex
    })
  }
}
