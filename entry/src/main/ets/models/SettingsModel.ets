export class AppSettings {
  highContrast: boolean
  largeText: boolean
  reduceAnimations: boolean
  showPrepareHints: boolean
  autoBreakTasks: boolean

  constructor() {
    this.highContrast = false
    this.largeText = false
    this.reduceAnimations = true
    this.showPrepareHints = true
    this.autoBreakTasks = false
  }
}
