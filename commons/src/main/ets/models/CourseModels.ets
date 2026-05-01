// ===== 课表相关数据模型 =====

export enum WeekType {
  EVERY = 'EVERY',
  ODD = 'ODD',
  EVEN = 'EVEN'
}

export class TimeSlot {
  slotNumber: number
  startTime: string
  endTime: string

  constructor(slotNumber: number, startTime: string, endTime: string) {
    this.slotNumber = slotNumber
    this.startTime = startTime
    this.endTime = endTime
  }
}

export class Course {
  id: string
  name: string
  classroom: string
  teacher: string
  dayOfWeek: number        // 1-7 周一到周日
  startSlot: number        // 开始节次
  slotCount: number        // 连续节数
  weekType: WeekType
  startWeek: number
  endWeek: number
  color: string

  constructor(
    name: string,
    classroom: string,
    teacher: string,
    dayOfWeek: number,
    startSlot: number,
    slotCount: number,
    weekType: WeekType = WeekType.EVERY,
    startWeek: number = 1,
    endWeek: number = 20
  ) {
    this.id = 'course_' + Date.now() + '_' + Math.random().toString(36).substring(2, 8)
    this.name = name
    this.classroom = classroom
    this.teacher = teacher
    this.dayOfWeek = dayOfWeek
    this.startSlot = startSlot
    this.slotCount = slotCount
    this.weekType = weekType
    this.startWeek = startWeek
    this.endWeek = endWeek
    this.color = this.pickColor()
  }

  private pickColor(): string {
    const colors = [
      '#FF9F7F', '#FFDB5C', '#67E0E3', '#37A2DA', '#32C5E9',
      '#9FE6B8', '#FB7293', '#E062AE', '#E690D1', '#E7BCF3',
      '#8378EA', '#96BFFF', '#FF9F43', '#FECA57', '#48DBFB',
      '#1DD1A1', '#5F27CD', '#54A0FF', '#00D2D3', '#FF9FF3'
    ]
    return colors[Math.floor(Math.random() * colors.length)]
  }
}

export const DEFAULT_TIME_SLOTS: TimeSlot[] = [
  new TimeSlot(1, '08:00', '08:45'),
  new TimeSlot(2, '08:55', '09:40'),
  new TimeSlot(3, '10:00', '10:45'),
  new TimeSlot(4, '10:55', '11:40'),
  new TimeSlot(5, '14:00', '14:45'),
  new TimeSlot(6, '14:55', '15:40'),
  new TimeSlot(7, '16:00', '16:45'),
  new TimeSlot(8, '16:55', '17:40'),
]

export const WEEKDAY_LABELS: string[] = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']

export class CourseScheduleState {
  currentWeek: number
  totalWeeks: number
  timeSlots: TimeSlot[]
  courses: Course[]
  semesterStartDate: string   // 开学日期 YYYY-MM-DD

  constructor() {
    this.currentWeek = 1
    this.totalWeeks = 20
    this.timeSlots = DEFAULT_TIME_SLOTS.map(s => new TimeSlot(s.slotNumber, s.startTime, s.endTime))
    this.courses = []
    this.semesterStartDate = ''
  }
}
