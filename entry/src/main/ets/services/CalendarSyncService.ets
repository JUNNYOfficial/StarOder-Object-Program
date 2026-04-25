import { calendarManager } from '@kit.CalendarKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit'
import { Course, TimeSlot, WeekType, CourseScheduleState } from '../models/CourseModels'

const TAG = '[CalendarSync]'

export class CalendarInfo {
  id: number
  name: string
  accountName: string
  isCloud: boolean
  constructor(id: number, name: string, accountName: string, isCloud: boolean) {
    this.id = id
    this.name = name
    this.accountName = accountName
    this.isCloud = isCloud
  }
}

class CalendarSyncServiceClass {
  private calendarMgr: calendarManager.CalendarManager | null = null
  private initialized: boolean = false

  init(context: Context, onResult: (granted: boolean) => void): void {
    if (this.initialized) {
      onResult(true)
      return
    }
    const permissions: Permissions[] = [
      'ohos.permission.READ_CALENDAR',
      'ohos.permission.WRITE_CALENDAR'
    ]
    const atManager = abilityAccessCtrl.createAtManager()
    atManager.requestPermissionsFromUser(context, permissions)
      .then((result) => {
        const allGranted = result.authResults.every(r => r === 0)
        if (!allGranted) {
          console.error(TAG, '日历权限被拒绝')
          onResult(false)
          return
        }
        this.calendarMgr = calendarManager.getCalendarManager(context)
        this.initialized = true
        onResult(true)
      })
      .catch((error: BusinessError) => {
        console.error(TAG, '初始化失败:', JSON.stringify(error))
        onResult(false)
      })
  }

  getCalendars(context: Context): Promise<CalendarInfo[]> {
    return new Promise((resolve) => {
      this.init(context, (granted) => {
        if (!granted || !this.calendarMgr) {
          resolve([])
          return
        }
        // 原子化服务仅支持 getCalendar()，不支持 getAllCalendars() 和 getAccount()
        this.calendarMgr.getCalendar()
          .then((cal: calendarManager.Calendar) => {
            const displayName = '系统日历'
            resolve([new CalendarInfo(cal.id, displayName, '', false)])
          })
          .catch((err: BusinessError) => {
            console.error(TAG, '获取日历失败:', JSON.stringify(err))
            resolve([])
          })
      })
    })
  }

  syncCoursesToCalendar(
    state: CourseScheduleState,
    context: Context,
    calendarId: number,
    onResult: (success: number, failed: number, msg: string) => void
  ): void {
    this.init(context, (granted) => {
      if (!granted) {
        onResult(0, 0, '需要日历权限才能同步')
        return
      }
      if (!this.calendarMgr) {
        onResult(0, 0, '日历管理器未初始化')
        return
      }

      // 原子化服务不支持 getAllCalendars()，直接使用默认日历
      this.fallbackToDefaultCalendar(state, onResult)
    })
  }

  private fallbackToDefaultCalendar(
    state: CourseScheduleState,
    onResult: (success: number, failed: number, msg: string) => void
  ): void {
    if (!this.calendarMgr) {
      onResult(0, 0, '日历管理器未初始化')
      return
    }
    this.calendarMgr.getCalendar()
      .then((calendar: calendarManager.Calendar) => {
        this.doSyncWithCalendar(state, calendar, onResult)
      })
      .catch((err: BusinessError) => {
        console.error(TAG, '获取默认日历失败:', JSON.stringify(err))
        onResult(0, 0, '获取系统日历失败')
      })
  }

  private doSyncWithCalendar(
    state: CourseScheduleState,
    calendar: calendarManager.Calendar,
    onResult: (success: number, failed: number, msg: string) => void
  ): void {
    let success = 0
    let failed = 0
    const courses = state.courses

    for (let i = 0; i < courses.length; i++) {
      const course = courses[i]
      try {
        this.addCourseEvents(calendar, course, state)
        success++
      } catch (e) {
        console.error(TAG, `同步课程失败 ${course.name}:`, JSON.stringify(e))
        failed++
      }
    }
    onResult(success, failed, `成功 ${success} 个，失败 ${failed} 个`)
  }

  private addCourseEvents(
    calendar: calendarManager.Calendar,
    course: Course,
    state: CourseScheduleState
  ): void {
    const startSlot = state.timeSlots.find(s => s.slotNumber === course.startSlot)
    if (!startSlot) return

    const endSlotNum = course.startSlot + course.slotCount - 1
    const endSlot = state.timeSlots.find(s => s.slotNumber === endSlotNum)
    if (!endSlot) return

    const baseDate = state.semesterStartDate
      ? new Date(state.semesterStartDate)
      : this.getCurrentSemesterStart()

    // 计算第一次上课日期
    const firstWeekOffset = (course.startWeek - 1) * 7 + (course.dayOfWeek - 1)
    const eventDate = new Date(baseDate)
    eventDate.setDate(eventDate.getDate() + firstWeekOffset)

    const startParts = startSlot.startTime.split(':')
    const startH = parseInt(startParts[0])
    const startM = parseInt(startParts[1])

    const endParts = endSlot.endTime.split(':')
    const endH = parseInt(endParts[0])
    const endM = parseInt(endParts[1])

    const startTime = new Date(eventDate)
    startTime.setHours(startH, startM, 0, 0)
    const endTime = new Date(eventDate)
    endTime.setHours(endH, endM, 0, 0)

    // 构建重复规则
    const weekCount = course.endWeek - course.startWeek + 1
    let interval = 1
    let count = weekCount
    if (course.weekType === WeekType.ODD || course.weekType === WeekType.EVEN) {
      interval = 2
      count = Math.ceil(weekCount / 2)
    }

    const event: calendarManager.Event = {
      type: calendarManager.EventType.NORMAL,
      title: course.name,
      description: `教室: ${course.classroom || '未指定'} 教师: ${course.teacher || '未指定'} 第${course.startWeek}-${course.endWeek}周`,
      startTime: startTime.getTime(),
      endTime: endTime.getTime(),
      reminderTime: [15],
      recurrenceRule: {
        recurrenceFrequency: calendarManager.RecurrenceFrequency.WEEKLY,
        interval: interval,
        count: count
      }
    }

    calendar.addEvent(event)
      .then((eventId: number) => {
        console.info(TAG, `添加重复日程成功: ${course.name} id=${eventId}`)
      })
      .catch((err: BusinessError) => {
        console.error(TAG, `添加日程失败: ${err.code} ${err.message}`)
      })
  }

  private getCurrentSemesterStart(): Date {
    const now = new Date()
    const year = now.getFullYear()
    const month = now.getMonth()
    if (month < 6) {
      return new Date(year, 1, 17)
    } else {
      return new Date(year, 8, 1)
    }
  }
}

export const CalendarSyncService = new CalendarSyncServiceClass()
