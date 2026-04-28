import { Task } from '../models/DataModels'

/**
 * 将 HH:MM 格式时间转换为从 00:00 开始的分钟数
 */
export function timeToMinutes(timeStr: string): number {
  if (!timeStr || !timeStr.includes(':')) return 0
  const parts = timeStr.split(':')
  const h = Number(parts[0])
  const m = Number(parts[1])
  if (isNaN(h) || isNaN(m)) return 0
  return h * 60 + m
}

/**
 * 将分钟数转换为 HH:MM 格式
 */
export function minutesToTime(minutes: number): string {
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`
}

/**
 * 获取当前时间的分钟数（从 00:00 开始）
 */
export function getCurrentMinutes(): number {
  const now = new Date()
  return now.getHours() * 60 + now.getMinutes()
}

/**
 * 判断给定日期是否是今天
 */
export function isToday(dateStr: string): boolean {
  const now = new Date()
  const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
  return dateStr === todayStr
}

/**
 * 任务时间状态信息 —— 用于时间轴显示
 */
export class TaskTimeInfo {
  isOngoing: boolean = false
  isEnded: boolean = false
  isUpcoming: boolean = false
  minutesToStart: number = 0
  minutesToEnd: number = 0
  progressPercent: number = 0
  relativeLabel: string = ''
}

/**
 * 获取任务相对于"现在"的时间信息
 */
export function getTaskTimeInfo(taskDate: string, startTime: string, endTime: string): TaskTimeInfo {
  const result = new TaskTimeInfo()

  if (!isToday(taskDate)) {
    const taskD = new Date(taskDate + 'T00:00:00')
    const now = new Date()
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    if (taskD < todayStart) {
      result.isEnded = true
      result.progressPercent = 100
      result.relativeLabel = '已结束'
    } else {
      result.isUpcoming = true
      result.relativeLabel = `${startTime || '??:??'} 开始`
    }
    return result
  }

  const startMins = timeToMinutes(startTime)
  const endMins = timeToMinutes(endTime)
  const currentMins = getCurrentMinutes()

  // 未开始
  if (currentMins < startMins) {
    const minsToStart = startMins - currentMins
    result.isUpcoming = true
    result.minutesToStart = minsToStart
    result.relativeLabel = `${minsToStart} 分钟后开始`
    return result
  }

  // 进行中
  if (currentMins >= startMins && currentMins < endMins) {
    const minsToEnd = endMins - currentMins
    const totalDuration = endMins - startMins
    const progress = totalDuration > 0 ? Math.round(((currentMins - startMins) / totalDuration) * 100) : 0
    result.isOngoing = true
    result.minutesToEnd = minsToEnd
    result.progressPercent = progress
    result.relativeLabel = `还有 ${minsToEnd} 分钟结束`
    return result
  }

  // 已结束
  result.isEnded = true
  result.progressPercent = 100
  result.relativeLabel = '已结束'
  return result
}

/**
 * 格式化分钟数为易读形式
 * 如 65 → "1小时5分钟"
 */
export function formatDuration(minutes: number): string {
  if (minutes <= 0) return '0分钟'
  const h = Math.floor(minutes / 60)
  const m = minutes % 60
  if (h > 0 && m > 0) return `${h}小时${m}分钟`
  if (h > 0) return `${h}小时`
  return `${m}分钟`
}

/**
 * 时间轴显示范围
 */
export class DayTimeRange {
  startHour: number
  endHour: number

  constructor(startHour: number, endHour: number) {
    this.startHour = startHour
    this.endHour = endHour
  }
}

/**
 * 根据任务列表计算合适的时间轴显示范围
 * 返回 DayTimeRange，确保覆盖所有任务并留有余量
 */
export function getDayTimeRange(tasks: Task[]): DayTimeRange {
  let minHour = 6   // 默认早上6点
  let maxHour = 23  // 默认晚上11点

  for (let i = 0; i < tasks.length; i++) {
    const task = tasks[i]
    if (task.startTime) {
      const h = parseInt(task.startTime.split(':')[0])
      if (!isNaN(h) && h < minHour) minHour = h
    }
    if (task.endTime) {
      const h = parseInt(task.endTime.split(':')[0])
      if (!isNaN(h) && h >= maxHour) maxHour = h + 1
    }
  }

  // 确保范围合理
  if (minHour < 0) minHour = 0
  if (maxHour > 24) maxHour = 24
  if (minHour >= maxHour) {
    minHour = 6
    maxHour = 23
  }

  // 添加 1 小时上下边距
  if (minHour > 0) minHour -= 1
  if (maxHour < 24) maxHour += 1

  return new DayTimeRange(minHour, maxHour)
}

/**
 * 过渡预警信息
 */
export class TransitionInfo {
  isWarning: boolean = false   // 10-6 分钟，预警期
  isUrgent: boolean = false    // 5-0 分钟，紧急期
  minutesToEnd: number = 0
}

/**
 * 获取当前任务的过渡预警状态
 */
export function getTransitionInfo(currentTask: Task): TransitionInfo {
  const result = new TransitionInfo()

  if (!isToday(currentTask.date) || !currentTask.startTime || !currentTask.endTime) {
    return result
  }

  const startMins = timeToMinutes(currentTask.startTime)
  const endMins = timeToMinutes(currentTask.endTime)
  const currentMins = getCurrentMinutes()

  // 只有进行中的任务才需要过渡预警
  if (currentMins < startMins || currentMins >= endMins) {
    return result
  }

  const minsToEnd = endMins - currentMins
  result.minutesToEnd = minsToEnd

  if (minsToEnd <= 5) {
    result.isUrgent = true
  } else if (minsToEnd <= 10) {
    result.isWarning = true
  }

  return result
}
