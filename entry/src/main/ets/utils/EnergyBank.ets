import { Task, TaskType, TaskIntensity, EnergyRecord } from '../models/DataModels'

/**
 * 获取单个任务的能量消耗值
 * REST 类型为负值（恢复能量）
 */
export function getTaskEnergyCost(type: TaskType, intensity: TaskIntensity): number {
  if (type === TaskType.REST) return -1
  switch (intensity) {
    case TaskIntensity.LOW: return 1
    case TaskIntensity.MEDIUM: return 2
    case TaskIntensity.HIGH: return 3
    default: return 2
  }
}

/**
 * 计算一天的任务能量消耗和恢复
 */
export class EnergyCostResult {
  spent: number = 0
  recovered: number = 0
}

export function calculateDayEnergy(tasks: Task[]): EnergyCostResult {
  const result = new EnergyCostResult()
  for (let i = 0; i < tasks.length; i++) {
    const cost = getTaskEnergyCost(tasks[i].type, tasks[i].intensity)
    if (cost > 0) {
      result.spent += cost
    } else {
      result.recovered += Math.abs(cost)
    }
  }
  return result
}

/**
 * 从能量记录计算今日能量预算
 * 基于最近3天的平均能量评分映射到预算
 * 评分 1-5 → 预算 5-12
 */
export function getEnergyBudgetFromRecords(records: EnergyRecord[]): number {
  if (records.length === 0) return 8

  const recent = records.slice(-3)
  let sum = 0
  for (let i = 0; i < recent.length; i++) {
    sum += recent[i].rating
  }
  const avg = sum / recent.length
  return Math.round(5 + avg * 1.5)
}

/**
 * 能量汇总信息
 */
export class EnergySummary {
  budget: number = 8
  spent: number = 0
  recovered: number = 0
  net: number = 0
  overBudget: boolean = false
  socialCount: number = 0

  constructor(budget: number, spent: number, recovered: number, socialCount: number) {
    this.budget = budget
    this.spent = spent
    this.recovered = recovered
    this.net = spent - recovered
    this.overBudget = this.net > budget
    this.socialCount = socialCount
  }
}

/**
 * 获取今日能量汇总
 */
export function getTodayEnergySummary(tasks: Task[], records: EnergyRecord[]): EnergySummary {
  const budget = getEnergyBudgetFromRecords(records)
  const costResult = calculateDayEnergy(tasks)

  let socialCount = 0
  for (let i = 0; i < tasks.length; i++) {
    if (tasks[i].type === TaskType.SOCIAL) {
      socialCount++
    }
  }

  return new EnergySummary(budget, costResult.spent, costResult.recovered, socialCount)
}
