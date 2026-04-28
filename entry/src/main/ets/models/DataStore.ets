import { preferences } from '@kit.ArkData'
import {
  Task, SubTask, EnergyRecord, MoodSurveyRecord, FocusRecord, UserPreferences, TaskStatus, RepeatMode, YesterdaySummary, FaceMoodRecord
} from './DataModels'
import { Course, TimeSlot, CourseScheduleState, DEFAULT_TIME_SLOTS, WeekType } from './CourseModels'
import { formatDate } from '../utils/DateUtils'

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

class DataStore {
  private pref: preferences.Preferences | null = null

  init(context: Context): void {
    try {
      this.pref = preferences.getPreferencesSync(context, { name: 'star_order_db_v2' })
      this.cleanExpiredDeletedTasks()
    } catch (e) {
      console.error('DataStore init failed:', JSON.stringify(e))
    }
  }

  // ===== Generic helpers =====
  put<T>(key: string, value: T): void {
    if (!this.pref) return
    try {
      this.pref.putSync(key, JSON.stringify(value))
      this.pref.flush()
    } catch (e) {
      console.error(`Save ${key} failed:`, JSON.stringify(e))
    }
  }

  get<T>(key: string, defaultValue: T): T {
    if (!this.pref) return defaultValue
    try {
      const raw = this.pref.getSync(key, '') as string
      if (!raw) return defaultValue
      return JSON.parse(raw) as T
    } catch (e) {
      console.error(`Get ${key} failed:`, JSON.stringify(e))
      return defaultValue
    }
  }

  // ===== Tasks =====
  getTasks(): Task[] {
    return this.get<Task[]>(KEY_TASKS, [])
  }

  saveTasks(tasks: Task[]): void {
    this.put(KEY_TASKS, tasks)
  }

  syncExternalTasks(newTasks: Task[], source: string): SyncExternalTasksResult {
    const all = this.getTasks()
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
    this.saveTasks(all)
    const result: SyncExternalTasksResult = { added: added, updated: updated }
    return result
  }

  addTask(task: Task): void {
    const all = this.getTasks()
    all.push(task)
    this.saveTasks(all)
  }

  updateTask(task: Task): void {
    const all = this.getTasks()
    const idx = all.findIndex(t => t.id === task.id)
    if (idx >= 0) {
      task.updatedAt = Date.now()
      all[idx] = task
      this.saveTasks(all)
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

  softDeleteTask(taskId: string): void {
    const originalId = this.resolveOriginalTaskId(taskId)
    const all = this.getTasks()
    const idx = all.findIndex(t => t.id === originalId)
    if (idx >= 0) {
      all[idx].deleted = true
      all[idx].deletedAt = Date.now()
      all[idx].updatedAt = Date.now()
      this.saveTasks(all)
    }
  }

  restoreTask(taskId: string): void {
    const originalId = this.resolveOriginalTaskId(taskId)
    const all = this.getTasks()
    const idx = all.findIndex(t => t.id === originalId)
    if (idx >= 0) {
      all[idx].deleted = false
      all[idx].deletedAt = 0
      all[idx].updatedAt = Date.now()
      this.saveTasks(all)
    }
  }

  permanentlyDeleteTask(taskId: string): void {
    const originalId = this.resolveOriginalTaskId(taskId)
    const all = this.getTasks()
    const filtered = all.filter(t => t.id !== originalId)
    this.saveTasks(filtered)
  }

  getDeletedTasks(): Task[] {
    return this.getTasks().filter(t => t.deleted)
  }

  getActiveTasks(): Task[] {
    return this.getTasks().filter(t => !t.deleted)
  }

  getTaskById(taskId: string): Task | undefined {
    const originalId = this.resolveOriginalTaskId(taskId)
    return this.getActiveTasks().find(t => t.id === originalId)
  }

  getTasksByDate(date: string): Task[] {
    const direct = this.getActiveTasks().filter(t => t.date === date)
    const recurring = this.expandRecurringTasks(date)
    return [...direct, ...recurring]
      .sort((a, b) => a.startTime.localeCompare(b.startTime))
  }

  private expandRecurringTasks(targetDate: string): Task[] {
    const result: Task[] = []
    const all = this.getActiveTasks()
    const target = this.parseLocalDate(targetDate)

    for (let i = 0; i < all.length; i++) {
      const t = all[i]
      if (t.repeatMode === RepeatMode.NONE) continue

      const origin = this.parseLocalDate(t.date)
      if (target.getTime() < origin.getTime()) continue
      if (target.getTime() === origin.getTime()) continue // already included as direct task

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

  cleanExpiredDeletedTasks(days: number = 3): void {
    const all = this.getTasks()
    const cutoff = Date.now() - days * 24 * 60 * 60 * 1000
    const cleaned = all.filter(t => !(t.deleted && t.deletedAt > 0 && t.deletedAt < cutoff))
    if (cleaned.length !== all.length) {
      this.saveTasks(cleaned)
    }
  }

  // ===== Energy Records =====
  getEnergyRecords(): EnergyRecord[] {
    return this.get<EnergyRecord[]>(KEY_ENERGY, [])
  }

  saveEnergyRecord(record: EnergyRecord): void {
    const all = this.getEnergyRecords()
    all.push(record)
    this.put(KEY_ENERGY, all)
  }

  getEnergyRecordsByDate(date: string): EnergyRecord[] {
    return this.getEnergyRecords().filter(r => r.date === date)
  }

  // ===== Mood Surveys =====
  getMoodSurveys(): MoodSurveyRecord[] {
    return this.get<MoodSurveyRecord[]>(KEY_MOOD, [])
  }

  saveMoodSurvey(record: MoodSurveyRecord): void {
    const all = this.getMoodSurveys()
    all.push(record)
    this.put(KEY_MOOD, all)
  }

  getMoodSurveyCountByDate(date: string): number {
    return this.getMoodSurveys().filter(r => r.date === date).length
  }

  // ===== Focus Records =====
  getFocusRecords(): FocusRecord[] {
    return this.get<FocusRecord[]>(KEY_FOCUS, [])
  }

  saveFocusRecord(record: FocusRecord): void {
    const all = this.getFocusRecords()
    all.push(record)
    this.put(KEY_FOCUS, all)
  }

  getTodayFocusMinutes(): number {
    const today = formatDate(new Date())
    return this.getFocusRecords()
      .filter(r => {
        const localDate = formatDate(new Date(r.startTime))
        return localDate === today
      })
      .reduce((sum, r) => sum + r.actualMinutes, 0)
  }

  // ===== User Preferences =====
  getUserPrefs(): UserPreferences {
    return this.get<UserPreferences>(KEY_PREFS, new UserPreferences())
  }

  saveUserPrefs(prefs: UserPreferences): void {
    this.put(KEY_PREFS, prefs)
  }

  // ===== Data Import/Export =====
  exportAll(): string {
    const tasks = this.getTasks()
    const energyRecords = this.getEnergyRecords()
    const moodSurveys = this.getMoodSurveys()
    const focusRecords = this.getFocusRecords()
    const userPrefs = this.getUserPrefs()
    return JSON.stringify({ tasks, energyRecords, moodSurveys, focusRecords, userPrefs })
  }

  importAll(jsonStr: string, mode: 'merge' | 'overwrite'): void {
    try {
      const raw = JSON.parse(jsonStr) as Record<string, object>
      if (mode === 'overwrite') {
        if (raw.tasks) this.saveTasks(raw.tasks as Task[])
        if (raw.energyRecords) this.put(KEY_ENERGY, raw.energyRecords)
        if (raw.moodSurveys) this.put(KEY_MOOD, raw.moodSurveys)
        if (raw.focusRecords) this.put(KEY_FOCUS, raw.focusRecords)
        if (raw.userPrefs) this.saveUserPrefs(raw.userPrefs as UserPreferences)
      } else {
        if (raw.tasks) {
          const existing = this.getTasks()
          const existingIds = new Set(existing.map(t => t.id))
          const newTasks = (raw.tasks as Task[]).filter(t => !existingIds.has(t.id))
          for (let i = 0; i < newTasks.length; i++) {
            existing.push(newTasks[i])
          }
          this.saveTasks(existing)
        }
      }
    } catch (e) {
      console.error('Import failed:', JSON.stringify(e))
    }
  }

  // ===== Course Schedule =====
  getCourseState(): CourseScheduleState {
    const state = this.get<CourseScheduleState>(KEY_COURSE_STATE, new CourseScheduleState())
    if (!state.timeSlots || state.timeSlots.length === 0) {
      state.timeSlots = DEFAULT_TIME_SLOTS.map(s => new TimeSlot(s.slotNumber, s.startTime, s.endTime))
    }
    return state
  }

  saveCourseState(state: CourseScheduleState): void {
    this.put(KEY_COURSE_STATE, state)
  }

  getCourses(): Course[] {
    return this.get<Course[]>(KEY_COURSES, [])
  }

  saveCourses(courses: Course[]): void {
    this.put(KEY_COURSES, courses)
  }

  addCourse(course: Course): void {
    const courses = this.getCourses()
    courses.push(course)
    this.saveCourses(courses)
  }

  updateCourse(course: Course): void {
    const courses = this.getCourses()
    const idx = courses.findIndex(c => c.id === course.id)
    if (idx >= 0) {
      courses[idx] = course
      this.saveCourses(courses)
    }
  }

  deleteCourse(id: string): void {
    const courses = this.getCourses().filter(c => c.id !== id)
    this.saveCourses(courses)
  }

  // ===== Terms agreement =====
  hasAgreedToTerms(): boolean {
    return this.get<boolean>(KEY_AGREED_TERMS, false)
  }

  setAgreedToTerms(agreed: boolean): void {
    this.put(KEY_AGREED_TERMS, agreed)
  }

  // ===== Last Login Tracking =====
  getLastLoginDate(): string {
    return this.get<string>(KEY_LAST_LOGIN_DATE, '')
  }

  setLastLoginDate(date: string): void {
    this.put(KEY_LAST_LOGIN_DATE, date)
  }

  shouldShowYesterdaySummary(): boolean {
    return this.get<boolean>(KEY_SHOW_YESTERDAY_SUMMARY, false)
  }

  setShouldShowYesterdaySummary(show: boolean): void {
    this.put(KEY_SHOW_YESTERDAY_SUMMARY, show)
  }

  getStoredYesterdaySummary(): YesterdaySummary {
    return this.get<YesterdaySummary>(KEY_YESTERDAY_SUMMARY, new YesterdaySummary('', 0, 0, 0))
  }

  setStoredYesterdaySummary(summary: YesterdaySummary): void {
    this.put(KEY_YESTERDAY_SUMMARY, summary)
  }

  // ===== Task Status Advancement =====
  advanceTaskStatus(taskId: string): boolean {
    const originalId = this.resolveOriginalTaskId(taskId)
    const all = this.getActiveTasks()
    const idx = all.findIndex(t => t.id === originalId)
    if (idx < 0) return false
    const statusOrder = [TaskStatus.TODO, TaskStatus.STARTED, TaskStatus.MOSTLY, TaskStatus.DONE]
    const currentIdx = statusOrder.indexOf(all[idx].status)
    all[idx].status = statusOrder[(currentIdx + 1) % statusOrder.length]
    all[idx].updatedAt = Date.now()
    this.saveTasks(all)
    return true
  }

  // ===== Face Mood Records =====
  getFaceMoodRecords(): FaceMoodRecord[] {
    return this.get<FaceMoodRecord[]>(KEY_FACE_MOOD, [])
  }

  saveFaceMoodRecord(record: FaceMoodRecord): void {
    const all = this.getFaceMoodRecords()
    all.push(record)
    this.put(KEY_FACE_MOOD, all)
  }

  // ===== Mood Prompt Tracking =====
  getLastMoodPromptDate(): string {
    return this.get<string>(KEY_LAST_MOOD_PROMPT, '')
  }

  setLastMoodPromptDate(date: string): void {
    this.put(KEY_LAST_MOOD_PROMPT, date)
  }

  hasMoodRecordToday(): boolean {
    const today = formatDate(new Date())
    const surveys = this.getMoodSurveys()
    const faceRecords = this.getFaceMoodRecords()
    return surveys.some(r => r.date === today) || faceRecords.some(r => r.date === today)
  }

  // ===== Yesterday Summary =====
  getYesterdaySummary(yesterday: string): YesterdaySummary {
    const tasks = this.getTasksByDate(yesterday)
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
    const allFocus = this.getFocusRecords()
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

  clearAll(): void {
    if (!this.pref) return
    try {
      this.pref.clearSync()
      this.pref.flush()
    } catch (e) {
      console.error('Clear all failed:', JSON.stringify(e))
    }
  }

  // ===== Conflict Detection =====
  checkTaskConflict(date: string, startTime: string, endTime: string, excludeId?: string): ConflictResult {
    if (!startTime || !endTime) return { hasConflict: false, conflictWith: '' }
    const tasks = this.getTasksByDate(date)
    const startMin = this.timeToMinutes(startTime)
    const endMin = this.timeToMinutes(endTime)

    for (let i = 0; i < tasks.length; i++) {
      const t = tasks[i]
      if (excludeId && t.id === excludeId) continue
      if (!t.startTime || !t.endTime) continue
      const tStart = this.timeToMinutes(t.startTime)
      const tEnd = this.timeToMinutes(t.endTime)
      // 有重叠即冲突
      if (startMin < tEnd && endMin > tStart) {
        return { hasConflict: true, conflictWith: t.title }
      }
    }
    return { hasConflict: false, conflictWith: '' }
  }

  checkCourseConflict(state: CourseScheduleState, newCourse: Course, excludeId?: string): ConflictResult {
    const courses = this.getCourses()
    for (let i = 0; i < courses.length; i++) {
      const c = courses[i]
      if (excludeId && c.id === excludeId) continue
      if (c.dayOfWeek !== newCourse.dayOfWeek) continue
      // 周次范围有交集
      if (newCourse.endWeek < c.startWeek || newCourse.startWeek > c.endWeek) continue
      // 单双周过滤：单周课程与双周课程不冲突
      if (newCourse.weekType === WeekType.ODD && c.weekType === WeekType.EVEN) continue
      if (newCourse.weekType === WeekType.EVEN && c.weekType === WeekType.ODD) continue
      // 节次有重叠
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
  getFocusStatsByRange(startDate: string, endDate: string): FocusStatsResult {
    const all = this.getFocusRecords()
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

  getFocusWeeklyStats(weeks: number = 4): FocusWeeklyStat[] {
    const result: FocusWeeklyStat[] = []
    const now = new Date()
    for (let w = weeks - 1; w >= 0; w--) {
      const weekEnd = new Date(now)
      weekEnd.setDate(weekEnd.getDate() - w * 7)
      const weekStart = new Date(weekEnd)
      weekStart.setDate(weekStart.getDate() - 6)
      const startStr = formatDate(weekStart)
      const endStr = formatDate(weekEnd)
      const stats = this.getFocusStatsByRange(startStr, endStr)
      result.push({
        label: `${weekStart.getMonth() + 1}/${weekStart.getDate()}-${weekEnd.getMonth() + 1}/${weekEnd.getDate()}`,
        totalMinutes: stats.totalMinutes,
        sessions: stats.sessions
      })
    }
    return result
  }

  getFocusDailyStats(days: number = 7): FocusDailyStat[] {
    const result: FocusDailyStat[] = []
    const now = new Date()
    for (let d = days - 1; d >= 0; d--) {
      const date = new Date(now)
      date.setDate(date.getDate() - d)
      const dateStr = formatDate(date)
      const stats = this.getFocusStatsByRange(dateStr, dateStr)
      result.push({
        label: `${date.getMonth() + 1}/${date.getDate()}`,
        minutes: stats.totalMinutes
      })
    }
    return result
  }

  // ===== Utils =====
  private parseLocalDate(dateStr: string): Date {
    const parts = dateStr.split('-').map(Number)
    return new Date(parts[0], parts[1] - 1, parts[2])
  }
}

export const dataStore = new DataStore()
