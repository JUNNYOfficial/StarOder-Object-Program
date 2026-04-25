import { preferences } from '@kit.ArkData'
import { Schedule } from '../models/ScheduleModel'
import { AppSettings } from '../models/SettingsModel'

const SCHEDULES_KEY = 'star_schedules'
const SETTINGS_KEY = 'star_settings'

class StorageUtil {
  private pref: preferences.Preferences | null = null

  async init(context: Context) {
    try {
      this.pref = preferences.getPreferencesSync(context, { name: 'star_order_db' })
    } catch (e) {
      console.error('Storage init failed:', JSON.stringify(e))
    }
  }

  // Schedules
  saveSchedules(schedules: Schedule[]): void {
    if (!this.pref) return
    try {
      this.pref.putSync(SCHEDULES_KEY, JSON.stringify(schedules))
      this.pref.flush()
    } catch (e) {
      console.error('Save schedules failed:', JSON.stringify(e))
    }
  }

  getSchedules(): Schedule[] {
    if (!this.pref) return []
    try {
      const raw = this.pref.getSync(SCHEDULES_KEY, '[]') as string
      return JSON.parse(raw) as Schedule[]
    } catch (e) {
      console.error('Get schedules failed:', JSON.stringify(e))
      return []
    }
  }

  // Settings
  saveSettings(settings: AppSettings): void {
    if (!this.pref) return
    try {
      this.pref.putSync(SETTINGS_KEY, JSON.stringify(settings))
      this.pref.flush()
    } catch (e) {
      console.error('Save settings failed:', JSON.stringify(e))
    }
  }

  getSettings(): AppSettings {
    if (!this.pref) return new AppSettings()
    try {
      const raw = this.pref.getSync(SETTINGS_KEY, '') as string
      if (!raw) return new AppSettings()
      return JSON.parse(raw) as AppSettings
    } catch (e) {
      console.error('Get settings failed:', JSON.stringify(e))
      return new AppSettings()
    }
  }
}

export const storage = new StorageUtil()
