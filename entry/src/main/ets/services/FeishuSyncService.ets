import { http } from '@kit.NetworkKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { Task, TaskType, TaskIntensity, TimeBlock, TaskStatus } from '../models/DataModels'
import { dataStore } from '../models/DataStore'

const KEY_FEISHU_TOKEN = 'feishu_token'
const KEY_FEISHU_EXPIRES = 'feishu_token_expires'
const KEY_FEISHU_APP_ID = 'feishu_app_id'
const KEY_FEISHU_APP_SECRET = 'feishu_app_secret'

const TENANT_TOKEN_URL = 'https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal'
const CALENDAR_URL = 'https://open.feishu.cn/open-apis/calendar/v4/calendars/primary/events'

class TenantTokenResponse {
  code: number = 0
  msg: string = ''
  tenant_access_token: string = ''
  expire: number = 0
}

class FeishuApiResponse {
  code: number = 0
  msg: string = ''
  data: FeishuEventData = new FeishuEventData()
}

class FeishuEventData {
  items: FeishuEventItem[] = []
}

class FeishuEventTime {
  timestamp: string = '0'
}

class FeishuEventItem {
  summary: string = ''
  title: string = ''
  event_id: string = ''
  id: string = ''
  description: string = ''
  start_time: FeishuEventTime = new FeishuEventTime()
  end_time: FeishuEventTime = new FeishuEventTime()
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

function isConfigured(): boolean {
  return getAppId().length > 0 && getAppSecret().length > 0
}

function getToken(): string {
  return dataStore.get<string>(KEY_FEISHU_TOKEN, '')
}

function getTokenExpires(): number {
  return dataStore.get<number>(KEY_FEISHU_EXPIRES, 0)
}

function isAuthorized(): boolean {
  const token = getToken()
  if (!token) return false
  return Date.now() < getTokenExpires()
}

function saveToken(token: string, expiresIn: number): void {
  dataStore.put(KEY_FEISHU_TOKEN, token)
  dataStore.put(KEY_FEISHU_EXPIRES, Date.now() + expiresIn * 1000)
}

function clearAuth(): void {
  dataStore.put(KEY_FEISHU_TOKEN, '')
  dataStore.put(KEY_FEISHU_EXPIRES, 0)
}

function doPost(url: string, body: string, headers: Record<string, string>,
  onResult: (statusCode: number, result: string, errMsg: string) => void): void {
  const req = http.createHttp()
  req.request(url, {
    method: http.RequestMethod.POST,
    header: headers,
    extraData: body,
    connectTimeout: 15000,
    readTimeout: 15000
  }, (err: BusinessError, data: http.HttpResponse) => {
    if (err) {
      const code = err.code ?? 0
      const msg = err.message ?? '未知网络错误'
      console.error(`[Feishu] HTTP error: code=${code}, msg=${msg}`)
      onResult(0, '', `网络请求失败: ${msg}`)
      return
    }
    const resultStr = data.result ? data.result.toString() : ''
    console.info(`[Feishu] ${url} response: ${resultStr.substring(0, 200)}`)
    onResult(data.responseCode ?? 200, resultStr, '')
  })
}

function exchangeCodeForToken(code: string, onResult: (success: boolean, msg: string) => void): void {
  // 不再使用 OAuth code 换 token，改为直接用 app_id + app_secret 获取 tenant_access_token
  connectWithSecret(onResult)
}

function connectWithSecret(onResult: (success: boolean, msg: string) => void): void {
  const appId = getAppId()
  const appSecret = getAppSecret()
  if (!appId || !appSecret) {
    onResult(false, '请先配置飞书 App ID 和 App Secret')
    return
  }

  console.info(`[Feishu] getting tenant_access_token for appId=${appId}`)

  const body = JSON.stringify({ app_id: appId, app_secret: appSecret })

  doPost(TENANT_TOKEN_URL, body, { 'Content-Type': 'application/json' },
    (statusCode, resultStr, errMsg) => {
      if (errMsg) {
        onResult(false, errMsg)
        return
      }
      try {
        const resp = JSON.parse(resultStr) as TenantTokenResponse
        if (resp.code !== 0) {
          onResult(false, `飞书错误: ${resp.msg} (code=${resp.code})`)
          return
        }
        if (!resp.tenant_access_token) {
          onResult(false, '飞书未返回 token，请检查 App ID/Secret 是否正确')
          return
        }
        saveToken(resp.tenant_access_token, resp.expire)
        onResult(true, '连接成功')
      } catch (e) {
        onResult(false, `解析响应失败: ${resultStr}`)
      }
    })
}

function fetchCalendarEvents(onResult: (tasks: Task[], msg: string) => void): void {
  const token = getToken()
  if (!token || Date.now() >= getTokenExpires()) {
    // token 过期，自动刷新
    connectWithSecret((success, msg) => {
      if (success) {
        fetchCalendarEvents(onResult)
      } else {
        onResult([], `Token 过期且刷新失败: ${msg}`)
      }
    })
    return
  }

  const now = new Date()
  const start = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 7)
  const end = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 30)
  const timeMin = start.toISOString()
  const timeMax = end.toISOString()
  const url = `${CALENDAR_URL}?time_min=${encodeURIComponent(timeMin)}&time_max=${encodeURIComponent(timeMax)}&page_size=100`

  const req = http.createHttp()
  req.request(url, {
    method: http.RequestMethod.GET,
    header: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    connectTimeout: 15000,
    readTimeout: 15000
  }, (err: BusinessError, data: http.HttpResponse) => {
    if (err) {
      onResult([], `请求失败: ${err.message ?? '未知错误'}`)
      return
    }
    try {
      const resultStr = data.result ? data.result.toString() : '{}'
      const result = JSON.parse(resultStr) as FeishuApiResponse
      if (result.code !== 0) {
        onResult([], `飞书错误: ${result.msg} (code=${result.code})`)
        return
      }
      const eventData = result.data as FeishuEventData
      const tasks = convertEventsToTasks(eventData.items)
      onResult(tasks, `同步了 ${tasks.length} 个日程`)
    } catch (e) {
      onResult([], '解析响应失败')
    }
  })
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
  getAppId(): string { return getAppId() }
  setAppId(id: string): void { setAppId(id) }
  getAppSecret(): string { return getAppSecret() }
  setAppSecret(secret: string): void { setAppSecret(secret) }
  isConfigured(): boolean { return isConfigured() }
  isAuthorized(): boolean { return isAuthorized() }
  getToken(): string { return getToken() }
  saveToken(token: string, expiresIn: number): void { saveToken(token, expiresIn) }
  clearAuth(): void { clearAuth() }
  exchangeCodeForToken(code: string, onResult: (success: boolean, msg: string) => void): void { connectWithSecret(onResult) }
  fetchCalendarEvents(onResult: (tasks: Task[], msg: string) => void): void { fetchCalendarEvents(onResult) }
}

export const FeishuSyncService = new FeishuSyncServiceClass()
