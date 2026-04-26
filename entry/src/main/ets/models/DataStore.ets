import { preferences } from '@kit.ArkData'
import {
  Task, SubTask, EnergyRecord, MoodSurveyRecord, FocusRecord, UserPreferences, TaskStatus, RepeatMode
} from './DataModels'
import { Course, TimeSlot, CourseScheduleState, DEFAULT_TIME_SLOTS } from './CourseModels'

const KEY_TASKS = 'star_tasks'
const KEY_ENERGY = 'star_energy_records'
const KEY_MOOD = 'star_mood_surveys'
const KEY_FOCUS = 'star_focus_records'
const KEY_PREFS = 'star_user_prefs'
const KEY_COURSES = 'star_courses'
const KEY_COURSE_STATE = 'star_course_state'
const KEY_AGREED_TERMS = 'star_agreed_terms'

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

  softDeleteTask(taskId: string): void {
    const all = this.getTasks()
    const idx = all.findIndex(t => t.id === taskId)
    if (idx >= 0) {
      all[idx].deleted = true
      all[idx].deletedAt = Date.now()
      all[idx].updatedAt = Date.now()
      this.saveTasks(all)
    }
  }

  restoreTask(taskId: string): void {
    const all = this.getTasks()
    const idx = all.findIndex(t => t.id === taskId)
    if (idx >= 0) {
      all[idx].deleted = false
      all[idx].deletedAt = 0
      all[idx].updatedAt = Date.now()
      this.saveTasks(all)
    }
  }

  permanentlyDeleteTask(taskId: string): void {
    const all = this.getTasks()
    const filtered = all.filter(t => t.id !== taskId)
    this.saveTasks(filtered)
  }

  getDeletedTasks(): Task[] {
    return this.getTasks().filter(t => t.deleted)
  }

  getActiveTasks(): Task[] {
    return this.getTasks().filter(t => !t.deleted)
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
        clone.subTasks = t.subTasks ? t.subTasks.map(s => new SubTask(s.title, clone.id)) : []
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
    const today = this.formatDate(new Date())
    return this.getFocusRecords()
      .filter(r => r.startTime.startsWith(today))
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

  clearAll(): void {
    if (!this.pref) return
    try {
      this.pref.clearSync()
      this.pref.flush()
    } catch (e) {
      console.error('Clear all failed:', JSON.stringify(e))
    }
  }

  // ===== Utils =====
  private formatDate(d: Date): string {
    const y = d.getFullYear()
    const m = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${y}-${m}-${day}`
  }

  private parseLocalDate(dateStr: string): Date {
    const [y, m, d] = dateStr.split('-').map(Number)
    return new Date(y, m - 1, d)
  }
}

export const dataStore = new DataStore()
