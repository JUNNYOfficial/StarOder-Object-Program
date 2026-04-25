export class SubTask {
  id: string
  title: string
  isCompleted: boolean

  constructor(title: string) {
    this.id = Date.now().toString() + Math.random().toString(36).slice(2, 8)
    this.title = title
    this.isCompleted = false
  }
}

export class Schedule {
  id: string
  title: string
  date: string
  startTime: string
  endTime: string
  colorTag: string
  notes: string
  prepareItems: string[]
  subTasks: SubTask[]
  isCompleted: boolean
  hasReminder: boolean

  constructor(title: string, date: string, startTime: string, endTime: string) {
    this.id = Date.now().toString() + Math.random().toString(36).slice(2, 8)
    this.title = title
    this.date = date
    this.startTime = startTime
    this.endTime = endTime
    this.colorTag = 'calm'
    this.notes = ''
    this.prepareItems = []
    this.subTasks = []
    this.isCompleted = false
    this.hasReminder = false
  }
}

export class ColorTagInfo {
  label: string
  color: string
  bg: string
  hcColor: string

  constructor(label: string, color: string, bg: string, hcColor: string) {
    this.label = label
    this.color = color
    this.bg = bg
    this.hcColor = hcColor
  }
}

export function getColorTag(key: string): ColorTagInfo {
  switch (key) {
    case 'calm': return new ColorTagInfo('平静', '#0A59F7', '#E8EFFF', '#005F87')
    case 'energy': return new ColorTagInfo('活力', '#ED6F21', '#FFF4E8', '#8B4A14')
    case 'focus': return new ColorTagInfo('专注', '#7B61FF', '#F0EBFF', '#4A3B8C')
    case 'rest': return new ColorTagInfo('休息', '#34C759', '#E8F5E6', '#1A6B2E')
    default: return new ColorTagInfo('平静', '#0A59F7', '#E8EFFF', '#005F87')
  }
}

export const COLOR_TAG_KEYS = ['calm', 'energy', 'focus', 'rest']
