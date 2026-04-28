import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { formBindingData, formProvider } from '@kit.FormKit';
import { dataStore } from '../models/DataStore';
import { Task, SubTask, TaskType, TaskIntensity, TimeBlock, TaskStatus } from '../models/DataModels';
import { addDays, formatDate } from '../utils/DateUtils';

interface TaskWithMinutes {
  task: Task
  minutes: number
}

interface FormUpdateData {
  todayCount: number
  nextTask: string
  nextTime: string
}

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private launchWantUri: string = 'pages/Index'

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    await dataStore.init(this.context);
    await this.handleWant(want);
  }

  async onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onNewWant');
    await this.handleWant(want);
  }

  private async handleWant(want: Want): Promise<void> {
    if (want.parameters) {
      const urlValue = want.parameters['url']
      if (urlValue) {
        this.launchWantUri = String(urlValue)
      }
    }
    // Handle form lifecycle
    const formId = want.parameters?.['formId'] as string
    const formConfig = want.parameters?.['formConfig'] as string
    if (formId && formConfig) {
      await this.updateFormData(formId)
    }
  }

  private async updateFormData(formId: string): Promise<void> {
    try {
      const today = formatDate(new Date())
      const tasks = await dataStore.getTasksByDate(today)
      const todoCount = tasks.filter(t => t.status !== TaskStatus.DONE).length

      let nextTask = ''
      let nextTime = ''
      const now = new Date()
      const nowMinutes = now.getHours() * 60 + now.getMinutes()
      const upcoming: TaskWithMinutes[] = tasks
        .filter(t => t.startTime)
        .map(t => {
          const parts = (t.startTime as string).split(':').map(Number)
          const item: TaskWithMinutes = { task: t, minutes: parts[0] * 60 + parts[1] }
          return item
        })
        .filter(t => t.minutes > nowMinutes)
        .sort((a, b) => a.minutes - b.minutes)

      if (upcoming.length > 0) {
        nextTask = upcoming[0].task.title
        nextTime = upcoming[0].task.startTime || ''
      } else if (tasks.length > 0) {
        nextTask = tasks[0].title
        nextTime = tasks[0].startTime || ''
      }

      const formData: FormUpdateData = {
        todayCount: todoCount,
        nextTask: nextTask,
        nextTime: nextTime
      }
      const bindingData = formBindingData.createFormBindingData(formData)
      formProvider.updateForm(formId, bindingData)
        .then(() => {
          hilog.info(DOMAIN, 'testTag', 'Form updated successfully')
        })
        .catch((err: Error) => {
          hilog.error(DOMAIN, 'testTag', 'Form update failed: %{public}s', JSON.stringify(err))
        })
    } catch (e) {
      hilog.error(DOMAIN, 'testTag', 'Update form data failed: %{public}s', JSON.stringify(e))
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    await this.checkYesterdaySummary();
    await this.seedSampleData();

    windowStage.loadContent(this.launchWantUri, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  private async checkYesterdaySummary(): Promise<void> {
    // 先清理旧的，避免同一天重复显示
    await dataStore.setShouldShowYesterdaySummary(false)

    const today = formatDate(new Date())
    const lastLogin = await dataStore.getLastLoginDate()

    // 有上次登录记录且跨天了，显示昨天完成情况
    if (lastLogin && lastLogin < today) {
      const yesterday = addDays(today, -1)
      const summary = await dataStore.getYesterdaySummary(yesterday)
      // 只有昨天有数据才显示
      if (summary.totalTasks > 0 || summary.focusMinutes > 0) {
        await dataStore.setStoredYesterdaySummary(summary)
        await dataStore.setShouldShowYesterdaySummary(true)
      }
    }

    await dataStore.setLastLoginDate(today)
  }

  private async seedSampleData(): Promise<void> {
    if ((await dataStore.getActiveTasks()).length > 0) {
      return;
    }

    const today = formatDate(new Date());

    const s1 = new Task('吃早餐', today, '08:00', '08:30');
    s1.type = TaskType.HOME;
    s1.intensity = TaskIntensity.LOW;
    s1.timeBlock = TimeBlock.MORNING;
    s1.status = TaskStatus.DONE;
    s1.prepareItems = ['拿出碗', '准备牛奶'];
    s1.subTasks = [
      new SubTask('热牛奶', s1.id),
      new SubTask('拿出面包', s1.id),
      new SubTask('坐在餐桌前', s1.id)
    ];
    s1.subTasks.forEach(st => st.completed = true);

    const s2 = new Task('晨间散步', today, '09:00', '09:30');
    s2.type = TaskType.EXERCISE;
    s2.intensity = TaskIntensity.LOW;
    s2.timeBlock = TimeBlock.MORNING;
    s2.status = TaskStatus.STARTED;
    s2.prepareItems = ['穿运动鞋', '带钥匙'];

    const s3 = new Task('阅读时间', today, '10:00', '11:00');
    s3.type = TaskType.THINK;
    s3.intensity = TaskIntensity.MEDIUM;
    s3.timeBlock = TimeBlock.MORNING;
    s3.status = TaskStatus.TODO;
    s3.notes = '选择一本喜欢的书，不用读完';
    s3.subTasks = [
      new SubTask('找一本书', s3.id),
      new SubTask('坐在舒服的位置', s3.id),
      new SubTask('读 20 分钟', s3.id)
    ];

    const s4 = new Task('准备午餐', today, '11:30', '12:30');
    s4.type = TaskType.HOME;
    s4.intensity = TaskIntensity.MEDIUM;
    s4.timeBlock = TimeBlock.AFTERNOON;
    s4.status = TaskStatus.PAUSED;

    await dataStore.saveTasks([s1, s2, s3, s4]);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Sample data seeded');
  }

}
