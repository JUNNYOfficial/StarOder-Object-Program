import { UiTokens } from '../design/UiTokens'
import { RepeatMode } from '../models/DataModels'

export function getRepeatModeLabel(mode: RepeatMode): string {
  switch (mode) {
    case RepeatMode.NONE: return '不重复'
    case RepeatMode.DAILY: return '每天'
    case RepeatMode.WEEKLY: return '每周'
    case RepeatMode.MONTHLY: return '每月'
    case RepeatMode.YEARLY: return '每年'
    default: return '不重复'
  }
}

export function getBaseFont(largeText: boolean): number {
  return largeText ? UiTokens.textL : UiTokens.textM
}

export function getSectionTitle(largeText: boolean): number {
  return largeText ? UiTokens.textL : UiTokens.textM
}

export function getLargeFont(largeText: boolean): number {
  return largeText ? UiTokens.text2XL : UiTokens.textXL
}

export function getSmallFont(largeText: boolean): number {
  return largeText ? UiTokens.textM : UiTokens.textS
}

export function getExtraLargeFont(largeText: boolean): number {
  return largeText ? UiTokens.textXL : UiTokens.textL
}
