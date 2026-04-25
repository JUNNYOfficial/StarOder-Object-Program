import { Task, TaskType, TaskIntensity, TimeBlock, TaskStatus } from '../models/DataModels'

export interface IcsEvent {
  summary: string
  startDate: Date
  endDate: Date
  description: string
  location: string
  isAllDay: boolean
}

export function parseIcsText(icsText: string): IcsEvent[] {
  const events: IcsEvent[] = []
  const lines = icsText.replace(/\r\n/g, '\n').replace(/\r/g, '\n').split('\n')

  let i = 0
  while (i < lines.length) {
    // 找到 VEVENT 开始
    if (lines[i].trim() === 'BEGIN:VEVENT') {
      const veventLines: string[] = []
      i++
      while (i < lines.length && lines[i].trim() !== 'END:VEVENT') {
        // 处理折叠行（以空格开头的行是上一行的续行）
        if (lines[i].startsWith(' ') || lines[i].startsWith('\t')) {
          if (veventLines.length > 0) {
            veventLines[veventLines.length - 1] += lines[i].substring(1)
          }
        } else {
          veventLines.push(lines[i])
        }
        i++
      }
      const event = parseVevent(veventLines)
      if (event) {
        events.push(event)
      }
    }
    i++
  }

  return events
}

function parseVevent(lines: string[]): IcsEvent | null {
  let summary = ''
  let dtStart = ''
  let dtEnd = ''
  let description = ''
  let location = ''
  let isAllDay = false

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]
    if (line.startsWith('SUMMARY:')) {
      summary = decodeIcsValue(line.substring(8))
    } else if (line.startsWith('SUMMARY;')) {
      const idx = line.indexOf(':')
      if (idx > 0) {
        summary = decodeIcsValue(line.substring(idx + 1))
      }
    } else if (line.startsWith('DTSTART;VALUE=DATE:')) {
      dtStart = line.substring(19)
      isAllDay = true
    } else if (line.startsWith('DTSTART:')) {
      dtStart = line.substring(8)
      isAllDay = dtStart.length === 8
    } else if (line.startsWith('DTEND;VALUE=DATE:')) {
      dtEnd = line.substring(18)
    } else if (line.startsWith('DTEND:')) {
      dtEnd = line.substring(6)
    } else if (line.startsWith('DESCRIPTION:')) {
      description = decodeIcsValue(line.substring(12))
    } else if (line.startsWith('DESCRIPTION;')) {
      const idx = line.indexOf(':')
      if (idx > 0) {
        description = decodeIcsValue(line.substring(idx + 1))
      }
    } else if (line.startsWith('LOCATION:')) {
      location = decodeIcsValue(line.substring(9))
    }
  }

  if (!summary && !dtStart) {
    return null
  }

  const startDate = parseIcsDateTime(dtStart, isAllDay)
  let endDate = parseIcsDateTime(dtEnd, isAllDay)

  // 如果没有结束时间，默认开始时间后1小时
  if (!dtEnd && startDate) {
    endDate = new Date(startDate.getTime() + 60 * 60 * 1000)
  }

  if (!startDate) {
    return null
  }

  return {
    summary: summary || '未命名日程',
    startDate,
    endDate: endDate || startDate,
    description,
    location,
    isAllDay
  }
}

function parseIcsDateTime(value: string, isAllDay: boolean): Date | null {
  if (!value) return null

  value = value.trim()

  // 全天事件: 20240425
  if (isAllDay && value.length === 8) {
    const y = parseInt(value.substring(0, 4))
    const m = parseInt(value.substring(4, 6)) - 1
    const d = parseInt(value.substring(6, 8))
    return new Date(y, m, d, 9, 0, 0) // 全天事件默认9点开始
  }

  // 带时间: 20240425T100000Z 或 20240425T100000
  if (value.length >= 15) {
    const y = parseInt(value.substring(0, 4))
    const m = parseInt(value.substring(4, 6)) - 1
    const d = parseInt(value.substring(6, 8))
    const h = parseInt(value.substring(9, 11))
    const min = parseInt(value.substring(11, 13))
    const s = parseInt(value.substring(13, 15))

    if (value.endsWith('Z')) {
      // UTC 时间，转为本地时间
      const utcDate = new Date(Date.UTC(y, m, d, h, min, s))
      return new Date(utcDate.getTime())
    }
    return new Date(y, m, d, h, min, s)
  }

  return null
}

function decodeIcsValue(value: string): string {
  if (!value) return ''
  // 处理 ICS 编码: \, \; \n \\ 等
  return value
    .replace(/\\n/g, '\n')
    .replace(/\\,/g, ',')
    .replace(/\\;/g, ';')
    .replace(/\\\\/g, '\\')
}

export function icsEventsToTasks(events: IcsEvent[]): Task[] {
  const tasks: Task[] = []
  for (let i = 0; i < events.length; i++) {
    const e = events[i]
    const dateStr = formatDate(e.startDate)
    const startTimeStr = e.isAllDay ? '' : formatTime(e.startDate)
    const endTimeStr = e.isAllDay ? '' : formatTime(e.endDate)

    const task = new Task(e.summary, dateStr, startTimeStr, endTimeStr)
    const notes: string[] = []
    if (e.location) notes.push(`地点: ${e.location}`)
    if (e.description) notes.push(e.description)
    task.notes = notes.join('\n')
    task.source = 'feishu'
    task.status = TaskStatus.TODO
    task.type = TaskType.THINK
    task.intensity = TaskIntensity.MEDIUM
    task.timeBlock = inferTimeBlock(e.startDate.getHours())
    tasks.push(task)
  }
  return tasks
}

function formatDate(d: Date): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

function formatTime(d: Date): string {
  const h = String(d.getHours()).padStart(2, '0')
  const m = String(d.getMinutes()).padStart(2, '0')
  return `${h}:${m}`
}

function inferTimeBlock(hour: number): TimeBlock {
  if (hour < 6) return TimeBlock.DAWN
  if (hour < 12) return TimeBlock.MORNING
  if (hour < 14) return TimeBlock.AFTERNOON
  if (hour < 18) return TimeBlock.AFTERNOON
  if (hour < 22) return TimeBlock.EVENING
  return TimeBlock.NIGHT
}
