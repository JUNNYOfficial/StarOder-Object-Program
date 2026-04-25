import { UiTokens } from '../design/UiTokens'

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
