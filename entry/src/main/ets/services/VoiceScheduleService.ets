import { Task, TaskType, TaskIntensity, TimeBlock } from '../models/DataModels'

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

function todayStr(): string {
  const d = new Date()
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

function tomorrowStr(): string {
  const d = new Date()
  d.setDate(d.getDate() + 1)
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

function dayAfterTomorrowStr(): string {
  const d = new Date()
  d.setDate(d.getDate() + 2)
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

export function parseScheduleText(text: string): ParsedSchedule {
  const result = new ParsedSchedule()
  result.title = text
  result.date = todayStr()
  result.startTime = '09:00'
  result.endTime = '10:00'
  result.durationMinutes = 60
  result.type = TaskType.THINK
  result.intensity = TaskIntensity.MEDIUM
  result.timeBlock = TimeBlock.MORNING

  // 解析日期
  if (text.includes('后天')) {
    result.date = dayAfterTomorrowStr()
  } else if (text.includes('明天')) {
    result.date = tomorrowStr()
  }

  // 解析时间
  let hour = 9
  let minute = 0
  const timeMatch = text.match(/(\d{1,2})[点:：](\d{0,2})/)
  if (timeMatch) {
    hour = parseInt(timeMatch[1])
    minute = timeMatch[2] ? parseInt(timeMatch[2]) : 0
  }

  // 上午/下午/晚上
  if (text.includes('晚上')) {
    if (hour >= 1 && hour <= 6) hour += 12
    result.timeBlock = TimeBlock.EVENING
  } else if (text.includes('下午')) {
    if (hour >= 1 && hour <= 6) hour += 12
    result.timeBlock = TimeBlock.AFTERNOON
  } else if (text.includes('中午')) {
    hour = 12
    minute = 0
    result.timeBlock = TimeBlock.AFTERNOON
  } else if (text.includes('上午') || text.includes('早上')) {
    result.timeBlock = TimeBlock.MORNING
  }

  result.startTime = `${String(hour).padStart(2, '0')}:${String(minute).padStart(2, '0')}`
  const endMinutes = hour * 60 + minute + result.durationMinutes
  const endH = Math.floor(endMinutes / 60) % 24
  const endM = endMinutes % 60
  result.endTime = `${String(endH).padStart(2, '0')}:${String(endM).padStart(2, '0')}`

  // 处理跨天
  if (endMinutes >= 1440) {
    const daysToAdd = Math.floor(endMinutes / 1440)
    const parts = result.date.split('-').map(Number)
    const newDate = new Date(parts[0], parts[1] - 1, parts[2])
    newDate.setDate(newDate.getDate() + daysToAdd)
    result.date = `${newDate.getFullYear()}-${String(newDate.getMonth() + 1).padStart(2, '0')}-${String(newDate.getDate()).padStart(2, '0')}`
  }

  // 推断类型
  if (text.includes('运动') || text.includes('跑步') || text.includes('健身') || text.includes('瑜伽')) {
    result.type = TaskType.EXERCISE
    result.intensity = TaskIntensity.HIGH
  } else if (text.includes('开会') || text.includes('会议') || text.includes('讨论') || text.includes('工作')) {
    result.type = TaskType.THINK
    result.intensity = TaskIntensity.HIGH
  } else if (text.includes('吃饭') || text.includes('早餐') || text.includes('午餐') || text.includes('晚餐')) {
    result.type = TaskType.HOME
    result.intensity = TaskIntensity.LOW
  } else if (text.includes('休息') || text.includes('睡觉') || text.includes('午睡') || text.includes('放松')) {
    result.type = TaskType.REST
    result.intensity = TaskIntensity.LOW
  } else if (text.includes('社交') || text.includes('聚会') || text.includes('见面') || text.includes('朋友')) {
    result.type = TaskType.SOCIAL
    result.intensity = TaskIntensity.MEDIUM
  }

  // 清理标题
  result.title = text
    .replace(/明天|后天|今天/g, '')
    .replace(/上午|下午|晚上|早上|中午/g, '')
    .replace(/\d{1,2}[点:：]\d{0,2}/g, '')
    .trim()

  if (!result.title) {
    result.title = '新日程'
  }

  return result
}

export function createTaskFromParsed(parsed: ParsedSchedule): Task {
  const task = new Task(parsed.title, parsed.date, parsed.startTime, parsed.endTime)
  task.type = parsed.type
  task.intensity = parsed.intensity
  task.timeBlock = parsed.timeBlock
  task.notes = parsed.notes
  task.source = 'voice'
  return task
}

export function setSystemReminder(task: Task): boolean {
  // 原子化服务(atomicService)不支持 reminderAgentManager
  // 如需系统提醒，需将应用改为普通应用(bundleType: app)
  return false
}
