import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { dataStore } from '../models/DataStore';
import { Task, SubTask, TaskType, TaskIntensity, TimeBlock, TaskStatus } from '../models/DataModels';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private launchWantUri: string = 'pages/Index'

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    this.extractLaunchUrl(want);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onNewWant');
    this.extractLaunchUrl(want);
  }

  private extractLaunchUrl(want: Want): void {
    if (want.parameters) {
      const urlValue = want.parameters['url']
      if (urlValue) {
        this.launchWantUri = String(urlValue)
      }
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    dataStore.init(this.context);
    this.seedSampleData();

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

  private seedSampleData(): void {
    if (dataStore.getActiveTasks().length > 0) {
      return;
    }

    const today = this.formatDate(new Date());

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

    dataStore.saveTasks([s1, s2, s3, s4]);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Sample data seeded');
  }

  private formatDate(d: Date): string {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${day}`;
  }
}
