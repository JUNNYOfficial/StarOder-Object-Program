import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { Task, TaskType, TaskIntensity, TimeBlock, TaskStatus } from '../models/DataModels'
import { dataStore } from '../models/DataStore'

const KEY_FEISHU_TOKEN = 'feishu_access_token'
const KEY_FEISHU_REFRESH = 'feishu_refresh_token'
const KEY_FEISHU_EXPIRES = 'feishu_token_expires'
const KEY_FEISHU_APP_ID = 'feishu_app_id'
const KEY_FEISHU_APP_SECRET = 'feishu_app_secret'

const TOKEN_URL = 'https://open.feishu.cn/open-apis/authen/v1/access_token'
const CALENDAR_URL = 'https://open.feishu.cn/open-apis/calendar/v4/calendars/primary/events'
const REDIRECT_URI = 'starorder://auth/feishu'

export class FeishuToken {
  accessToken: string
  refreshToken: string
  expiresAt: number
  constructor(accessToken: string, refreshToken: string, expiresIn: number) {
    this.accessToken = accessToken
    this.refreshToken = refreshToken
    this.expiresAt = Date.now() + expiresIn * 1000
  }
}

class FeishuApiResponse {
  code: number
  msg: string
  data: FeishuTokenData | FeishuEventData
  constructor() {
    this.code = 0
    this.msg = ''
    this.data = new FeishuTokenData()
  }
}

class FeishuTokenData {
  access_token: string
  refresh_token: string
  expires_in: number
  constructor() {
    this.access_token = ''
    this.refresh_token = ''
    this.expires_in = 0
  }
}

class FeishuEventData {
  items: FeishuEventItem[]
  constructor() {
    this.items = []
  }
}

class FeishuEventTime {
  timestamp: string
  constructor() {
    this.timestamp = '0'
  }
}

class FeishuEventItem {
  summary: string
  title: string
  event_id: string
  id: string
  description: string
  start_time: FeishuEventTime
  end_time: FeishuEventTime
  constructor() {
    this.summary = ''
    this.title = ''
    this.event_id = ''
    this.id = ''
    this.description = ''
    this.start_time = new FeishuEventTime()
    this.end_time = new FeishuEventTime()
  }
}

function getAppId(): string {
  return dataStore.get<string>(KEY_FEISHU_APP_ID, '')
}

function setAppId(id: string): void {
  dataStore.put(KEY_FEISHU_APP_ID, id)
}

function getAppSecret(): string {
  return dataStore.get<string>(KEY_FEISHU_APP_SECRET, '')
}

function setAppSecret(secret: string): void {
  dataStore.put(KEY_FEISHU_APP_SECRET, secret)
}

function getAuthUrl(): string {
  const appId = getAppId()
  return `https://open.feishu.cn/open-apis/authen/v1/index?app_id=${appId}&redirect_uri=${encodeURIComponent(REDIRECT_URI)}`
}

function isConfigured(): boolean {
  return getAppId().length > 0 && getAppSecret().length > 0
}

function getToken(): FeishuToken | null {
  const access = dataStore.get<string>(KEY_FEISHU_TOKEN, '')
  if (!access) return null
  const refresh = dataStore.get<string>(KEY_FEISHU_REFRESH, '')
  const expires = dataStore.get<number>(KEY_FEISHU_EXPIRES, 0)
  return new FeishuToken(access, refresh, Math.floor((expires - Date.now()) / 1000))
}

function isAuthorized(): boolean {
  const token = getToken()
  if (!token) return false
  return Date.now() < token.expiresAt
}

function saveToken(token: FeishuToken): void {
  dataStore.put(KEY_FEISHU_TOKEN, token.accessToken)
  dataStore.put(KEY_FEISHU_REFRESH, token.refreshToken)
  dataStore.put(KEY_FEISHU_EXPIRES, token.expiresAt)
}

function clearAuth(): void {
  dataStore.put(KEY_FEISHU_TOKEN, '')
  dataStore.put(KEY_FEISHU_REFRESH, '')
  dataStore.put(KEY_FEISHU_EXPIRES, 0)
}

function exchangeCodeForToken(code: string, onResult: (success: boolean, msg: string) => void): void {
  const appId = getAppId()
  const appSecret = getAppSecret()
  if (!appId || !appSecret) {
    onResult(false, '请先配置飞书应用 ID 和 Secret')
    return
  }

  const httpRequest = http.createHttp()
  const body = JSON.stringify({
    grant_type: 'authorization_code',
    code: code,
    client_id: appId,
    client_secret: appSecret
  })

  httpRequest.request(
    TOKEN_URL,
    {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json' },
      extraData: body
    },
    (err: BusinessError, data: http.HttpResponse) => {
      if (err) {
        onResult(false, `请求失败: ${err.message}`)
        return
      }
      try {
        const result = JSON.parse(data.result as string) as FeishuApiResponse
        if (result.code !== 0) {
          onResult(false, `飞书错误: ${result.msg}`)
          return
        }
        const tokenData = result.data as FeishuTokenData
        if (tokenData.access_token) {
          saveToken(new FeishuToken(tokenData.access_token, tokenData.refresh_token, tokenData.expires_in))
          onResult(true, '授权成功')
        } else {
          onResult(false, '未获取到 access_token')
        }
      } catch (e) {
        onResult(false, `解析响应失败`)
      }
    }
  )
}

function fetchCalendarEvents(onResult: (tasks: Task[], msg: string) => void): void {
  const token = getToken()
  if (!token || Date.now() >= token.expiresAt) {
    onResult([], '飞书授权已过期，请重新连接')
    return
  }

  const now = new Date()
  const start = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 7)
  const end = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 30)
  const timeMin = start.toISOString()
  const timeMax = end.toISOString()
  const url = `${CALENDAR_URL}?time_min=${encodeURIComponent(timeMin)}&time_max=${encodeURIComponent(timeMax)}&page_size=100`

  const httpRequest = http.createHttp()
  httpRequest.request(
    url,
    {
      method: http.RequestMethod.GET,
      header: { 'Authorization': `Bearer ${token.accessToken}` }
    },
    (err: BusinessError, data: http.HttpResponse) => {
      if (err) {
        onResult([], `请求失败: ${err.message}`)
        return
      }
      try {
        const result = JSON.parse(data.result as string) as FeishuApiResponse
        if (result.code !== 0) {
          onResult([], `飞书错误: ${result.msg}`)
          return
        }
        const eventData = result.data as FeishuEventData
        const tasks = convertEventsToTasks(eventData.items)
        onResult(tasks, `同步了 ${tasks.length} 个日程`)
      } catch (e) {
        onResult([], `解析响应失败`)
      }
    }
  )
}

function convertEventsToTasks(items: FeishuEventItem[]): Task[] {
  const tasks: Task[] = []
  for (let i = 0; i < items.length; i++) {
    const item = items[i]
    const summary = item.summary || item.title || '飞书日程'
    const eventId = item.event_id || item.id || ''

    const startObj = item.start_time
    const endObj = item.end_time
    if (!startObj || !endObj) continue

    const startTs = startObj.timestamp || '0'
    const endTs = endObj.timestamp || '0'
    const startDate = new Date(parseInt(startTs) * 1000)
    const endDate = new Date(parseInt(endTs) * 1000)

    const dateStr = formatDate(startDate)
    const startTimeStr = formatTime(startDate)
    const endTimeStr = formatTime(endDate)

    const task = new Task(summary, dateStr, startTimeStr, endTimeStr)
    task.notes = item.description || ''
    task.source = 'feishu'
    task.externalId = eventId
    task.status = TaskStatus.TODO
    task.type = TaskType.THINK
    task.intensity = TaskIntensity.MEDIUM
    task.timeBlock = inferTimeBlock(startDate.getHours())
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

class FeishuSyncServiceClass {
  getAuthUrl(): string { return getAuthUrl() }
  getAppId(): string { return getAppId() }
  setAppId(id: string): void { setAppId(id) }
  getAppSecret(): string { return getAppSecret() }
  setAppSecret(secret: string): void { setAppSecret(secret) }
  isConfigured(): boolean { return isConfigured() }
  isAuthorized(): boolean { return isAuthorized() }
  getToken(): FeishuToken | null { return getToken() }
  saveToken(token: FeishuToken): void { saveToken(token) }
  clearAuth(): void { clearAuth() }
  exchangeCodeForToken(code: string, onResult: (success: boolean, msg: string) => void): void { exchangeCodeForToken(code, onResult) }
  fetchCalendarEvents(onResult: (tasks: Task[], msg: string) => void): void { fetchCalendarEvents(onResult) }
}

export const FeishuSyncService = new FeishuSyncServiceClass()
