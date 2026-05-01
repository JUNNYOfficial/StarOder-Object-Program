import { image } from '@kit.ImageKit'

export interface FaceMoodAnalysisResult {
  score: number // 1-5
  confidence: number // 0-1
  reason: string
}

interface Hsv {
  h: number;
  s: number;
  v: number;
}

export class FaceMoodAnalyzer {
  static async analyze(pixelMap: image.PixelMap): Promise<FaceMoodAnalysisResult> {
    const info: image.ImageInfo = await pixelMap.getImageInfo()
    const width = info.size.width
    const height = info.size.height

    const bufferSize = width * height * 4
    // 防止高清照片导致 ArrayBuffer 溢出（如 4000x3000 = 48MB）
    const MAX_BUFFER_SIZE = 16 * 1024 * 1024 // 16MB
    if (bufferSize > MAX_BUFFER_SIZE) {
      return {
        score: 3,
        confidence: 0.3,
        reason: '照片尺寸过大，建议靠近镜头重新拍摄'
      }
    }
    const buffer = new ArrayBuffer(bufferSize)
    await pixelMap.readPixelsToBuffer(buffer)

    const pixels = new Uint8Array(buffer)

    let totalWarm = 0
    let totalCold = 0
    let totalV = 0
    let totalS = 0
    let sampleCount = 0

    // 采样步长，控制分析像素数量以平衡性能
    const step = Math.max(1, Math.floor((width * height) / 5000))

    for (let i = 0; i < pixels.length; i += 4 * step) {
      const r = pixels[i] / 255
      const g = pixels[i + 1] / 255
      const b = pixels[i + 2] / 255

      const hsv = FaceMoodAnalyzer.rgbToHsv(r, g, b)
      const h = hsv.h
      const s = hsv.s
      const v = hsv.v

      // 暖色：红/橙/黄 (0-60°) 及 品红 (300-360°)
      // 冷色：青/蓝 (160-260°)
      if ((h >= 0 && h <= 60) || (h >= 300 && h <= 360)) {
        totalWarm++
      } else if (h >= 160 && h <= 260) {
        totalCold++
      }

      totalV += v
      totalS += s
      sampleCount++
    }

    if (sampleCount === 0) {
      return { score: 3, confidence: 0, reason: '无法分析图片内容' }
    }

    const warmRatio = totalWarm / sampleCount
    const coldRatio = totalCold / sampleCount
    const avgV = totalV / sampleCount
    const avgS = totalS / sampleCount

    // 情绪评分算法（基于色彩心理学简化模型）
    let score = 3.0
    score += (avgV - 0.5) * 2.0
    score += (warmRatio - 0.25) * 1.5
    score -= (coldRatio - 0.25) * 1.5
    score += (avgS - 0.4) * 0.8

    score = Math.max(1, Math.min(5, score))
    const roundedScore = Math.round(score)

    // 置信度：饱和度越高、亮度越适中，置信度越高
    const confidence = 0.35 + avgS * 0.35 + (1 - Math.abs(avgV - 0.5) * 2) * 0.2

    // 生成分析理由
    const reasons: string[] = []
    if (avgV > 0.65) {
      reasons.push('画面明亮')
    } else if (avgV < 0.4) {
      reasons.push('画面偏暗')
    }

    if (warmRatio > 0.4) {
      reasons.push('暖色调占优')
    } else if (coldRatio > 0.35) {
      reasons.push('冷色调占优')
    }

    if (avgS > 0.5) {
      reasons.push('色彩鲜明')
    } else {
      reasons.push('色彩柔和')
    }

    const reason = reasons.join('，') + `，参考情绪 ${roundedScore}/5`

    return {
      score: roundedScore,
      confidence: Math.max(0, Math.min(1, confidence)),
      reason
    }
  }

  private static rgbToHsv(r: number, g: number, b: number): Hsv {
    const max = Math.max(r, g, b)
    const min = Math.min(r, g, b)
    const d = max - min

    let h = 0
    if (d !== 0) {
      if (max === r) {
        h = ((g - b) / d + (g < b ? 6 : 0)) * 60
      } else if (max === g) {
        h = ((b - r) / d + 2) * 60
      } else {
        h = ((r - g) / d + 4) * 60
      }
    }

    const s = max === 0 ? 0 : d / max
    const v = max

    return { h, s, v }
  }
}
