import { Task, TaskType, TaskIntensity, TimeBlock } from '../models/DataModels'
import { todayStr, tomorrowStr, dayAfterTomorrowStr, formatDate, getWeekdayOffset, addDays } from '../utils/DateUtils'

export class ParsedSchedule {
  title: string
  date: string
  startTime: string
  endTime: string
  durationMinutes: number
  type: TaskType
  intensity: TaskIntensity
  timeBlock: TimeBlock
  notes: string

  constructor() {
    this.title = ''
    this.date = ''
    this.startTime = '09:00'
    this.endTime = '10:00'
    this.durationMinutes = 60
    this.type = TaskType.THINK
    this.intensity = TaskIntensity.MEDIUM
    this.timeBlock = TimeBlock.MORNING
    this.notes = ''
  }
}

interface ParsedTimeResult {
  hour: number
  minute: number
  timeBlock: TimeBlock
}

interface TaskTypeIntensity {
  type: TaskType
  intensity: TaskIntensity
}

const WEEKDAY_MAP: Record<string, number> = {
  '周一': 1, '星期一': 1, '周二': 2, '星期二': 2,
  '周三': 3, '星期三': 3, '周四': 4, '星期四': 4,
  '周五': 5, '星期五': 5, '周六': 6, '星期六': 6,
  '周日': 7, '星期日': 7, '星期天': 7,
  '1': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7,
  '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7, '天': 7
}

function parseDateFromText(text: string): string {
  const today = new Date()

  // 今天
  if (text.includes('今天')) {
    return todayStr()
  }

  // 明天
  if (text.includes('明天')) {
    return tomorrowStr()
  }

  // 后天
  if (text.includes('后天')) {
    return dayAfterTomorrowStr()
  }

  // 大后天
  if (text.includes('大后天')) {
    const d = new Date()
    d.setDate(d.getDate() + 3)
    return formatDate(d)
  }

  // N天后
  const daysLaterMatch = text.match(/(\d+)\s*天后/)
  if (daysLaterMatch) {
    const days = parseInt(daysLaterMatch[1])
    if (days > 0 && days < 365) {
      const d = new Date()
      d.setDate(d.getDate() + days)
      return formatDate(d)
    }
  }

  // N周后
  const weeksLaterMatch = text.match(/(\d+)\s*周后/)
  if (weeksLaterMatch) {
    const weeks = parseInt(weeksLaterMatch[1])
    if (weeks > 0 && weeks < 52) {
      const d = new Date()
      d.setDate(d.getDate() + weeks * 7)
      return formatDate(d)
    }
  }

  // 下周X
  const nextWeekMatch = text.match(/下周([一二三四五六日天]|\d|周一|周二|周三|周四|周五|周六|周日|星期[一二三四五六日])/)
  if (nextWeekMatch) {
    const dayKey = nextWeekMatch[1]
    const targetDay = WEEKDAY_MAP[dayKey] || WEEKDAY_MAP['周' + dayKey]
    if (targetDay !== undefined) {
      const offset = getWeekdayOffset(targetDay)
      const d = new Date()
      d.setDate(d.getDate() + offset)
      return formatDate(d)
    }
  }

  // 本周X
  const thisWeekMatch = text.match(/本周([一二三四五六日天]|\d|周一|周二|周三|周四|周五|周六|周日|星期[一二三四五六日])/)
  if (thisWeekMatch) {
    const dayKey = thisWeekMatch[1]
    const targetDay = WEEKDAY_MAP[dayKey] || WEEKDAY_MAP['周' + dayKey]
    if (targetDay !== undefined) {
      const currentDay = today.getDay() === 0 ? 7 : today.getDay()
      let offset = targetDay - currentDay
      if (offset >= 0) {
        const d = new Date()
        d.setDate(d.getDate() + offset)
        return formatDate(d)
      }
    }
  }

  // 星期X（不带本周/下周，默认本周或下周）
  const weekdayMatch = text.match(/星期?([一二三四五六日天])/)
  if (weekdayMatch) {
    const targetDay = WEEKDAY_MAP[weekdayMatch[0]]
    if (targetDay !== undefined) {
      const offset = getWeekdayOffset(targetDay)
      const d = new Date()
      d.setDate(d.getDate() + offset)
      return formatDate(d)
    }
  }

  // 具体日期 MM月DD日 或 M月D日
  const monthDayMatch = text.match(/(\d{1,2})月(\d{1,2})[日号]/)
  if (monthDayMatch) {
    const month = parseInt(monthDayMatch[1]) - 1
    const day = parseInt(monthDayMatch[2])
    const year = today.getFullYear()
    const candidate = new Date(year, month, day)
    // 如果日期已过，假设是明年
    if (candidate.getTime() < today.getTime() - 24 * 60 * 60 * 1000) {
      candidate.setFullYear(year + 1)
    }
    return formatDate(candidate)
  }

  // 具体日期 MM-DD 或 MM/DD
  const dateSlashMatch = text.match(/(\d{1,2})[\/-](\d{1,2})/)
  if (dateSlashMatch && !text.includes('点') && !text.includes(':')) {
    const month = parseInt(dateSlashMatch[1]) - 1
    const day = parseInt(dateSlashMatch[2])
    const year = today.getFullYear()
    const candidate = new Date(year, month, day)
    if (candidate.getTime() < today.getTime() - 24 * 60 * 60 * 1000) {
      candidate.setFullYear(year + 1)
    }
    return formatDate(candidate)
  }

  return todayStr()
}

function parseTimeFromText(text: string): ParsedTimeResult {
  let hour = 9
  let minute = 0
  let timeBlock = TimeBlock.MORNING

  // 解析时间 HH:MM 或 H:MM
  const timeMatch = text.match(/(\d{1,2})[:：](\d{1,2})/)
  if (timeMatch) {
    hour = parseInt(timeMatch[1])
    minute = parseInt(timeMatch[2])
  } else {
    // 解析 "X点" 或 "X点半"
    const hourMatch = text.match(/(\d{1,2})\s*点/)
    if (hourMatch) {
      hour = parseInt(hourMatch[1])
      if (text.includes('半点')) {
        minute = 30
      }
    }
  }

  // 上午/下午/晚上 修正
  if (text.includes('晚上') || text.includes('夜间')) {
    if (hour >= 1 && hour <= 6) hour += 12
    timeBlock = TimeBlock.EVENING
  } else if (text.includes('下午')) {
    if (hour >= 1 && hour <= 6) hour += 12
    timeBlock = TimeBlock.AFTERNOON
  } else if (text.includes('中午')) {
    hour = 12
    minute = 0
    timeBlock = TimeBlock.AFTERNOON
  } else if (text.includes('上午') || text.includes('早上')) {
    timeBlock = TimeBlock.MORNING
  } else if (text.includes('凌晨') || text.includes('黎明')) {
    timeBlock = TimeBlock.DAWN
  } else if (hour >= 18 && hour <= 23) {
    timeBlock = TimeBlock.EVENING
  } else if (hour >= 12 && hour < 18) {
    timeBlock = TimeBlock.AFTERNOON
  } else if (hour >= 6 && hour < 12) {
    timeBlock = TimeBlock.MORNING
  } else if (hour >= 0 && hour < 6) {
    timeBlock = TimeBlock.NIGHT
  }

  const result: ParsedTimeResult = { hour, minute, timeBlock }
  return result
}

function parseDurationFromText(text: string, defaultMinutes: number): number {
  // X分钟
  const minMatch = text.match(/(\d+)\s*分钟?/)
  if (minMatch) {
    const val = parseInt(minMatch[1])
    if (val > 0 && val < 1440) return val
  }

  // X小时
  const hourMatch = text.match(/(\d+)(?:\s*个)?\s*小时?/)
  if (hourMatch) {
    const val = parseInt(hourMatch[1])
    if (val > 0 && val < 24) return val * 60
  }

  // 半小时
  if (text.includes('半小时')) {
    return 30
  }

  // 一刻钟
  if (text.includes('一刻钟') || text.includes('一刻')) {
    return 15
  }

  return defaultMinutes
}

function inferTypeAndIntensity(text: string): TaskTypeIntensity {
  if (text.includes('运动') || text.includes('跑步') || text.includes('健身') || text.includes('瑜伽')
    || text.includes('游泳') || text.includes('打球') || text.includes('骑行')) {
    const r1: TaskTypeIntensity = { type: TaskType.EXERCISE, intensity: TaskIntensity.HIGH }
    return r1
  }

  if (text.includes('开会') || text.includes('会议') || text.includes('讨论') || text.includes('工作')
    || text.includes('项目') || text.includes('报告') || text.includes('答辩') || text.includes('面试')) {
    const r2: TaskTypeIntensity = { type: TaskType.THINK, intensity: TaskIntensity.HIGH }
    return r2
  }

  if (text.includes('学习') || text.includes('复习') || text.includes('备考') || text.includes('读书')
    || text.includes('阅读') || text.includes('写作业') || text.includes('做题')) {
    const r3: TaskTypeIntensity = { type: TaskType.THINK, intensity: TaskIntensity.MEDIUM }
    return r3
  }

  if (text.includes('吃饭') || text.includes('早餐') || text.includes('午餐') || text.includes('晚餐')
    || text.includes('做饭') || text.includes('买菜')) {
    const r4: TaskTypeIntensity = { type: TaskType.HOME, intensity: TaskIntensity.LOW }
    return r4
  }

  if (text.includes('休息') || text.includes('睡觉') || text.includes('午睡') || text.includes('放松')
    || text.includes('冥想') || text.includes('打盹')) {
    const r5: TaskTypeIntensity = { type: TaskType.REST, intensity: TaskIntensity.LOW }
    return r5
  }

  if (text.includes('社交') || text.includes('聚会') || text.includes('见面') || text.includes('朋友')
    || text.includes('约会') || text.includes('聚餐') || text.includes('聊天')) {
    const r6: TaskTypeIntensity = { type: TaskType.SOCIAL, intensity: TaskIntensity.MEDIUM }
    return r6
  }

  const r7: TaskTypeIntensity = { type: TaskType.THINK, intensity: TaskIntensity.MEDIUM }
  return r7
}

function cleanTitle(text: string): string {
  let cleaned = text
    .replace(/今天|明天|后天|大后天/g, '')
    .replace(/(\d+)\s*天后/g, '')
    .replace(/(\d+)\s*周后/g, '')
    .replace(/本周[一二三四五六日天]|下周[一二三四五六日天]/g, '')
    .replace(/星期[一二三四五六日天]/g, '')
    .replace(/周[一二三四五六日天]/g, '')
    .replace(/上午|下午|晚上|早上|中午|凌晨|黎明|夜间/g, '')
    .replace(/(\d{1,2})[:：](\d{1,2})/g, '')
    .replace(/(\d{1,2})\s*点/g, '')
    .replace(/(\d{1,2})月(\d{1,2})[日号]/g, '')
    .replace(/(\d{1,2})[\/-](\d{1,2})/g, '')
    .replace(/(\d+)(?:\s*个)?\s*小时?/g, '')
    .replace(/(\d+)\s*分钟?/g, '')
    .replace(/半小时|一刻钟|一刻/g, '')
    .replace(/[\s,，]+/g, ' ')
    .trim()

  return cleaned || '新日程'
}

export function parseScheduleText(text: string): ParsedSchedule {
  const result = new ParsedSchedule()
  result.title = text
  result.date = parseDateFromText(text)

  const parsedTime = parseTimeFromText(text)
  const hour = parsedTime.hour
  const minute = parsedTime.minute
  const timeBlock = parsedTime.timeBlock
  result.startTime = `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`
  result.timeBlock = timeBlock

  result.durationMinutes = parseDurationFromText(text, 60)
  const endMinutes = hour * 60 + minute + result.durationMinutes
  const endH = Math.floor(endMinutes / 60) % 24
  const endM = endMinutes % 60
  result.endTime = `${String(endH).padStart(2, '0')}:${String(endM).padStart(2, '0')}`

  // 处理跨天
  if (endMinutes >= 1440) {
    const daysToAdd = Math.floor(endMinutes / 1440)
    result.date = addDays(result.date, daysToAdd)
  }

  const inferred = inferTypeAndIntensity(text)
  result.type = inferred.type
  result.intensity = inferred.intensity

  result.title = cleanTitle(text)

  return result
}

export function createTaskFromParsed(parsed: ParsedSchedule): Task {
  const task = new Task(parsed.title, parsed.date, parsed.startTime, parsed.endTime)
  task.type = parsed.type
  task.intensity = parsed.intensity
  task.timeBlock = parsed.timeBlock
  task.notes = parsed.notes
  task.duration = parsed.durationMinutes
  task.source = 'voice'
  return task
}

export function setSystemReminder(task: Task): boolean {
  // 原子化服务(atomicService)不支持 reminderAgentManager
  // 如需系统提醒，需将应用改为普通应用(bundleType: app)
  return false
}
