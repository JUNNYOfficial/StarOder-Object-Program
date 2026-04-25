import { router, promptAction } from '@kit.ArkUI'
import { dataStore } from '../models/DataStore'
import { Course, TimeSlot, CourseScheduleState, WeekType, WEEKDAY_LABELS } from '../models/CourseModels'
import { CalendarSyncService, CalendarInfo } from '../services/CalendarSyncService'
import { UiTokens } from '../design/UiTokens'
class SlotCellData {
  slot: TimeSlot
  course: Course | null
  constructor(slot: TimeSlot, course: Course | null) {
    this.slot = slot
    this.course = course
  }
}

@Entry
@Component
struct CourseSchedulePage {
  @State state: CourseScheduleState = new CourseScheduleState()
  @State selectedWeek: number = 1
  @State showEditPanel: boolean = false
  @State editingCourse: Course | null = null

  @State editName: string = ''
  @State editClassroom: string = ''
  @State editTeacher: string = ''
  @State editDay: number = 1
  @State editStartSlot: number = 1
  @State editSlotCount: number = 1
  @State editWeekType: WeekType = WeekType.EVERY
  @State editStartWeek: number = 1
  @State editEndWeek: number = 20

  @State showCalendarPicker: boolean = false
  @State calendarOptions: CalendarInfo[] = []
  @State selectedCalendarId: number = -1

  aboutToAppear() {
    this.state = dataStore.getCourseState()
    this.selectedWeek = this.state.currentWeek
  }

  private coursesForCell(day: number, slot: number): Course[] {
    return this.state.courses.filter(c => {
      if (c.dayOfWeek !== day) return false
      if (slot < c.startSlot || slot >= c.startSlot + c.slotCount) return false
      if (this.selectedWeek < c.startWeek || this.selectedWeek > c.endWeek) return false
      if (c.weekType === WeekType.ODD && this.selectedWeek % 2 === 0) return false
      if (c.weekType === WeekType.EVEN && this.selectedWeek % 2 === 1) return false
      return true
    })
  }

  private buildSlotCells(day: number): SlotCellData[] {
    const result: SlotCellData[] = []
    for (let i = 0; i < this.state.timeSlots.length; i++) {
      const slot = this.state.timeSlots[i]
      const courses = this.coursesForCell(day, slot.slotNumber)
      result.push(new SlotCellData(slot, courses.length > 0 ? courses[0] : null))
    }
    return result
  }

  private prevWeek() {
    if (this.selectedWeek > 1) this.selectedWeek--
  }

  private nextWeek() {
    if (this.selectedWeek < this.state.totalWeeks) this.selectedWeek++
  }

  private goCurrentWeek() {
    this.selectedWeek = this.state.currentWeek
  }

  private openAdd(day: number, slot: number) {
    this.editingCourse = null
    this.editName = ''
    this.editClassroom = ''
    this.editTeacher = ''
    this.editDay = day
    this.editStartSlot = slot
    this.editSlotCount = 1
    this.editWeekType = WeekType.EVERY
    this.editStartWeek = 1
    this.editEndWeek = this.state.totalWeeks
    this.showEditPanel = true
  }

  private openEdit(course: Course) {
    this.editingCourse = course
    this.editName = course.name
    this.editClassroom = course.classroom
    this.editTeacher = course.teacher
    this.editDay = course.dayOfWeek
    this.editStartSlot = course.startSlot
    this.editSlotCount = course.slotCount
    this.editWeekType = course.weekType
    this.editStartWeek = course.startWeek
    this.editEndWeek = course.endWeek
    this.showEditPanel = true
  }

  private saveCourse() {
    if (!this.editName.trim()) {
      promptAction.showToast({ message: '请输入课程名称' })
      return
    }
    if (this.editingCourse) {
      const c = this.editingCourse
      c.name = this.editName.trim()
      c.classroom = this.editClassroom.trim()
      c.teacher = this.editTeacher.trim()
      c.dayOfWeek = this.editDay
      c.startSlot = this.editStartSlot
      c.slotCount = this.editSlotCount
      c.weekType = this.editWeekType
      c.startWeek = this.editStartWeek
      c.endWeek = this.editEndWeek
      dataStore.updateCourse(c)
    } else {
      const c = new Course(
        this.editName.trim(),
        this.editClassroom.trim(),
        this.editTeacher.trim(),
        this.editDay,
        this.editStartSlot,
        this.editSlotCount,
        this.editWeekType,
        this.editStartWeek,
        this.editEndWeek
      )
      dataStore.addCourse(c)
    }
    this.state.courses = dataStore.getCourses()
    this.showEditPanel = false
    promptAction.showToast({ message: '已保存' })
  }

  private deleteCurrentCourse() {
    if (this.editingCourse) {
      dataStore.deleteCourse(this.editingCourse.id)
      this.state.courses = dataStore.getCourses()
      this.showEditPanel = false
      promptAction.showToast({ message: '已删除' })
    }
  }

  private syncToCalendar() {
    if (this.state.courses.length === 0) {
      promptAction.showToast({ message: '没有课程可同步' })
      return
    }
    CalendarSyncService.getCalendars(getContext(this))
      .then((calendars: CalendarInfo[]) => {
        if (calendars.length === 0) {
          promptAction.showToast({ message: '未找到可用日历，请先添加日历账户' })
          return
        }
        this.calendarOptions = calendars
        this.showCalendarPicker = true
      })
      .catch(() => {
        promptAction.showToast({ message: '获取日历列表失败' })
      })
  }

  private confirmSyncToCalendar(calendarId: number) {
    this.showCalendarPicker = false
    promptAction.showToast({ message: '正在同步到系统日历...' })
    CalendarSyncService.syncCoursesToCalendar(this.state, getContext(this), calendarId, (success, failed, msg) => {
      promptAction.showToast({ message: msg, duration: 3000 })
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
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
          .onClick(() => this.prevWeek())

          Text(`第 ${this.selectedWeek} 周`)
            .fontSize(UiTokens.textXL)
            .fontWeight(FontWeight.Bold)
            .fontColor(UiTokens.textPrimary)

          Button() {
            Text('>')
              .fontSize(UiTokens.textL)
              .fontColor(UiTokens.textPrimary)
          }
          .width(36)
          .height(36)
          .backgroundColor(UiTokens.bgHover)
          .borderRadius(UiTokens.radiusM)
          .onClick(() => this.nextWeek())

          if (this.selectedWeek !== this.state.currentWeek) {
            Button('本周')
              .fontSize(UiTokens.textS)
              .fontColor(UiTokens.brand)
              .backgroundColor(UiTokens.brandSoft)
              .padding({ left: 10, right: 10, top: 4, bottom: 4 })
              .borderRadius(UiTokens.radiusM)
              .onClick(() => this.goCurrentWeek())
          }
        }
        .width('100%')
        .height(48)
        .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)

        // Weekday header
        Row() {
          // 左上角空白
          Column() {
            Text('')
          }
          .width(60)

          ForEach(WEEKDAY_LABELS, (label: string, index: number) => {
            Column() {
              Text(label)
                .fontSize(UiTokens.textS)
                .fontColor(UiTokens.textPrimary)
                .fontWeight(FontWeight.Medium)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Center)
          })
        }
        .width('100%')
        .height(36)
        .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })

        // Schedule grid
        Scroll() {
          Row() {
            // Left time column
            Column({ space: 0 }) {
              ForEach(this.state.timeSlots, (slot: TimeSlot) => {
                Column() {
                  Text(String(slot.slotNumber))
                    .fontSize(UiTokens.textM)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(UiTokens.textPrimary)
                  Text(slot.startTime)
                    .fontSize(10)
                    .fontColor(UiTokens.textTertiary)
                  Text(slot.endTime)
                    .fontSize(10)
                    .fontColor(UiTokens.textTertiary)
                }
                .width(60)
                .height(80)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .border({ width: { bottom: 0.5 }, color: UiTokens.divider })
              })
            }
            .width(60)

            // Grid columns
            ForEach([1, 2, 3, 4, 5, 6, 7], (day: number) => {
              Column({ space: 0 }) {
                ForEach(this.buildSlotCells(day), (cell: SlotCellData) => {
                  Stack() {
                    if (cell.course && cell.slot.slotNumber === cell.course.startSlot) {
                      Column() {
                        Text(cell.course.name)
                          .fontSize(11)
                          .fontColor('#FFFFFF')
                          .fontWeight(FontWeight.Medium)
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        if (cell.course.classroom) {
                          Text(cell.course.classroom)
                            .fontSize(9)
                            .fontColor('rgba(255,255,255,0.85)')
                            .maxLines(1)
                        }
                      }
                      .width('95%')
                      .height(`${cell.course.slotCount * 80 - 4}px`)
                      .padding(4)
                      .backgroundColor(cell.course.color)
                      .borderRadius(UiTokens.radiusM)
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)
                      .onClick(() => {
                        if (cell.course) this.openEdit(cell.course)
                      })
                    }
                  }
                  .width('100%')
                  .height(80)
                  .border({ width: { bottom: 0.5, right: 0.5 }, color: UiTokens.divider })
                  .backgroundColor(cell.course ? 'transparent' : UiTokens.bgCard)
                  .onClick(() => {
                    if (!cell.course) this.openAdd(day, cell.slot.slotNumber)
                  })
                })
              }
              .layoutWeight(1)
            })
          }
          .width('100%')
          .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)

        // Bottom actions
        Column({ space: UiTokens.gapM }) {
          Row({ space: UiTokens.gapM }) {
            Button('时间段设置')
              .layoutWeight(1)
              .height(40)
              .fontSize(UiTokens.textS)
              .fontColor(UiTokens.textInverse)
              .backgroundColor(UiTokens.brand)
              .borderRadius(UiTokens.radiusL)
              .onClick(() => {
                router.pushUrl({ url: 'pages/TimeSlotSettingsPage' })
              })

            Button('批量导入')
              .layoutWeight(1)
              .height(40)
              .fontSize(UiTokens.textS)
              .fontColor(UiTokens.textInverse)
              .backgroundColor(UiTokens.brand)
              .borderRadius(UiTokens.radiusL)
              .onClick(() => {
                router.pushUrl({ url: 'pages/CourseImportPage' })
              })
          }
          .width('100%')

          Button('同步到华为日历')
            .width('100%')
            .height(40)
            .fontSize(UiTokens.textS)
            .fontColor(UiTokens.brand)
            .backgroundColor(UiTokens.brandSoft)
            .borderRadius(UiTokens.radiusL)
            .onClick(() => {
              this.syncToCalendar()
            })
        }
        .width('100%')
        .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })
        .padding({ bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(UiTokens.bgPage)

      // Edit panel overlay
      if (this.showEditPanel) {
        Column() {
          // Backdrop
          Column()
            .width('100%')
            .layoutWeight(1)
            .backgroundColor('rgba(0,0,0,0.4)')
            .onClick(() => { this.showEditPanel = false })

          // Panel
          Column({ space: UiTokens.gapM }) {
            Row() {
              Text(this.editingCourse ? '编辑课程' : '添加课程')
                .fontSize(UiTokens.textXL)
                .fontWeight(FontWeight.Bold)
                .fontColor(UiTokens.textPrimary)
                .layoutWeight(1)

              if (this.editingCourse) {
                Text('删除')
                  .fontSize(UiTokens.textM)
                  .fontColor(UiTokens.error)
                  .onClick(() => this.deleteCurrentCourse())
              }
            }
            .width('100%')

            TextInput({ placeholder: '课程名称', text: $$this.editName })
              .width('100%')
              .height(44)
              .backgroundColor(UiTokens.bgHover)
              .borderRadius(UiTokens.radiusL)

            TextInput({ placeholder: '教室', text: $$this.editClassroom })
              .width('100%')
              .height(44)
              .backgroundColor(UiTokens.bgHover)
              .borderRadius(UiTokens.radiusL)

            TextInput({ placeholder: '教师', text: $$this.editTeacher })
              .width('100%')
              .height(44)
              .backgroundColor(UiTokens.bgHover)
              .borderRadius(UiTokens.radiusL)

            Row({ space: UiTokens.gapM }) {
              Column({ space: 4 }) {
                Text('星期')
                  .fontSize(UiTokens.textS)
                  .fontColor(UiTokens.textSecondary)
                Row() {
                  Text('<')
                    .fontSize(16)
                    .fontColor(this.editDay > 1 ? UiTokens.brand : UiTokens.textTertiary)
                    .onClick(() => { if (this.editDay > 1) this.editDay-- })
                  Text(WEEKDAY_LABELS[this.editDay - 1])
                    .fontSize(14)
                    .fontColor(UiTokens.textPrimary)
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)
                  Text('>')
                    .fontSize(16)
                    .fontColor(this.editDay < 7 ? UiTokens.brand : UiTokens.textTertiary)
                    .onClick(() => { if (this.editDay < 7) this.editDay++ })
                }
                .width('100%')
                .height(40)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusL)
                .padding({ left: 8, right: 8 })
              }
              .layoutWeight(1)

              Column({ space: 4 }) {
                Text('开始节')
                  .fontSize(UiTokens.textS)
                  .fontColor(UiTokens.textSecondary)
                Row() {
                  Text('<')
                    .fontSize(16)
                    .fontColor(this.editStartSlot > 1 ? UiTokens.brand : UiTokens.textTertiary)
                    .onClick(() => { if (this.editStartSlot > 1) this.editStartSlot-- })
                  Text(`第${this.editStartSlot}节`)
                    .fontSize(14)
                    .fontColor(UiTokens.textPrimary)
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)
                  Text('>')
                    .fontSize(16)
                    .fontColor(this.editStartSlot < this.state.timeSlots.length ? UiTokens.brand : UiTokens.textTertiary)
                    .onClick(() => { if (this.editStartSlot < this.state.timeSlots.length) this.editStartSlot++ })
                }
                .width('100%')
                .height(40)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusL)
                .padding({ left: 8, right: 8 })
              }
              .layoutWeight(1)

              Column({ space: 4 }) {
                Text('节数')
                  .fontSize(UiTokens.textS)
                  .fontColor(UiTokens.textSecondary)
                Row() {
                  Text('<')
                    .fontSize(16)
                    .fontColor(this.editSlotCount > 1 ? UiTokens.brand : UiTokens.textTertiary)
                    .onClick(() => { if (this.editSlotCount > 1) this.editSlotCount-- })
                  Text(`${this.editSlotCount}节`)
                    .fontSize(14)
                    .fontColor(UiTokens.textPrimary)
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)
                  Text('>')
                    .fontSize(16)
                    .fontColor(this.editSlotCount < 4 ? UiTokens.brand : UiTokens.textTertiary)
                    .onClick(() => { if (this.editSlotCount < 4) this.editSlotCount++ })
                }
                .width('100%')
                .height(40)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusL)
                .padding({ left: 8, right: 8 })
              }
              .layoutWeight(1)
            }
            .width('100%')

            Row({ space: UiTokens.gapM }) {
              Column({ space: 4 }) {
                Text('周次类型')
                  .fontSize(UiTokens.textS)
                  .fontColor(UiTokens.textSecondary)
                Row() {
                  Text('<')
                    .fontSize(16)
                    .fontColor(UiTokens.brand)
                    .onClick(() => {
                      if (this.editWeekType === WeekType.EVERY) this.editWeekType = WeekType.EVEN
                      else if (this.editWeekType === WeekType.ODD) this.editWeekType = WeekType.EVERY
                      else this.editWeekType = WeekType.ODD
                    })
                  Text(this.editWeekType === WeekType.EVERY ? '每周' : this.editWeekType === WeekType.ODD ? '单周' : '双周')
                    .fontSize(14)
                    .fontColor(UiTokens.textPrimary)
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)
                  Text('>')
                    .fontSize(16)
                    .fontColor(UiTokens.brand)
                    .onClick(() => {
                      if (this.editWeekType === WeekType.EVERY) this.editWeekType = WeekType.ODD
                      else if (this.editWeekType === WeekType.ODD) this.editWeekType = WeekType.EVEN
                      else this.editWeekType = WeekType.EVERY
                    })
                }
                .width('100%')
                .height(40)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusL)
                .padding({ left: 8, right: 8 })
              }
              .layoutWeight(1)

              Column({ space: 4 }) {
                Text('开始周')
                  .fontSize(UiTokens.textS)
                  .fontColor(UiTokens.textSecondary)
                Row() {
                  Text('<')
                    .fontSize(16)
                    .fontColor(this.editStartWeek > 1 ? UiTokens.brand : UiTokens.textTertiary)
                    .onClick(() => { if (this.editStartWeek > 1) this.editStartWeek-- })
                  Text(`${this.editStartWeek}`)
                    .fontSize(14)
                    .fontColor(UiTokens.textPrimary)
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)
                  Text('>')
                    .fontSize(16)
                    .fontColor(this.editStartWeek < this.state.totalWeeks ? UiTokens.brand : UiTokens.textTertiary)
                    .onClick(() => { if (this.editStartWeek < this.state.totalWeeks) this.editStartWeek++ })
                }
                .width('100%')
                .height(40)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusL)
                .padding({ left: 8, right: 8 })
              }
              .layoutWeight(1)

              Column({ space: 4 }) {
                Text('结束周')
                  .fontSize(UiTokens.textS)
                  .fontColor(UiTokens.textSecondary)
                Row() {
                  Text('<')
                    .fontSize(16)
                    .fontColor(this.editEndWeek > 1 ? UiTokens.brand : UiTokens.textTertiary)
                    .onClick(() => { if (this.editEndWeek > 1) this.editEndWeek-- })
                  Text(`${this.editEndWeek}`)
                    .fontSize(14)
                    .fontColor(UiTokens.textPrimary)
                    .layoutWeight(1)
                    .textAlign(TextAlign.Center)
                  Text('>')
                    .fontSize(16)
                    .fontColor(this.editEndWeek < this.state.totalWeeks ? UiTokens.brand : UiTokens.textTertiary)
                    .onClick(() => { if (this.editEndWeek < this.state.totalWeeks) this.editEndWeek++ })
                }
                .width('100%')
                .height(40)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusL)
                .padding({ left: 8, right: 8 })
              }
              .layoutWeight(1)
            }
            .width('100%')

            Row({ space: UiTokens.gapM }) {
              Button('取消')
                .layoutWeight(1)
                .height(44)
                .fontColor(UiTokens.textSecondary)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusL)
                .onClick(() => { this.showEditPanel = false })

              Button('保存')
                .layoutWeight(1)
                .height(44)
                .fontColor(UiTokens.textInverse)
                .backgroundColor(UiTokens.brand)
                .borderRadius(UiTokens.radiusL)
                .onClick(() => this.saveCourse())
            }
            .width('100%')
          }
          .width('100%')
          .padding(UiTokens.pagePadding)
          .padding({ bottom: 32 })
          .backgroundColor(UiTokens.bgCard)
          .borderRadius({ topLeft: 24, topRight: 24 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.End)
      }

      // Calendar picker overlay
      if (this.showCalendarPicker) {
        Column() {
          Column()
            .width('100%')
            .layoutWeight(1)
            .backgroundColor('rgba(0,0,0,0.4)')
            .onClick(() => { this.showCalendarPicker = false })

          Column({ space: UiTokens.gapM }) {
            Text('选择同步目标日历')
              .fontSize(UiTokens.textXL)
              .fontWeight(FontWeight.Bold)
              .fontColor(UiTokens.textPrimary)
              .width('100%')

            Column({ space: 0 }) {
              ForEach(this.calendarOptions, (cal: CalendarInfo, index: number) => {
                Row({ space: UiTokens.gapM }) {
                  Column()
                    .width(20)
                    .height(20)
                    .borderRadius(10)
                    .border({ width: 2, color: this.selectedCalendarId === cal.id ? UiTokens.brand : UiTokens.divider })
                    .backgroundColor(this.selectedCalendarId === cal.id ? UiTokens.brand : 'transparent')

                  Column({ space: 2 }) {
                    Text(cal.name)
                      .fontSize(UiTokens.textM)
                      .fontColor(UiTokens.textPrimary)
                      .fontWeight(FontWeight.Medium)

                    Text(cal.isCloud ? '云端日历' : '本地日历')
                      .fontSize(UiTokens.textS)
                      .fontColor(cal.isCloud ? UiTokens.brand : UiTokens.textTertiary)
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .height(52)
                .padding(12)
                .backgroundColor(this.selectedCalendarId === cal.id ? UiTokens.brandSoft : 'transparent')
                .borderRadius(UiTokens.radiusL)
                .onClick(() => { this.selectedCalendarId = cal.id })

                if (index < this.calendarOptions.length - 1) {
                  Divider()
                    .strokeWidth(0.5)
                    .color(UiTokens.divider)
                }
              })
            }
            .width('100%')
            .height(300)

            Row({ space: UiTokens.gapM }) {
              Button('取消')
                .layoutWeight(1)
                .height(44)
                .fontColor(UiTokens.textSecondary)
                .backgroundColor(UiTokens.bgHover)
                .borderRadius(UiTokens.radiusL)
                .onClick(() => { this.showCalendarPicker = false })

              Button('确认同步')
                .layoutWeight(1)
                .height(44)
                .fontColor(UiTokens.textInverse)
                .backgroundColor(UiTokens.brand)
                .borderRadius(UiTokens.radiusL)
                .onClick(() => this.confirmSyncToCalendar(this.selectedCalendarId))
            }
            .width('100%')
          }
          .width('100%')
          .padding(UiTokens.pagePadding)
          .padding({ bottom: 32 })
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
}
