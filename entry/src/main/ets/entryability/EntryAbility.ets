import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { storage } from '../utils/StorageUtil';
import { Schedule, SubTask } from '../models/ScheduleModel';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // Initialize local storage
    storage.init(this.context);

    // Seed sample data on first launch
    this.seedSampleData();

    windowStage.loadContent('pages/Index', (err) => {
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
    const existing = storage.getSchedules();
    if (existing.length > 0) {
      return;
    }

    const today = new Date();
    const y = today.getFullYear();
    const m = String(today.getMonth() + 1).padStart(2, '0');
    const d = String(today.getDate()).padStart(2, '0');
    const dateStr = `${y}-${m}-${d}`;

    const s1 = new Schedule('吃早餐', dateStr, '08:00', '08:30');
    s1.colorTag = 'calm';
    s1.prepareItems = ['拿出碗', '准备牛奶'];
    s1.subTasks = [new SubTask('热牛奶'), new SubTask('拿出面包'), new SubTask('坐在餐桌前')];

    const s2 = new Schedule('晨间散步', dateStr, '09:00', '09:30');
    s2.colorTag = 'energy';
    s2.prepareItems = ['穿运动鞋', '带钥匙'];

    const s3 = new Schedule('阅读时间', dateStr, '10:00', '11:00');
    s3.colorTag = 'focus';
    s3.notes = '选择一本喜欢的书，不用读完';
    s3.subTasks = [new SubTask('找一本书'), new SubTask('坐在舒服的位置'), new SubTask('读 20 分钟')];

    storage.saveSchedules([s1, s2, s3]);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Sample data seeded');
  }
}
