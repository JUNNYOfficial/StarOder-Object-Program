import { router, promptAction } from '@kit.ArkUI'
import { Task, TaskStatus, UserPreferences, YesterdaySummary } from '../models/DataModels'
import { dataStore } from '../models/DataStore'
import { ScheduleCard } from '../components/ScheduleCard'
import { CalendarTab } from '../components/CalendarTab'
import { TimerTab } from '../components/TimerTab'
import { SettingsTab } from '../components/SettingsTab'
import { UiTokens } from '../design/UiTokens'
import { addDays, todayStr } from '../utils/DateUtils'
import { CourseScheduleState, Course, WeekType } from '../models/CourseModels'

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

  aboutToAppear() {
    const now = new Date()
    this.currentDate = this.formatDate(now)
    this.greeting = this.getGreeting(now)
    this.loadData()
    if (!dataStore.hasAgreedToTerms()) {
      this.showTermsDialog = true
    }
    this.checkYesterdaySummary()
  }

  private checkYesterdaySummary(): void {
    if (dataStore.shouldShowYesterdaySummary()) {
      this.yesterdaySummary = dataStore.getStoredYesterdaySummary()
      this.showYesterdaySummary = true
      dataStore.setShouldShowYesterdaySummary(false)
    }
  }

  onPageShow() {
    this.loadData()
  }

  loadData() {
    this.settings = dataStore.getUserPrefs()
    this.tasks = dataStore.getTasksByDate(this.currentDate)
    this.applyFilter()
    this.courseState = dataStore.getCourseState()
    this.todayCourses = this.getTodayCourses()
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

  private getCourseTimeText(course: Course): string {
    const startSlot = this.courseState.timeSlots.find(s => s.slotNumber === course.startSlot)
    const endSlotNum = course.startSlot + course.slotCount - 1
    const endSlot = this.courseState.timeSlots.find(s => s.slotNumber === endSlotNum)
    if (startSlot && endSlot) {
      return `${startSlot.startTime}-${endSlot.endTime}`
    }
    return `第${course.startSlot}-${endSlotNum}节`
  }

  prevDay() {
    this.currentDate = addDays(this.currentDate, -1)
    this.loadData()
  }

  nextDay() {
    this.currentDate = addDays(this.currentDate, 1)
    this.loadData()
  }

  goToday() {
    this.currentDate = this.formatDate(new Date())
    this.loadData()
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

  formatDate(d: Date): string {
    const y = d.getFullYear()
    const m = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${y}-${m}-${day}`
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

  advanceStatus(task: Task) {
    const all = dataStore.getActiveTasks()
    const idx = all.findIndex(t => t.id === task.id)
    if (idx >= 0) {
      const statusOrder = [TaskStatus.TODO, TaskStatus.STARTED, TaskStatus.MOSTLY, TaskStatus.DONE]
      const currentIdx = statusOrder.indexOf(all[idx].status)
      all[idx].status = statusOrder[(currentIdx + 1) % statusOrder.length]
      all[idx].updatedAt = Date.now()
      dataStore.saveTasks(all)
      this.loadData()
    }
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
              .onClick(() => { this.prevDay() })

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
              .onClick(() => { this.nextDay() })

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
                .onClick(() => { this.goToday() })
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
                      Text(this.getCourseTimeText(course))
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
          List({ space: 0 }) {
            ListItem() {
              Column({ space: 0 }) {
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
                                                          Text(this.getCourseTimeText(course))
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
              }
              .width('100%')
            }

            ForEach(this.filteredTasks, (task: Task) => {
              ListItem() {
                ScheduleCard({
                  task: task,
                  settings: this.settings,
                  onClickCard: () => {
                    router.pushUrl({ url: 'pages/ScheduleDetail', params: { id: task.id } })
                  },
                  onToggleStatus: () => {
                    this.advanceStatus(task)
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
              .onClick(() => {
                dataStore.setAgreedToTerms(true)
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
      .onClick(() => {
        const all = dataStore.getActiveTasks()
        const idx = all.findIndex(t => t.id === task.id)
        if (idx >= 0) {
          all[idx].status = TaskStatus.DONE
          all[idx].updatedAt = Date.now()
          dataStore.saveTasks(all)
          this.loadData()
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
      .onClick(() => {
        dataStore.softDeleteTask(task.id)
        this.loadData()
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
