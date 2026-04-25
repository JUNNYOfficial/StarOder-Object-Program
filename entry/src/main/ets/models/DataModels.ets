// ===== 枚举类型 =====
export enum TaskIntensity {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH'
}

export enum TimeBlock {
  DAWN = 'DAWN',
  MORNING = 'MORNING',
  AFTERNOON = 'AFTERNOON',
  EVENING = 'EVENING',
  NIGHT = 'NIGHT'
}

export enum TaskType {
  THINK = 'THINK',
  SOCIAL = 'SOCIAL',
  HOME = 'HOME',
  REST = 'REST',
  EXERCISE = 'EXERCISE'
}

export enum Priority {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH'
}

export enum RepeatMode {
  NONE = 'NONE',
  DAILY = 'DAILY',
  WEEKLY = 'WEEKLY',
  MONTHLY = 'MONTHLY',
  YEARLY = 'YEARLY'
}

// 渐进式完成五态机
export enum TaskStatus {
  TODO = 'TODO',
  STARTED = 'STARTED',
  MOSTLY = 'MOSTLY',
  DONE = 'DONE',
  PAUSED = 'PAUSED'
}

export enum FocusMode {
  MINI = 'MINI',
  NORMAL = 'NORMAL',
  ESTIMATE = 'ESTIMATE',
  BODY = 'BODY'
}

// ===== 核心数据类 =====

export class SubTask {
  id: string
  title: string
  completed: boolean
  parentTaskId: string

  constructor(title: string, parentTaskId: string = '') {
    this.id = Date.now().toString() + Math.random().toString(36).slice(2, 8)
    this.title = title
    this.completed = false
    this.parentTaskId = parentTaskId
  }
}

export class Task {
  id: string
  title: string
  type: TaskType
  intensity: TaskIntensity
  timeBlock: TimeBlock
  date: string // YYYY-MM-DD
  startTime: string // HH:MM
  endTime: string // HH:MM
  duration: number // minutes
  status: TaskStatus
  priority: Priority
  repeatMode: RepeatMode
  notes: string
  prepareItems: string[]
  subTasks: SubTask[]
  pinned: boolean
  deleted: boolean
  deletedAt: number // timestamp, 0 if not deleted
  createdAt: number
  updatedAt: number
  source: string // 'manual' | 'feishu' | etc
  externalId: string // external system id, e.g. feishu event id

  constructor(title: string, date: string, startTime: string, endTime: string) {
    this.id = Date.now().toString() + Math.random().toString(36).slice(2, 8)
    this.title = title
    this.type = TaskType.HOME
    this.intensity = TaskIntensity.MEDIUM
    this.timeBlock = TimeBlock.MORNING
    this.date = date
    this.startTime = startTime
    this.endTime = endTime
    this.duration = 0
    this.status = TaskStatus.TODO
    this.priority = Priority.MEDIUM
    this.repeatMode = RepeatMode.NONE
    this.notes = ''
    this.prepareItems = []
    this.subTasks = []
    this.pinned = false
    this.deleted = false
    this.deletedAt = 0
    this.createdAt = Date.now()
    this.updatedAt = Date.now()
    this.source = 'manual'
    this.externalId = ''
  }
}

export class EnergyRecord {
  id: string
  date: string
  rating: number // 1-5
  note: string

  constructor(date: string, rating: number) {
    this.id = Date.now().toString() + Math.random().toString(36).slice(2, 8)
    this.date = date
    this.rating = rating
    this.note = ''
  }
}

export class MoodSurveyRecord {
  id: string
  date: string
  time: string
  mood: number // 1-5
  trigger: string
  context: string
  note: string

  constructor(date: string, time: string, mood: number) {
    this.id = Date.now().toString() + Math.random().toString(36).slice(2, 8)
    this.date = date
    this.time = time
    this.mood = mood
    this.trigger = ''
    this.context = ''
    this.note = ''
  }
}

export class FocusRecord {
  id: string
  taskId: string
  mode: FocusMode
  plannedMinutes: number
  actualMinutes: number
  startTime: string
  endTime: string
  interrupted: boolean
  completed: boolean

  constructor(taskId: string, mode: FocusMode, plannedMinutes: number) {
    this.id = Date.now().toString() + Math.random().toString(36).slice(2, 8)
    this.taskId = taskId
    this.mode = mode
    this.plannedMinutes = plannedMinutes
    this.actualMinutes = 0
    this.startTime = ''
    this.endTime = ''
    this.interrupted = false
    this.completed = false
  }
}

export class UserPreferences {
  timeDisplay: string // '12h' | '24h'
  reminderMode: string
  density: string // 'compact' | 'comfortable' | 'spacious'
  colorTheme: string
  localMode: boolean
  highContrast: boolean
  largeText: boolean
  reduceAnimations: boolean
  showPrepareHints: boolean

  constructor() {
    this.timeDisplay = '24h'
    this.reminderMode = 'gentle'
    this.density = 'comfortable'
    this.colorTheme = 'calm'
    this.localMode = true
    this.highContrast = false
    this.largeText = false
    this.reduceAnimations = true
    this.showPrepareHints = true
  }
}

// ===== 配置类 =====

export class TimeBlockConfig {
  label: string
  iconHint: string
  bgColor: string
  desc: string

  constructor(label: string, iconHint: string, bgColor: string, desc: string) {
    this.label = label
    this.iconHint = iconHint
    this.bgColor = bgColor
    this.desc = desc
  }
}

export function getTimeBlockConfig(block: TimeBlock): TimeBlockConfig {
  switch (block) {
    case TimeBlock.DAWN: return new TimeBlockConfig('黎明', 'dawn', '#FFF8E7', '日出前的安静时光')
    case TimeBlock.MORNING: return new TimeBlockConfig('上午', 'morning', '#E8F4FF', '精力充沛的黄金时段')
    case TimeBlock.AFTERNOON: return new TimeBlockConfig('下午', 'afternoon', '#FFF4E8', '持续工作的稳定时段')
    case TimeBlock.EVENING: return new TimeBlockConfig('傍晚', 'evening', '#FFE8E8', '逐渐收束的一天')
    case TimeBlock.NIGHT: return new TimeBlockConfig('夜间', 'night', '#E8E8FF', '准备休息的时刻')
    default: return new TimeBlockConfig('上午', 'morning', '#E8F4FF', '')
  }
}

export class IntensityConfig {
  label: string
  color: string
  softColor: string

  constructor(label: string, color: string, softColor: string) {
    this.label = label
    this.color = color
    this.softColor = softColor
  }
}

export function getIntensityConfig(intensity: TaskIntensity): IntensityConfig {
  switch (intensity) {
    case TaskIntensity.LOW: return new IntensityConfig('轻松', '#34C759', '#E8F5E6')
    case TaskIntensity.MEDIUM: return new IntensityConfig('适中', '#0A59F7', '#E8EFFF')
    case TaskIntensity.HIGH: return new IntensityConfig('高强度', '#ED6F21', '#FFF4E8')
    default: return new IntensityConfig('适中', '#0A59F7', '#E8EFFF')
  }
}

export class TypeConfig {
  label: string
  color: string
  softColor: string

  constructor(label: string, color: string, softColor: string) {
    this.label = label
    this.color = color
    this.softColor = softColor
  }
}

export function getTypeConfig(type: TaskType): TypeConfig {
  switch (type) {
    case TaskType.THINK: return new TypeConfig('思考', '#7B61FF', '#F0EBFF')
    case TaskType.SOCIAL: return new TypeConfig('社交', '#ED6F21', '#FFF4E8')
    case TaskType.HOME: return new TypeConfig('居家', '#0A59F7', '#E8EFFF')
    case TaskType.REST: return new TypeConfig('休息', '#34C759', '#E8F5E6')
    case TaskType.EXERCISE: return new TypeConfig('运动', '#E84026', '#FFE8E8')
    default: return new TypeConfig('居家', '#0A59F7', '#E8EFFF')
  }
}

export class FocusModeConfig {
  label: string
  desc: string
  defaultMinutes: number
  color: string

  constructor(label: string, desc: string, defaultMinutes: number, color: string) {
    this.label = label
    this.desc = desc
    this.defaultMinutes = defaultMinutes
    this.color = color
  }
}

export function getFocusModeConfig(mode: FocusMode): FocusModeConfig {
  switch (mode) {
    case FocusMode.MINI: return new FocusModeConfig('微专注', '只需几分钟，先开始就好', 5, '#34C759')
    case FocusMode.NORMAL: return new FocusModeConfig('标准专注', '常规的专注时段', 25, '#0A59F7')
    case FocusMode.ESTIMATE: return new FocusModeConfig('预估专注', '先预估时间，再开始执行', 45, '#7B61FF')
    case FocusMode.BODY: return new FocusModeConfig('身体专注', '关注身体感受的节奏', 15, '#ED6F21')
    default: return new FocusModeConfig('标准专注', '常规的专注时段', 25, '#0A59F7')
  }
}

export class TaskTemplate {
  title: string
  type: TaskType
  intensity: TaskIntensity
  timeBlock: TimeBlock
  prepareItems: string[]
  subTasks: string[]
  durationMinutes: number

  constructor(title: string, type: TaskType, intensity: TaskIntensity, timeBlock: TimeBlock, durationMinutes: number) {
    this.title = title
    this.type = type
    this.intensity = intensity
    this.timeBlock = timeBlock
    this.prepareItems = []
    this.subTasks = []
    this.durationMinutes = durationMinutes
  }
}
