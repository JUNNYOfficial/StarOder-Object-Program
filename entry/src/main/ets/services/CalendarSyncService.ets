import { calendarManager } from '@kit.CalendarKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit'
import { Course, TimeSlot, WeekType, CourseScheduleState } from '../models/CourseModels'

const TAG = '[CalendarSync]'

class CalendarSyncServiceClass {
  private calendarMgr: calendarManager.CalendarManager | null = null
  private initialized: boolean = false

  async init(context: Context): Promise<boolean> {
    if (this.initialized) return true
    try {
      const permissions: Permissions[] = [
        'ohos.permission.READ_CALENDAR',
        'ohos.permission.WRITE_CALENDAR'
      ]
      const atManager = abilityAccessCtrl.createAtManager()
      const result = await atManager.requestPermissionsFromUser(context, permissions)
      const allGranted = result.authResults.every(r => r === 0)
      if (!allGranted) {
        console.error(TAG, '日历权限被拒绝')
        return false
      }
      this.calendarMgr = calendarManager.getCalendarManager(context)
      this.initialized = true
      return true
    } catch (e) {
      console.error(TAG, '初始化失败:', JSON.stringify(e))
      return false
    }
  }

  async syncCoursesToCalendar(
    state: CourseScheduleState,
    context: Context,
    onResult: (success: number, failed: number, msg: string) => void
  ): Promise<void> {
    const granted = await this.init(context)
    if (!granted) {
      onResult(0, 0, '需要日历权限才能同步')
      return
    }

    try {
      const calendar = await this.calendarMgr!.getCalendar()
      let success = 0
      let failed = 0

      for (let i = 0; i < state.courses.length; i++) {
        const course = state.courses[i]
        try {
          await this.addOrUpdateCourseEvent(calendar, course, state)
          success++
        } catch (e) {
          console.error(TAG, `同步课程失败 ${course.name}:`, JSON.stringify(e))
          failed++
        }
      }

      onResult(success, failed, `成功 ${success} 个，失败 ${failed} 个`)
    } catch (e) {
      console.error(TAG, '获取日历失败:', JSON.stringify(e))
      onResult(0, 0, '获取系统日历失败')
    }
  }

  private async addOrUpdateCourseEvent(
    calendar: calendarManager.Calendar,
    course: Course,
    state: CourseScheduleState
  ): Promise<void> {
    const startSlot = state.timeSlots.find(s => s.slotNumber === course.startSlot)
    if (!startSlot) return

    const endSlotNum = course.startSlot + course.slotCount - 1
    const endSlot = state.timeSlots.find(s => s.slotNumber === endSlotNum)
    if (!endSlot) return

    // 计算开学日期
    const baseDate = state.semesterStartDate
      ? new Date(state.semesterStartDate)
      : this.getCurrentSemesterStart()

    // 生成每周的日程
    for (let w = course.startWeek; w <= course.endWeek; w++) {
      if (course.weekType === WeekType.ODD && w % 2 === 0) continue
      if (course.weekType === WeekType.EVEN && w % 2 === 1) continue

      const eventDate = new Date(baseDate)
      eventDate.setDate(eventDate.getDate() + (w - 1) * 7 + (course.dayOfWeek - 1))

      const [startH, startM] = startSlot.startTime.split(':').map(Number)
      const [endH, endM] = endSlot.endTime.split(':').map(Number)

      const startTime = new Date(eventDate)
      startTime.setHours(startH, startM, 0, 0)
      const endTime = new Date(eventDate)
      endTime.setHours(endH, endM, 0, 0)

      const event: calendarManager.Event = {
        type: calendarManager.EventType.NORMAL,
        title: course.name,
        location: course.classroom,
        description: `教师: ${course.teacher || '未指定'}\n第 ${w} 周`,
        startTime: startTime.getTime(),
        endTime: endTime.getTime(),
        reminderTime: [15] // 提前15分钟提醒
      }

      await calendar.addEvent(event)
    }
  }

  private getCurrentSemesterStart(): Date {
    const now = new Date()
    const year = now.getFullYear()
    const month = now.getMonth()
    // 简单判断：9月前认为春季学期2月开始，9月后认为秋季学期9月开始
    if (month < 6) {
      return new Date(year, 1, 17) // 2月中旬
    } else {
      return new Date(year, 8, 1) // 9月1日
    }
  }
}

export const CalendarSyncService = new CalendarSyncServiceClass()
