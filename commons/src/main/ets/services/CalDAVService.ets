import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { dataStore } from '../models/DataStore'
import { Course, CourseScheduleState, WeekType } from '../models/CourseModels'

const TAG = '[CalDAV]'

const KEY_CALDAV_SERVER = 'caldav_server_url'
const KEY_CALDAV_USER = 'caldav_username'
const KEY_CALDAV_PASS = 'caldav_password'
const KEY_CALDAV_PATH = 'caldav_calendar_path'
const KEY_CALDAV_SYNC_STATE = 'caldav_sync_state'

export interface CalDAVConfig {
  serverUrl: string
  username: string
  password: string
  calendarPath: string
}

interface CalDAVSyncState {
  lastSyncTime: number
  syncedUids: string[]
}

async function getConfig(): Promise<CalDAVConfig> {
  return {
    serverUrl: await dataStore.get<string>(KEY_CALDAV_SERVER, ''),
    username: await dataStore.get<string>(KEY_CALDAV_USER, ''),
    password: await dataStore.get<string>(KEY_CALDAV_PASS, ''),
    calendarPath: await dataStore.get<string>(KEY_CALDAV_PATH, '')
  }
}

async function setConfig(config: CalDAVConfig): Promise<void> {
  await dataStore.put(KEY_CALDAV_SERVER, config.serverUrl)
  await dataStore.put(KEY_CALDAV_USER, config.username)
  await dataStore.put(KEY_CALDAV_PASS, config.password)
  await dataStore.put(KEY_CALDAV_PATH, config.calendarPath)
}

async function getSyncState(): Promise<CalDAVSyncState> {
  const defaultState: CalDAVSyncState = { lastSyncTime: 0, syncedUids: [] }
  return await dataStore.get<CalDAVSyncState>(KEY_CALDAV_SYNC_STATE, defaultState)
}

async function setSyncState(state: CalDAVSyncState): Promise<void> {
  await dataStore.put(KEY_CALDAV_SYNC_STATE, state)
}

async function clearSyncState(): Promise<void> {
  const emptyState: CalDAVSyncState = { lastSyncTime: 0, syncedUids: [] }
  await dataStore.put(KEY_CALDAV_SYNC_STATE, emptyState)
}

async function getLastSyncText(): Promise<string> {
  const state = await getSyncState()
  if (state.lastSyncTime === 0) {
    return '上次同步: 从未同步'
  }
  const d = new Date(state.lastSyncTime)
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  const h = String(d.getHours()).padStart(2, '0')
  const min = String(d.getMinutes()).padStart(2, '0')
  return `上次同步: ${y}-${m}-${day} ${h}:${min}`
}

function makeAuthHeader(username: string, password: string): string {
  const creds = `${username}:${password}`
  const base64 = encodeBase64(creds)
  return `Basic ${base64}`
}

function encodeBase64(input: string): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
  let output = ''
  let i = 0
  while (i < input.length) {
    const a = input.charCodeAt(i++)
    const b = i < input.length ? input.charCodeAt(i++) : NaN
    const c = i < input.length ? input.charCodeAt(i++) : NaN
    const bitmap = (a << 16) | ((!isNaN(b) ? b : 0) << 8) | (!isNaN(c) ? c : 0)
    output += chars.charAt((bitmap >> 18) & 63)
    output += chars.charAt((bitmap >> 12) & 63)
    output += !isNaN(b) ? chars.charAt((bitmap >> 6) & 63) : '='
    output += !isNaN(c) ? chars.charAt(bitmap & 63) : '='
  }
  return output
}

interface LooseRequestOptions {
  method: string
  header: Record<string, string>
  extraData: string
  connectTimeout: number
  readTimeout: number
}

function doRequest(
  url: string,
  method: string,
  headers: Record<string, string>,
  body: string,
  onResult: (statusCode: number, result: string, errMsg: string) => void
): void {
  const req = http.createHttp()
  const options: LooseRequestOptions = {
    method: method,
    header: headers,
    extraData: body,
    connectTimeout: 15000,
    readTimeout: 15000
  }
  req.request(url, options as http.HttpRequestOptions, (err: BusinessError, data: http.HttpResponse) => {
    if (err) {
      const msg = err.message ?? '未知网络错误'
      console.error(TAG, `HTTP ${method} error:`, msg)
      onResult(0, '', msg)
      return
    }
    const resultStr = data.result ? data.result.toString() : ''
    console.info(TAG, `${method} ${url} status=${data.responseCode}`)
    onResult(data.responseCode ?? 200, resultStr, '')
  })
}

function formatICSDateTime(d: Date): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  const h = String(d.getHours()).padStart(2, '0')
  const min = String(d.getMinutes()).padStart(2, '0')
  const s = String(d.getSeconds()).padStart(2, '0')
  return `${y}${m}${day}T${h}${min}${s}`
}

function escapeICS(value: string): string {
  return value
    .replace(/\\/g, '\\\\')
    .replace(/;/g, '\\;')
    .replace(/,/g, '\\,')
    .replace(/\n/g, '\\n')
}

function getCurrentSemesterStart(): Date {
  const now = new Date()
  const year = now.getFullYear()
  const month = now.getMonth()
  if (month < 6) {
    return new Date(year, 1, 17)
  } else {
    return new Date(year, 8, 1)
  }
}

function generateCourseICS(course: Course, state: CourseScheduleState): string {
  const baseDate = state.semesterStartDate
    ? new Date(state.semesterStartDate)
    : getCurrentSemesterStart()

  const firstWeekOffset = (course.startWeek - 1) * 7 + (course.dayOfWeek - 1)
  const eventDate = new Date(baseDate)
  eventDate.setDate(eventDate.getDate() + firstWeekOffset)

  const startSlot = state.timeSlots.find(s => s && s.slotNumber === course.startSlot)
  const endSlotNum = course.startSlot + course.slotCount - 1
  const endSlot = state.timeSlots.find(s => s && s.slotNumber === endSlotNum)

  if (!startSlot || !endSlot) return ''

  const startParts = startSlot.startTime.split(':')
  const endParts = endSlot.endTime.split(':')

  const startH = parseInt(startParts[0])
  const startM = parseInt(startParts[1])
  const endH = parseInt(endParts[0])
  const endM = parseInt(endParts[1])

  const startTime = new Date(eventDate)
  startTime.setHours(startH, startM, 0, 0)
  const endTime = new Date(eventDate)
  endTime.setHours(endH, endM, 0, 0)

  const dtStart = formatICSDateTime(startTime)
  const dtEnd = formatICSDateTime(endTime)

  const uid = `starorder-${course.id}@starorder.app`

  const weekCount = course.endWeek - course.startWeek + 1
  let interval = 1
  let count = weekCount
  if (course.weekType === WeekType.ODD || course.weekType === WeekType.EVEN) {
    interval = 2
    count = Math.ceil(weekCount / 2)
  }
  const rrule = `FREQ=WEEKLY;INTERVAL=${interval};COUNT=${count}`

  const summary = escapeICS(course.name)
  const description = escapeICS(`教室: ${course.classroom || '未指定'} 教师: ${course.teacher || '未指定'} 第${course.startWeek}-${course.endWeek}周`)
  const location = escapeICS(course.classroom || '')

  const lines: string[] = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'PRODID:-//StarOrder//CalDAV Client//EN',
    'CALSCALE:GREGORIAN',
    'METHOD:PUBLISH',
    'BEGIN:VTIMEZONE',
    'TZID:Asia/Shanghai',
    'BEGIN:STANDARD',
    'DTSTART:19700101T000000',
    'TZOFFSETFROM:+0800',
    'TZOFFSETTO:+0800',
    'END:STANDARD',
    'END:VTIMEZONE',
    'BEGIN:VEVENT',
    `UID:${uid}`,
    `DTSTART;TZID=Asia/Shanghai:${dtStart}`,
    `DTEND;TZID=Asia/Shanghai:${dtEnd}`,
    `SUMMARY:${summary}`,
    `DESCRIPTION:${description}`,
    `LOCATION:${location}`,
    `RRULE:${rrule}`,
    'BEGIN:VALARM',
    'ACTION:DISPLAY',
    'DESCRIPTION:Reminder',
    'TRIGGER:-PT15M',
    'END:VALARM',
    'END:VEVENT',
    'END:VCALENDAR'
  ]
  return lines.join('\r\n')
}

function testConnection(config: CalDAVConfig, onResult: (success: boolean, msg: string) => void): void {
  if (!config.serverUrl || !config.username || !config.password) {
    onResult(false, '请先配置 CalDAV 服务器地址、用户名和密码')
    return
  }

  const url = config.calendarPath || config.serverUrl
  const auth = makeAuthHeader(config.username, config.password)

  const body = `<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:">
  <d:prop>
    <d:displayname/>
  </d:prop>
</d:propfind>`

  doRequest(url, 'PROPFIND', {
    'Authorization': auth,
    'Content-Type': 'application/xml; charset=utf-8',
    'Depth': '0'
  }, body, (status, result, errMsg) => {
    if (errMsg) {
      onResult(false, errMsg)
      return
    }
    if (status === 207 || status === 200) {
      onResult(true, '连接成功')
    } else if (status === 401) {
      onResult(false, '认证失败，请检查用户名和密码')
    } else if (status === 404) {
      onResult(false, '日历路径不存在，请检查配置')
    } else {
      onResult(false, `服务器返回 HTTP ${status}`)
    }
  })
}

async function syncCoursesToCalDAV(
  state: CourseScheduleState,
  onResult: (success: number, failed: number, msg: string) => void
): Promise<void> {
  const config = await getConfig()
  if (!config.serverUrl || !config.username || !config.password || !config.calendarPath) {
    onResult(0, 0, 'CalDAV 未配置，请先在设置中配置服务器信息')
    return
  }

  const auth = makeAuthHeader(config.username, config.password)
  const courses = state.courses
  const prevState = await getSyncState()

  // 计算当前课程对应的 UID 集合
  const currentUids: string[] = []
  for (let i = 0; i < courses.length; i++) {
    currentUids.push(`starorder-${courses[i].id}@starorder.app`)
  }
  const currentUidSet = new Set<string>(currentUids)

  // 找出需要删除的 UID（上次同步有，但这次课程列表中没有）
  const toDelete: string[] = []
  for (let i = 0; i < prevState.syncedUids.length; i++) {
    const uid = prevState.syncedUids[i]
    if (!currentUidSet.has(uid)) {
      toDelete.push(uid)
    }
  }

  const totalTasks = toDelete.length + courses.length
  if (totalTasks === 0) {
    onResult(0, 0, '没有需要同步的内容')
    return
  }

  let putSuccess = 0
  let putFailed = 0
  let deleteSuccess = 0
  let deleteFailed = 0
  let completed = 0

  const checkDone = async () => {
    completed++
    if (completed >= totalTasks) {
      // 保存新的同步状态（只记录当前存在的课程 UID）
      const newState: CalDAVSyncState = { lastSyncTime: Date.now(), syncedUids: currentUids }
      await setSyncState(newState)
      const failed = putFailed + deleteFailed
      onResult(putSuccess + deleteSuccess, failed,
        `上传成功 ${putSuccess} 个，清理旧事件 ${deleteSuccess} 个，失败 ${failed} 个`)
    }
  }

  // 先处理删除
  for (let i = 0; i < toDelete.length; i++) {
    const uid = toDelete[i]
    const eventUrl = `${config.calendarPath}/${uid}.ics`
    doRequest(eventUrl, 'DELETE', { 'Authorization': auth }, '', async (status, result, errMsg) => {
      if (errMsg) {
        console.error(TAG, `删除失败 ${uid}:`, errMsg)
        deleteFailed++
      } else if (status >= 200 && status < 300 || status === 404) {
        // 404 表示事件已不存在，也算清理成功
        console.info(TAG, `删除成功 ${uid}`)
        deleteSuccess++
      } else {
        console.error(TAG, `删除失败 ${uid}, status=${status}`)
        deleteFailed++
      }
      await checkDone()
    })
  }

  // 再处理上传/更新
  for (let i = 0; i < courses.length; i++) {
    const course = courses[i]
    const icsData = generateCourseICS(course, state)
    if (!icsData) {
      putFailed++
      await checkDone()
      continue
    }

    const uid = `starorder-${course.id}@starorder.app`
    const eventUrl = `${config.calendarPath}/${uid}.ics`

    doRequest(eventUrl, 'PUT', {
      'Authorization': auth,
      'Content-Type': 'text/calendar; charset=utf-8'
    }, icsData, async (status, result, errMsg) => {
      if (errMsg) {
        console.error(TAG, `上传失败 ${course.name}:`, errMsg)
        putFailed++
      } else if (status >= 200 && status < 300) {
        console.info(TAG, `上传成功 ${course.name}`)
        putSuccess++
      } else {
        console.error(TAG, `上传失败 ${course.name}, status=${status}`)
        putFailed++
      }
      await checkDone()
    })
  }
}

class CalDAVServiceClass {
  async getConfig(): Promise<CalDAVConfig> { return await getConfig() }
  async setConfig(config: CalDAVConfig): Promise<void> { await setConfig(config) }
  async isConfigured(): Promise<boolean> {
    const c = await getConfig()
    return c.serverUrl.length > 0 && c.username.length > 0 && c.password.length > 0 && c.calendarPath.length > 0
  }
  testConnection(config: CalDAVConfig, onResult: (success: boolean, msg: string) => void): void {
    testConnection(config, onResult)
  }
  async syncCoursesToCalDAV(state: CourseScheduleState, onResult: (success: number, failed: number, msg: string) => void): Promise<void> {
    await syncCoursesToCalDAV(state, onResult)
  }
  async getLastSyncText(): Promise<string> { return await getLastSyncText() }
  async clearSyncState(): Promise<void> { await clearSyncState() }
}

export const CalDAVService = new CalDAVServiceClass()
