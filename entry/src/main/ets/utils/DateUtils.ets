export function formatDate(d: Date): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

export function formatTime(d: Date): string {
  const h = String(d.getHours()).padStart(2, '0')
  const min = String(d.getMinutes()).padStart(2, '0')
  return `${h}:${min}`
}

export function todayStr(): string {
  return formatDate(new Date())
}

export function formatYMD(y: number, m: number, d: number): string {
  const ms = String(m).padStart(2, '0')
  const ds = String(d).padStart(2, '0')
  return `${y}-${ms}-${ds}`
}

export function tomorrowStr(): string {
  const d = new Date()
  d.setDate(d.getDate() + 1)
  return formatDate(d)
}

export function dayAfterTomorrowStr(): string {
  const d = new Date()
  d.setDate(d.getDate() + 2)
  return formatDate(d)
}

export function parseDateStr(dateStr: string): Date {
  const parts = dateStr.split('-')
  const y = parseInt(parts[0])
  const m = parseInt(parts[1]) - 1
  const day = parseInt(parts[2])
  return new Date(y, m, day)
}

export function addDays(dateStr: string, days: number): string {
  const d = parseDateStr(dateStr)
  d.setDate(d.getDate() + days)
  return formatDate(d)
}

export function getWeekdayName(day: number): string {
  const names = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
  return names[day % 7]
}

export function getWeekdayOffset(targetWeekday: number): number {
  const today = new Date().getDay()
  const current = today === 0 ? 7 : today
  let offset = targetWeekday - current
  if (offset <= 0) offset += 7
  return offset
}

export function daysLaterStr(days: number): string {
  const d = new Date()
  d.setDate(d.getDate() + days)
  return formatDate(d)
}

export function nextWeekdayStr(targetWeekday: number): string {
  return daysLaterStr(getWeekdayOffset(targetWeekday))
}
