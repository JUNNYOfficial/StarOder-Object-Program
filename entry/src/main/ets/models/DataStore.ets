import { preferences } from '@kit.ArkData'
import {
  Task, SubTask, EnergyRecord, MoodSurveyRecord, FocusRecord, UserPreferences, TaskStatus, RepeatMode, YesterdaySummary, FaceMoodRecord
} from './DataModels'
import { Course, TimeSlot, CourseScheduleState, DEFAULT_TIME_SLOTS, WeekType } from './CourseModels'
import { formatDate } from '../utils/DateUtils'
import { CryptoService } from '../services/CryptoService'

interface ConflictResult {
  hasConflict: boolean
  conflictWith: string
}

interface FocusStatsResult {
  totalMinutes: number
  sessions: number
  completedSessions: number
  dailyData: Record<string, number>
}

interface FocusWeeklyStat {
  label: string
  totalMinutes: number
  sessions: number
}

interface FocusDailyStat {
  label: string
  minutes: number
}

interface SyncExternalTasksResult {
  added: number
  updated: number
}

const KEY_TASKS = 'star_tasks'
const KEY_ENERGY = 'star_energy_records'
const KEY_MOOD = 'star_mood_surveys'
const KEY_FOCUS = 'star_focus_records'
const KEY_PREFS = 'star_user_prefs'
const KEY_COURSES = 'star_courses'
const KEY_COURSE_STATE = 'star_course_state'
const KEY_AGREED_TERMS = 'star_agreed_terms'
const KEY_LAST_LOGIN_DATE = 'star_last_login_date'
const KEY_SHOW_YESTERDAY_SUMMARY = 'star_show_yesterday_summary'
const KEY_YESTERDAY_SUMMARY = 'star_yesterday_summary'
const KEY_FACE_MOOD = 'star_face_mood_records'
const KEY_LAST_MOOD_PROMPT = 'star_last_mood_prompt'
const KEY_ENC_MIGRATED = 'star_enc_migrated'

class DataStore {
  private pref: preferences.Preferences | null = null
  private initialized: boolean = false

  async init(context: Context): Promise<void> {
    try {
      this.pref = preferences.getPreferencesSync(context, { name: 'star_order_db_v2' })
      await CryptoService.initLocalKey()
      await this.migrateToEncrypted()
      await this.cleanExpiredDeletedTasks()
      this.initialized = true
    } catch (e) {
      console.error('DataStore init failed:', JSON.stringify(e))
    }
  }

  private async migrateToEncrypted(): Promise<void> {
    if (!this.pref) return
    const migrated = this.pref.getSync(KEY_ENC_MIGRATED, '') as string
    if (migrated === 'true') return

    const keysToMigrate = [
      KEY_TASKS, KEY_ENERGY, KEY_MOOD, KEY_FOCUS, KEY_PREFS,
      KEY_COURSES, KEY_COURSE_STATE, KEY_AGREED_TERMS, KEY_LAST_LOGIN_DATE,
      KEY_SHOW_YESTERDAY_SUMMARY, KEY_YESTERDAY_SUMMARY,
      KEY_FACE_MOOD, KEY_LAST_MOOD_PROMPT
    ]

    for (const key of keysToMigrate) {
      const raw = this.pref.getSync(key, '') as string
      if (raw && !CryptoService.isEncrypted(raw)) {
        try {
          const encrypted = await CryptoService.encryptLocal(raw)
          this.pref.putSync(key, encrypted)
        } catch (e) {
          console.error(`Migrate ${key} failed:`, JSON.stringify(e))
        }
      }
    }

    this.pref.putSync(KEY_ENC_MIGRATED, 'true')
    this.pref.flush()
  }

  // ===== Generic helpers =====
  async put<T>(key: string, value: T): Promise<void> {
    if (!this.pref) return
    try {
      const plain = JSON.stringify(value)
      const encrypted = await CryptoService.encryptLocal(plain)
      this.pref.putSync(key, encrypted)
      this.pref.flush()
    } catch (e) {
      console.error(`Save ${key} failed:`, JSON.stringify(e))
    }
  }

  async get<T>(key: string, defaultValue: T): Promise<T> {
    if (!this.pref) return defaultValue
    try {
      const raw = this.pref.getSync(key, '') as string
      if (!raw) return defaultValue
      const decrypted = await CryptoService.decryptLocal(raw)
      return JSON.parse(decrypted) as T
    } catch (e) {
      console.error(`Get ${key} failed:`, JSON.stringify(e))
      return defaultValue
    }
  }

  // ===== Tasks =====
  async getTasks(): Promise<Task[]> {
    return this.get<Task[]>(KEY_TASKS, [])
  }

  async saveTasks(tasks: Task[]): Promise<void> {
    this.put(KEY_TASKS, tasks)
  }

  async syncExternalTasks(newTasks: Task[], source: string): Promise<SyncExternalTasksResult> {
    const all = await this.getTasks()
    let added = 0
    let updated = 0
    for (let i = 0; i < newTasks.length; i++) {
      const newTask = newTasks[i]
      newTask.source = source
      const existingIdx = all.findIndex(t => t.externalId === newTask.externalId && t.source === source)
      if (existingIdx >= 0) {
        const existing = all[existingIdx]
        existing.title = newTask.title
        existing.date = newTask.date
        existing.startTime = newTask.startTime
        existing.endTime = newTask.endTime
        existing.notes = newTask.notes
        existing.timeBlock = newTask.timeBlock
        existing.updatedAt = Date.now()
        updated++
      } else {
        all.push(newTask)
        added++
      }
    }
    await this.saveTasks(all)
    const result: SyncExternalTasksResult = { added: added, updated: updated }
    return result
  }

  async addTask(task: Task): Promise<void> {
    const all = await this.getTasks()
    all.push(task)
    await this.saveTasks(all)
  }

  async updateTask(task: Task): Promise<void> {
    const all = await this.getTasks()
    const idx = all.findIndex(t => t.id === task.id)
    if (idx >= 0) {
      task.updatedAt = Date.now()
      all[idx] = task
      await this.saveTasks(all)
    }
  }

  private resolveOriginalTaskId(taskId: string): string {
    const underscoreIdx = taskId.lastIndexOf('_')
    if (underscoreIdx > 0) {
      const suffix = taskId.substring(underscoreIdx + 1)
      if (suffix.length === 10 && suffix.charAt(4) === '-' && suffix.charAt(7) === '-') {
        return taskId.substring(0, underscoreIdx)
      }
    }
    return taskId
  }

  async softDeleteTask(taskId: string): Promise<void> {
    const originalId = this.resolveOriginalTaskId(taskId)
    const all = await this.getTasks()
    const idx = all.findIndex(t => t.id === originalId)
    if (idx >= 0) {
      all[idx].deleted = true
      all[idx].deletedAt = Date.now()
      all[idx].updatedAt = Date.now()
      await this.saveTasks(all)
    }
  }

  async restoreTask(taskId: string): Promise<void> {
    const originalId = this.resolveOriginalTaskId(taskId)
    const all = await this.getTasks()
    const idx = all.findIndex(t => t.id === originalId)
    if (idx >= 0) {
      all[idx].deleted = false
      all[idx].deletedAt = 0
      all[idx].updatedAt = Date.now()
      await this.saveTasks(all)
    }
  }

  async permanentlyDeleteTask(taskId: string): Promise<void> {
    const originalId = this.resolveOriginalTaskId(taskId)
    const all = await this.getTasks()
    const filtered = all.filter(t => t.id !== originalId)
    await this.saveTasks(filtered)
  }

  async getDeletedTasks(): Promise<Task[]> {
    return (await this.getTasks()).filter(t => t.deleted)
  }

  async getActiveTasks(): Promise<Task[]> {
    return (await this.getTasks()).filter(t => !t.deleted)
  }

  async getTaskById(taskId: string): Promise<Task | undefined> {
    const originalId = this.resolveOriginalTaskId(taskId)
    return (await this.getActiveTasks()).find(t => t.id === originalId)
  }

  async getTasksByDate(date: string): Promise<Task[]> {
    const direct = (await this.getActiveTasks()).filter(t => t.date === date)
    const recurring = await this.expandRecurringTasks(date)
    return [...direct, ...recurring]
      .sort((a, b) => a.startTime.localeCompare(b.startTime))
  }

  private async expandRecurringTasks(targetDate: string): Promise<Task[]> {
    const result: Task[] = []
    const all = await this.getActiveTasks()
    const target = this.parseLocalDate(targetDate)

    for (let i = 0; i < all.length; i++) {
      const t = all[i]
      if (t.repeatMode === RepeatMode.NONE) continue

      const origin = this.parseLocalDate(t.date)
      if (target.getTime() < origin.getTime()) continue
      if (target.getTime() === origin.getTime()) continue

      let match = false
      if (t.repeatMode === RepeatMode.DAILY) {
        match = true
      } else if (t.repeatMode === RepeatMode.WEEKLY) {
        match = origin.getDay() === target.getDay()
      } else if (t.repeatMode === RepeatMode.MONTHLY) {
        match = origin.getDate() === target.getDate()
      } else if (t.repeatMode === RepeatMode.YEARLY) {
        match = origin.getMonth() === target.getMonth() && origin.getDate() === target.getDate()
      }

      if (match) {
        const clone = new Task(t.title, targetDate, t.startTime, t.endTime)
        clone.id = t.id + '_' + targetDate
        clone.type = t.type
        clone.intensity = t.intensity
        clone.timeBlock = t.timeBlock
        clone.status = TaskStatus.TODO
        clone.notes = t.notes
        clone.prepareItems = t.prepareItems ? [...t.prepareItems] : []
        clone.subTasks = t.subTasks ? t.subTasks.map(s => {
          const st = new SubTask(s.title, clone.id)
          st.id = s.id
          st.completed = s.completed
          return st
        }) : []
        clone.repeatMode = RepeatMode.NONE
        clone.date = targetDate
        result.push(clone)
      }
    }
    return result
  }

  async cleanExpiredDeletedTasks(days: number = 3): Promise<void> {
    const all = await this.getTasks()
    const cutoff = Date.now() - days * 24 * 60 * 60 * 1000
    const cleaned = all.filter(t => !(t.deleted && t.deletedAt > 0 && t.deletedAt < cutoff))
    if (cleaned.length !== all.length) {
      await this.saveTasks(cleaned)
    }
  }

  // ===== Energy Records =====
  async getEnergyRecords(): Promise<EnergyRecord[]> {
    return this.get<EnergyRecord[]>(KEY_ENERGY, [])
  }

  async saveEnergyRecord(record: EnergyRecord): Promise<void> {
    const all = await this.getEnergyRecords()
    all.push(record)
    await this.put(KEY_ENERGY, all)
  }

  async getEnergyRecordsByDate(date: string): Promise<EnergyRecord[]> {
    return (await this.getEnergyRecords()).filter(r => r.date === date)
  }

  // ===== Mood Surveys =====
  async getMoodSurveys(): Promise<MoodSurveyRecord[]> {
    return this.get<MoodSurveyRecord[]>(KEY_MOOD, [])
  }

  async saveMoodSurvey(record: MoodSurveyRecord): Promise<void> {
    const all = await this.getMoodSurveys()
    all.push(record)
    await this.put(KEY_MOOD, all)
  }

  async getMoodSurveyCountByDate(date: string): Promise<number> {
    return (await this.getMoodSurveys()).filter(r => r.date === date).length
  }

  // ===== Focus Records =====
  async getFocusRecords(): Promise<FocusRecord[]> {
    return this.get<FocusRecord[]>(KEY_FOCUS, [])
  }

  async saveFocusRecord(record: FocusRecord): Promise<void> {
    const all = await this.getFocusRecords()
    all.push(record)
    await this.put(KEY_FOCUS, all)
  }

  async getTodayFocusMinutes(): Promise<number> {
    const today = formatDate(new Date())
    return (await this.getFocusRecords())
      .filter(r => {
        const localDate = formatDate(new Date(r.startTime))
        return localDate === today
      })
      .reduce((sum, r) => sum + r.actualMinutes, 0)
  }

  // ===== User Preferences =====
  async getUserPrefs(): Promise<UserPreferences> {
    return this.get<UserPreferences>(KEY_PREFS, new UserPreferences())
  }

  async saveUserPrefs(prefs: UserPreferences): Promise<void> {
    await this.put(KEY_PREFS, prefs)
  }

  // ===== Data Import/Export =====
  async exportAll(password?: string): Promise<string> {
    const tasks = await this.getTasks()
    const energyRecords = await this.getEnergyRecords()
    const moodSurveys = await this.getMoodSurveys()
    const focusRecords = await this.getFocusRecords()
    const userPrefs = await this.getUserPrefs()
    const courses = await this.getCourses()
    const courseState = await this.getCourseState()
    const plainJson = JSON.stringify({ tasks, energyRecords, moodSurveys, focusRecords, userPrefs, courses, courseState })
    if (password && password.length > 0) {
      return CryptoService.encryptForExport(plainJson, password)
    }
    return plainJson
  }

  async importAll(cipherStr: string, mode: 'merge' | 'overwrite', password?: string): Promise<void> {
    let plainStr: string
    if (password && password.length > 0) {
      plainStr = await CryptoService.decryptForImport(cipherStr, password)
    } else {
      plainStr = cipherStr
    }
    try {
      const raw = JSON.parse(plainStr) as Record<string, object>
      if (mode === 'overwrite') {
        if (raw.tasks) await this.saveTasks(raw.tasks as Task[])
        if (raw.energyRecords) await this.put(KEY_ENERGY, raw.energyRecords)
        if (raw.moodSurveys) await this.put(KEY_MOOD, raw.moodSurveys)
        if (raw.focusRecords) await this.put(KEY_FOCUS, raw.focusRecords)
        if (raw.userPrefs) await this.saveUserPrefs(raw.userPrefs as UserPreferences)
        if (raw.courses) await this.saveCourses(raw.courses as Course[])
        if (raw.courseState) await this.saveCourseState(raw.courseState as CourseScheduleState)
      } else {
        if (raw.tasks) {
          const existing = await this.getTasks()
          const existingIds = new Set(existing.map(t => t.id))
          const newTasks = (raw.tasks as Task[]).filter(t => !existingIds.has(t.id))
          for (let i = 0; i < newTasks.length; i++) {
            existing.push(newTasks[i])
          }
          await this.saveTasks(existing)
        }
      }
    } catch (e) {
      console.error('Import failed:', JSON.stringify(e))
      throw e
    }
  }

  // ===== Course Schedule =====
  async getCourseState(): Promise<CourseScheduleState> {
    const state = await this.get<CourseScheduleState>(KEY_COURSE_STATE, new CourseScheduleState())
    if (!state.timeSlots || state.timeSlots.length === 0) {
      state.timeSlots = DEFAULT_TIME_SLOTS.map(s => new TimeSlot(s.slotNumber, s.startTime, s.endTime))
    }
    return state
  }

  async saveCourseState(state: CourseScheduleState): Promise<void> {
    await this.put(KEY_COURSE_STATE, state)
  }

  async getCourses(): Promise<Course[]> {
    return this.get<Course[]>(KEY_COURSES, [])
  }

  async saveCourses(courses: Course[]): Promise<void> {
    await this.put(KEY_COURSES, courses)
  }

  async addCourse(course: Course): Promise<void> {
    const courses = await this.getCourses()
    courses.push(course)
    await this.saveCourses(courses)
  }

  async updateCourse(course: Course): Promise<void> {
    const courses = await this.getCourses()
    const idx = courses.findIndex(c => c.id === course.id)
    if (idx >= 0) {
      courses[idx] = course
      await this.saveCourses(courses)
    }
  }

  async deleteCourse(id: string): Promise<void> {
    const courses = (await this.getCourses()).filter(c => c.id !== id)
    await this.saveCourses(courses)
  }

  // ===== Terms agreement =====
  async hasAgreedToTerms(): Promise<boolean> {
    return this.get<boolean>(KEY_AGREED_TERMS, false)
  }

  async setAgreedToTerms(agreed: boolean): Promise<void> {
    await this.put(KEY_AGREED_TERMS, agreed)
  }

  // ===== Last Login Tracking =====
  async getLastLoginDate(): Promise<string> {
    return this.get<string>(KEY_LAST_LOGIN_DATE, '')
  }

  async setLastLoginDate(date: string): Promise<void> {
    await this.put(KEY_LAST_LOGIN_DATE, date)
  }

  async shouldShowYesterdaySummary(): Promise<boolean> {
    return this.get<boolean>(KEY_SHOW_YESTERDAY_SUMMARY, false)
  }

  async setShouldShowYesterdaySummary(show: boolean): Promise<void> {
    await this.put(KEY_SHOW_YESTERDAY_SUMMARY, show)
  }

  async getStoredYesterdaySummary(): Promise<YesterdaySummary> {
    return this.get<YesterdaySummary>(KEY_YESTERDAY_SUMMARY, new YesterdaySummary('', 0, 0, 0))
  }

  async setStoredYesterdaySummary(summary: YesterdaySummary): Promise<void> {
    await this.put(KEY_YESTERDAY_SUMMARY, summary)
  }

  // ===== Task Status Advancement =====
  async advanceTaskStatus(taskId: string): Promise<boolean> {
    const originalId = this.resolveOriginalTaskId(taskId)
    const all = await this.getActiveTasks()
    const idx = all.findIndex(t => t.id === originalId)
    if (idx < 0) return false
    const statusOrder = [TaskStatus.TODO, TaskStatus.STARTED, TaskStatus.MOSTLY, TaskStatus.DONE]
    const currentIdx = statusOrder.indexOf(all[idx].status)
    all[idx].status = statusOrder[(currentIdx + 1) % statusOrder.length]
    all[idx].updatedAt = Date.now()
    await this.saveTasks(all)
    return true
  }

  // ===== Yesterday Summary =====
  async getYesterdaySummary(yesterday: string): Promise<YesterdaySummary> {
    const tasks = await this.getTasksByDate(yesterday)
    let totalTasks = 0
    let completedTasks = 0
    for (let i = 0; i < tasks.length; i++) {
      if (!tasks[i].deleted) {
        totalTasks++
        if (tasks[i].status === TaskStatus.DONE) {
          completedTasks++
        }
      }
    }

    let focusMinutes = 0
    const allFocus = await this.getFocusRecords()
    for (let i = 0; i < allFocus.length; i++) {
      const r = allFocus[i]
      if (!r.startTime) continue
      const localDate = formatDate(new Date(r.startTime))
      if (localDate === yesterday) {
        focusMinutes += r.actualMinutes
      }
    }

    return new YesterdaySummary(yesterday, totalTasks, completedTasks, focusMinutes)
  }

  async clearAll(): Promise<void> {
    if (!this.pref) return
    try {
      this.pref.clearSync()
      this.pref.flush()
    } catch (e) {
      console.error('Clear all failed:', JSON.stringify(e))
    }
  }

  // ===== Conflict Detection =====
  async checkTaskConflict(date: string, startTime: string, endTime: string, excludeId?: string): Promise<ConflictResult> {
    if (!startTime || !endTime) return { hasConflict: false, conflictWith: '' }
    const tasks = await this.getTasksByDate(date)
    const startMin = this.timeToMinutes(startTime)
    const endMin = this.timeToMinutes(endTime)

    for (let i = 0; i < tasks.length; i++) {
      const t = tasks[i]
      if (excludeId && t.id === excludeId) continue
      if (!t.startTime || !t.endTime) continue
      const tStart = this.timeToMinutes(t.startTime)
      const tEnd = this.timeToMinutes(t.endTime)
      if (startMin < tEnd && endMin > tStart) {
        return { hasConflict: true, conflictWith: t.title }
      }
    }
    return { hasConflict: false, conflictWith: '' }
  }

  async checkCourseConflict(state: CourseScheduleState, newCourse: Course, excludeId?: string): Promise<ConflictResult> {
    const courses = await this.getCourses()
    for (let i = 0; i < courses.length; i++) {
      const c = courses[i]
      if (excludeId && c.id === excludeId) continue
      if (c.dayOfWeek !== newCourse.dayOfWeek) continue
      if (newCourse.endWeek < c.startWeek || newCourse.startWeek > c.endWeek) continue
      if (newCourse.weekType === WeekType.ODD && c.weekType === WeekType.EVEN) continue
      if (newCourse.weekType === WeekType.EVEN && c.weekType === WeekType.ODD) continue
      const newEnd = newCourse.startSlot + newCourse.slotCount - 1
      const cEnd = c.startSlot + c.slotCount - 1
      if (newCourse.startSlot <= cEnd && newEnd >= c.startSlot) {
        return { hasConflict: true, conflictWith: c.name }
      }
    }
    return { hasConflict: false, conflictWith: '' }
  }

  private timeToMinutes(time: string): number {
    const parts = time.split(':').map(Number)
    return parts[0] * 60 + parts[1]
  }

  // ===== Focus Stats Aggregation =====
  async getFocusStatsByRange(startDate: string, endDate: string): Promise<FocusStatsResult> {
    const all = await this.getFocusRecords()
    const start = this.parseLocalDate(startDate).getTime()
    const end = this.parseLocalDate(endDate).getTime() + 24 * 60 * 60 * 1000
    let totalMinutes = 0
    let sessions = 0
    let completedSessions = 0
    const dailyData: Record<string, number> = {}

    for (let i = 0; i < all.length; i++) {
      const r = all[i]
      if (!r.startTime) continue
      const rTime = new Date(r.startTime).getTime()
      if (rTime >= start && rTime < end) {
        totalMinutes += r.actualMinutes
        sessions++
        if (r.completed) completedSessions++
        const dateStr = formatDate(new Date(r.startTime))
        dailyData[dateStr] = (dailyData[dateStr] || 0) + r.actualMinutes
      }
    }
    return { totalMinutes, sessions, completedSessions, dailyData }
  }

  async getFocusWeeklyStats(weeks: number = 4): Promise<FocusWeeklyStat[]> {
    const result: FocusWeeklyStat[] = []
    const now = new Date()
    for (let w = weeks - 1; w >= 0; w--) {
      const weekEnd = new Date(now)
      weekEnd.setDate(weekEnd.getDate() - w * 7)
      const weekStart = new Date(weekEnd)
      weekStart.setDate(weekStart.getDate() - 6)
      const startStr = formatDate(weekStart)
      const endStr = formatDate(weekEnd)
      const stats = await this.getFocusStatsByRange(startStr, endStr)
      result.push({
        label: `${weekStart.getMonth() + 1}/${weekStart.getDate()}-${weekEnd.getMonth() + 1}/${weekEnd.getDate()}`,
        totalMinutes: stats.totalMinutes,
        sessions: stats.sessions
      })
    }
    return result
  }

  async getFocusDailyStats(days: number = 7): Promise<FocusDailyStat[]> {
    const result: FocusDailyStat[] = []
    const now = new Date()
    for (let d = days - 1; d >= 0; d--) {
      const date = new Date(now)
      date.setDate(date.getDate() - d)
      const dateStr = formatDate(date)
      const stats = await this.getFocusStatsByRange(dateStr, dateStr)
      result.push({
        label: `${date.getMonth() + 1}/${date.getDate()}`,
        minutes: stats.totalMinutes
      })
    }
    return result
  }

  // ===== Face Mood Records =====
  async getFaceMoodRecords(): Promise<FaceMoodRecord[]> {
    return this.get<FaceMoodRecord[]>(KEY_FACE_MOOD, [])
  }

  async saveFaceMoodRecord(record: FaceMoodRecord): Promise<void> {
    const all = await this.getFaceMoodRecords()
    all.push(record)
    await this.put(KEY_FACE_MOOD, all)
  }

  // ===== Mood Prompt Tracking =====
  async getLastMoodPromptDate(): Promise<string> {
    return this.get<string>(KEY_LAST_MOOD_PROMPT, '')
  }

  async setLastMoodPromptDate(date: string): Promise<void> {
    await this.put(KEY_LAST_MOOD_PROMPT, date)
  }

  async hasMoodRecordToday(): Promise<boolean> {
    const today = formatDate(new Date())
    const surveys = await this.getMoodSurveys()
    const faceRecords = await this.getFaceMoodRecords()
    return surveys.some(r => r.date === today) || faceRecords.some(r => r.date === today)
  }

  // ===== Utils =====
  private parseLocalDate(dateStr: string): Date {
    const parts = dateStr.split('-').map(Number)
    return new Date(parts[0], parts[1] - 1, parts[2])
  }
}

export const dataStore = new DataStore()
