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

// ===== 本地 Agent：智能课表文本解析器 =====
// 支持 CSV、空格分隔、键值对、表格复制等多种格式
export class CourseAgent {
  static parse(content: string): CourseItem[] {
    if (!content || !content.trim()) {
      return []
    }
    const trimmed = content.trim()

    // 策略1：如果包含大量逗号，尝试 CSV
    if (trimmed.includes(',')) {
      const csvResult = parseCourseCSV(trimmed)
      if (csvResult.length > 0) {
        return csvResult
      }
    }

    // 策略2：如果包含制表符，尝试表格解析
    if (trimmed.includes('\t')) {
      const tabResult = parseCourseTab(trimmed)
      if (tabResult.length > 0) {
        return tabResult
      }
    }

    // 策略3：智能逐行解析（最通用）
    return parseSmartLines(trimmed)
  }

  static getFormatHint(): string {
    return '支持多种格式：\n' +
      '1. CSV：课程名,教师,地点,星期,开始时间,结束时间\n' +
      '2. 自然文本：高等数学 周一 08:00-09:35 教学楼A301 张老师 第1-16周\n' +
      '3. 表格复制：直接从教务系统/Excel 复制粘贴'
  }
}

// CSV 解析
function parseCourseCSV(content: string): CourseItem[] {
  const items: CourseItem[] = []
  const lines = content.split('\n')
  let headerSkipped = false
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim()
    if (!line) {
      continue
    }
    // 跳过表头行（包含"课程""名称""教师"等关键词）
    if (!headerSkipped && isHeaderLine(line)) {
      headerSkipped = true
      continue
    }
    const parts = line.split(',')
    if (parts.length < 4) {
      continue
    }
    const item = buildFromParts(parts)
    if (item && item.name) {
      items.push(item)
    }
  }
  return items
}

// 制表符分隔解析（从 Excel/网页表格复制）
function parseCourseTab(content: string): CourseItem[] {
  const items: CourseItem[] = []
  const lines = content.split('\n')
  let headerSkipped = false
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim()
    if (!line) {
      continue
    }
    if (!headerSkipped && isHeaderLine(line)) {
      headerSkipped = true
      continue
    }
    const parts = line.split('\t')
    if (parts.length < 4) {
      continue
    }
    const item = buildFromParts(parts)
    if (item && item.name) {
      items.push(item)
    }
  }
  return items
}

// 判断是否为表头行
function isHeaderLine(line: string): boolean {
  const headerKeywords = ['课程', '名称', '教师', '老师', '地点', '教室', '星期', '时间', '周次']
  let hit = 0
  for (let i = 0; i < headerKeywords.length; i++) {
    if (line.includes(headerKeywords[i])) {
      hit++
    }
  }
  return hit >= 2
}

// 从字段数组构建 CourseItem，自动识别各字段含义
function buildFromParts(parts: string[]): CourseItem | null {
  const item = new CourseItem()
  let nameSet = false

  for (let i = 0; i < parts.length; i++) {
    const raw = parts[i].trim()
    if (!raw) {
      continue
    }

    // 尝试提取时间
    const timeInfo = extractTime(raw)
    if (timeInfo) {
      item.startTime = timeInfo.start
      item.endTime = timeInfo.end
      continue
    }

    // 尝试提取星期
    const wd = extractWeekday(raw)
    if (wd > 0) {
      item.weekday = wd
      continue
    }

    // 尝试提取周次范围
    const weekRange = extractWeekRange(raw)
    if (weekRange) {
      item.weekStart = weekRange.start
      item.weekEnd = weekRange.end
      continue
    }

    // 尝试识别教师
    if (isTeacherField(raw)) {
      item.teacher = cleanTeacherName(raw)
      continue
    }

    // 尝试识别地点
    if (isLocationField(raw)) {
      item.location = raw
      continue
    }

    // 第一个未被识别的非数字短文本作为课程名
    if (!nameSet && raw.length >= 2 && !isPureNumber(raw)) {
      item.name = raw
      nameSet = true
      continue
    }

    // 如果课程名已设置，额外的文本可能是补充信息
    if (nameSet && raw.length >= 2) {
      if (!item.teacher && isTeacherField(raw)) {
        item.teacher = cleanTeacherName(raw)
      } else if (!item.location && isLocationField(raw)) {
        item.location = raw
      }
    }
  }

  return item.name ? item : null
}

// 智能逐行解析（处理自然语言风格的课表文本）
function parseSmartLines(content: string): CourseItem[] {
  const items: CourseItem[] = []
  const lines = content.split('\n')
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim()
    if (!line || line.length < 3) {
      continue
    }
    if (isHeaderLine(line)) {
      continue
    }

    const item = parseSmartLine(line)
    if (item && item.name) {
      items.push(item)
    }
  }
  return items
}

// 解析单行自然文本
function parseSmartLine(line: string): CourseItem | null {
  const item = new CourseItem()

  // 先提取时间（最明确的特征）
  const timeInfo = extractTime(line)
  if (timeInfo) {
    item.startTime = timeInfo.start
    item.endTime = timeInfo.end
    // 把时间部分替换掉，方便后续解析
    line = line.replace(timeInfo.matched, ' ')
  }

  // 提取星期
  const wd = extractWeekday(line)
  if (wd > 0) {
    item.weekday = wd
    line = line.replace(getWeekdayPatternMatch(line), ' ')
  }

  // 提取周次
  const weekRange = extractWeekRange(line)
  if (weekRange) {
    item.weekStart = weekRange.start
    item.weekEnd = weekRange.end
    line = line.replace(weekRange.matched, ' ')
  }

  // 用空格分割剩余文本
  const tokens = line.split(/\s+/).filter(t => t.length > 0)

  // 识别教师（优先：包含"老师""教授"等后缀，或2-4字中文人名）
  for (let i = 0; i < tokens.length; i++) {
    const t = tokens[i]
    if (isTeacherField(t)) {
      item.teacher = cleanTeacherName(t)
      tokens[i] = ''
      break
    }
  }

  // 识别地点
  for (let i = 0; i < tokens.length; i++) {
    const t = tokens[i]
    if (t && isLocationField(t)) {
      item.location = t
      tokens[i] = ''
      break
    }
  }

  // 剩余最长的token作为课程名
  let bestName = ''
  for (let i = 0; i < tokens.length; i++) {
    const t = tokens[i]
    if (t && t.length > bestName.length && !isPureNumber(t)) {
      bestName = t
    }
  }
  item.name = bestName

  return item.name ? item : null
}

// ===== 字段提取工具函数 =====

class TimeInfo {
  start: string
  end: string
  matched: string
  constructor(start: string, end: string, matched: string) {
    this.start = start
    this.end = end
    this.matched = matched
  }
}

class WeekRangeInfo {
  start: number
  end: number
  matched: string
  constructor(start: number, end: number, matched: string) {
    this.start = start
    this.end = end
    this.matched = matched
  }
}

function extractTime(text: string): TimeInfo | null {
  // 匹配 08:00-09:35 或 8:00~9:35 或 8:00至9:35
  const pattern = /(\d{1,2}):(\d{2})\s*[-~至到]\s*(\d{1,2}):(\d{2})/
  const m = text.match(pattern)
  if (m) {
    const startH = m[1].padStart(2, '0')
    const startM = m[2].padStart(2, '0')
    const endH = m[3].padStart(2, '0')
    const endM = m[4].padStart(2, '0')
    return new TimeInfo(`${startH}:${startM}`, `${endH}:${endM}`, m[0])
  }
  return null
}

function extractWeekday(text: string): number {
  const map: Record<string, number> = {
    '一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7, '天': 7,
    '1': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7
  }
  // 周[一二三四五六日1234567] 或 星期[一二三四五六日1234567] 或 周[ ]?[1234567]
  const pattern = /周[\s]?([一二三四五六日天1234567])/
  const m = text.match(pattern)
  if (m) {
    return map[m[1]] || 1
  }
  return 0
}

function getWeekdayPatternMatch(text: string): string {
  const pattern = /周[\s]?[一二三四五六日天1234567]/
  const m = text.match(pattern)
  return m ? m[0] : ''
}

function extractWeekRange(text: string): WeekRangeInfo | null {
  // 第1-16周 或 1-16周 或 第1~16周
  const pattern = /第?\s*(\d+)\s*[-~至]\s*(\d+)\s*周/
  const m = text.match(pattern)
  if (m) {
    return new WeekRangeInfo(parseInt(m[1]) || 1, parseInt(m[2]) || 16, m[0])
  }
  return null
}

function isTeacherField(text: string): boolean {
  if (text.includes('老师') || text.includes('教师') || text.includes('教授') || text.includes('讲师')) {
    return true
  }
  // 2-4字中文人名（简单判断：纯中文且2-4字）
  if (/^[\u4e00-\u9fa5]{2,4}$/.test(text)) {
    return true
  }
  return false
}

function cleanTeacherName(text: string): string {
  return text.replace(/老师|教师|教授|讲师/g, '')
}

function isLocationField(text: string): boolean {
  const locKeywords = ['教学楼', '教室', '实验室', '机房', '楼', '室', '馆', '堂', '场', '栋', '阁', '厅']
  for (let i = 0; i < locKeywords.length; i++) {
    if (text.includes(locKeywords[i])) {
      return true
    }
  }
  // 英文+数字组合，如 A301, B205
  if (/^[A-Za-z]\d{2,4}$/.test(text)) {
    return true
  }
  return false
}

function isPureNumber(text: string): boolean {
  return /^\d+$/.test(text)
}

// ===== 生成日程任务 =====

export async function generateTasksFromCourses(courses: CourseItem[], baseDate: string): Promise<number> {
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
    await dataStore.addTask(task)
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
