import { router, promptAction } from '@kit.ArkUI'
import { dataStore } from '../models/DataStore'
import { Course, TimeSlot, CourseScheduleState, WeekType, WEEKDAY_LABELS, DEFAULT_TIME_SLOTS } from '../models/CourseModels'
import { UiTokens } from '../design/UiTokens'

@Entry
@Component
struct CourseSchedulePage {
  @State state: CourseScheduleState = new CourseScheduleState()
  @State selectedWeek: number = 1
  @State showEditPanel: boolean = false
  @State editingCourse: Course | null = null

  // 编辑表单
  @State editName: string = ''
  @State editClassroom: string = ''
  @State editTeacher: string = ''
  @State editDay: number = 1
  @State editStartSlot: number = 1
  @State editSlotCount: number = 1
  @State editWeekType: WeekType = WeekType.EVERY
  @State editStartWeek: number = 1
  @State editEndWeek: number = 20

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
                ForEach(this.state.timeSlots, (slot: TimeSlot) => {
                  const courses = this.coursesForCell(day, slot.slotNumber)
                  const course = courses.length > 0 ? courses[0] : null
                  Stack() {
                    if (course && slot.slotNumber === course.startSlot) {
                      Column() {
                        Text(course.name)
                          .fontSize(11)
                          .fontColor('#FFFFFF')
                          .fontWeight(FontWeight.Medium)
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        if (course.classroom) {
                          Text(course.classroom)
                            .fontSize(9)
                            .fontColor('rgba(255,255,255,0.85)')
                            .maxLines(1)
                        }
                      }
                      .width('95%')
                      .height(`${course.slotCount * 80 - 4}px`)
                      .padding(4)
                      .backgroundColor(course.color)
                      .borderRadius(UiTokens.radiusM)
                      .justifyContent(FlexAlign.Center)
                      .alignItems(HorizontalAlign.Center)
                      .onClick(() => this.openEdit(course))
                    }
                  }
                  .width('100%')
                  .height(80)
                  .border({ width: { bottom: 0.5, right: 0.5 }, color: UiTokens.divider })
                  .backgroundColor(this.coursesForCell(day, slot.slotNumber).length === 0 ? UiTokens.bgCard : 'transparent')
                  .onClick(() => {
                    if (!course) this.openAdd(day, slot.slotNumber)
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
        .height(56)
        .padding({ left: UiTokens.pagePadding, right: UiTokens.pagePadding })
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
                Select([{ value: '周一' }, { value: '周二' }, { value: '周三' }, { value: '周四' }, { value: '周五' }, { value: '周六' }, { value: '周日' }])
                  .selected(this.editDay - 1)
                  .value(WEEKDAY_LABELS[this.editDay - 1])
                  .onSelect((index: number) => { this.editDay = index + 1 })
              }
              .layoutWeight(1)

              Column({ space: 4 }) {
                Text('开始节')
                  .fontSize(UiTokens.textS)
                  .fontColor(UiTokens.textSecondary)
                Select(this.state.timeSlots.map(s => ({ value: `第${s.slotNumber}节` })))
                  .selected(this.editStartSlot - 1)
                  .value(`第${this.editStartSlot}节`)
                  .onSelect((index: number) => { this.editStartSlot = index + 1 })
              }
              .layoutWeight(1)

              Column({ space: 4 }) {
                Text('节数')
                  .fontSize(UiTokens.textS)
                  .fontColor(UiTokens.textSecondary)
                Select([{ value: '1节' }, { value: '2节' }, { value: '3节' }, { value: '4节' }])
                  .selected(this.editSlotCount - 1)
                  .value(`${this.editSlotCount}节`)
                  .onSelect((index: number) => { this.editSlotCount = index + 1 })
              }
              .layoutWeight(1)
            }
            .width('100%')

            Row({ space: UiTokens.gapM }) {
              Column({ space: 4 }) {
                Text('周次类型')
                  .fontSize(UiTokens.textS)
                  .fontColor(UiTokens.textSecondary)
                Select([{ value: '每周' }, { value: '单周' }, { value: '双周' }])
                  .selected(this.editWeekType === WeekType.EVERY ? 0 : this.editWeekType === WeekType.ODD ? 1 : 2)
                  .value(this.editWeekType === WeekType.EVERY ? '每周' : this.editWeekType === WeekType.ODD ? '单周' : '双周')
                  .onSelect((index: number) => {
                    this.editWeekType = index === 0 ? WeekType.EVERY : index === 1 ? WeekType.ODD : WeekType.EVEN
                  })
              }
              .layoutWeight(1)

              Column({ space: 4 }) {
                Text('开始周')
                  .fontSize(UiTokens.textS)
                  .fontColor(UiTokens.textSecondary)
                TextInput({ text: $$this.editStartWeek.toString() })
                  .width('100%')
                  .height(40)
                  .backgroundColor(UiTokens.bgHover)
                  .borderRadius(UiTokens.radiusL)
                  .type(InputType.Number)
              }
              .layoutWeight(1)

              Column({ space: 4 }) {
                Text('结束周')
                  .fontSize(UiTokens.textS)
                  .fontColor(UiTokens.textSecondary)
                TextInput({ text: $$this.editEndWeek.toString() })
                  .width('100%')
                  .height(40)
                  .backgroundColor(UiTokens.bgHover)
                  .borderRadius(UiTokens.radiusL)
                  .type(InputType.Number)
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
    }
    .width('100%')
    .height('100%')
  }
}
