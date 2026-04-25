import { Task, TaskType, TaskIntensity, TimeBlock } from '../models/DataModels'
import { dataStore } from '../models/DataStore'

export class CourseItem {
  name: string
  teacher: string
  location: string
  weekday: number
  startTime: string
  endTime: string
  weekStart: number
  weekEnd: number

  constructor() {
    this.name = ''
    this.teacher = ''
    this.location = ''
    this.weekday = 1
    this.startTime = '08:00'
    this.endTime = '09:35'
    this.weekStart = 1
    this.weekEnd = 16
  }
}

export function parseCourseCSV(content: string): CourseItem[] {
  const items: CourseItem[] = []
  const lines = content.split('\n')
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim()
    if (!line || i === 0) {
      continue
    }
    const parts = line.split(',')
    if (parts.length < 6) {
      continue
    }
    const item = new CourseItem()
    item.name = parts[0].trim()
    item.teacher = parts[1].trim()
    item.location = parts[2].trim()
    item.weekday = parseInt(parts[3].trim()) || 1
    item.startTime = parts[4].trim()
    item.endTime = parts[5].trim()
    if (parts.length > 6) {
      item.weekStart = parseInt(parts[6].trim()) || 1
    }
    if (parts.length > 7) {
      item.weekEnd = parseInt(parts[7].trim()) || 16
    }
    items.push(item)
  }
  return items
}

export function generateTasksFromCourses(courses: CourseItem[], baseDate: string): number {
  let count = 0
  const base = new Date(baseDate)
  for (let i = 0; i < courses.length; i++) {
    const c = courses[i]
    const dayOffset = c.weekday - 1
    const courseDate = new Date(base)
    courseDate.setDate(base.getDate() + dayOffset)
    const dateStr = formatDate(courseDate)

    const task = new Task(c.name, dateStr, c.startTime, c.endTime)
    task.notes = `教师：${c.teacher}  地点：${c.location}`
    task.type = inferCourseType(c.name)
    task.intensity = TaskIntensity.MEDIUM
    task.timeBlock = inferTimeBlockFromHour(parseInt(c.startTime.split(':')[0]))
    dataStore.addTask(task)
    count = count + 1
  }
  return count
}

function formatDate(d: Date): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

function inferCourseType(name: string): TaskType {
  if (name.includes('体育') || name.includes('运动')) {
    return TaskType.EXERCISE
  }
  if (name.includes('休息') || name.includes('自习')) {
    return TaskType.REST
  }
  return TaskType.THINK
}

function inferTimeBlockFromHour(h: number): TimeBlock {
  if (h < 6) return TimeBlock.DAWN
  if (h < 12) return TimeBlock.MORNING
  if (h < 14) return TimeBlock.AFTERNOON
  if (h < 18) return TimeBlock.AFTERNOON
  if (h < 22) return TimeBlock.EVENING
  return TimeBlock.NIGHT
}
