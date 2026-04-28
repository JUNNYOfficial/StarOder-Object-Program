import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import util from '@ohos.util'
import { deviceInfo } from '@kit.DeviceKit'

export class CryptoService {
  private static readonly LOCAL_SALT = 'StarOrder_v2_Salt_X7k9'
  private static readonly ENC_PREFIX = 'enc2:'
  private static localKey: cryptoFramework.SymKey | null = null
  private static keyInitPromise: Promise<void> | null = null

  static async initLocalKey(): Promise<void> {
    if (this.localKey) return
    if (this.keyInitPromise) return this.keyInitPromise

    this.keyInitPromise = (async () => {
      let deviceSeed: string
      try {
        deviceSeed = `${deviceInfo.marketName || ''}_${deviceInfo.productModel || ''}_${deviceInfo.brand || ''}_${deviceInfo.manufacture || ''}`
      } catch (e) {
        deviceSeed = 'fallback_device_seed'
      }
      const seed = `${deviceSeed}_${this.LOCAL_SALT}`
      const keyData = await this.sha256(seed)
      const generator = cryptoFramework.createSymKeyGenerator('AES256')
      this.localKey = await generator.convertKey({ data: keyData })
    })()

    return this.keyInitPromise
  }

  static async encryptLocal(plainText: string): Promise<string> {
    await this.initLocalKey()
    if (!this.localKey) throw new Error('Local key not initialized')
    const encrypted = await this.aesEncrypt(plainText, this.localKey)
    return this.ENC_PREFIX + encrypted
  }

  static async decryptLocal(cipherText: string): Promise<string> {
    await this.initLocalKey()
    if (!this.localKey) throw new Error('Local key not initialized')
    if (!cipherText.startsWith(this.ENC_PREFIX)) {
      return cipherText
    }
    const payload = cipherText.slice(this.ENC_PREFIX.length)
    return this.aesDecrypt(payload, this.localKey)
  }

  static isEncrypted(cipherText: string): boolean {
    return cipherText.startsWith(this.ENC_PREFIX)
  }

  static async encryptForExport(plainText: string, password: string): Promise<string> {
    const salt = this.randomBytes(16)
    const keyData = await this.sha256(password + this.bytesToHex(salt))
    const generator = cryptoFramework.createSymKeyGenerator('AES256')
    const key = await generator.convertKey({ data: keyData })
    const encrypted = await this.aesEncrypt(plainText, key)
    const encryptedBytes = this.base64Decode(encrypted)
    const combined = new Uint8Array([...salt, ...encryptedBytes])
    const payload = this.base64Encode(combined)
    return `star_export_v2:${payload}`
  }

  static async decryptForImport(cipherText: string, password: string): Promise<string> {
    if (!cipherText.startsWith('star_export_v2:')) {
      return cipherText
    }
    const payload = cipherText.slice('star_export_v2:'.length)
    const bytes = this.base64Decode(payload)
    const salt = bytes.slice(0, 16)
    const encryptedBytes = bytes.slice(16)
    const keyData = await this.sha256(password + this.bytesToHex(salt))
    const generator = cryptoFramework.createSymKeyGenerator('AES256')
    const key = await generator.convertKey({ data: keyData })
    const encrypted = this.base64Encode(encryptedBytes)
    return this.aesDecrypt(encrypted, key)
  }

  private static async aesEncrypt(plainText: string, key: cryptoFramework.SymKey): Promise<string> {
    const cipher = cryptoFramework.createCipher('AES256|CBC|PKCS7')
    const iv = this.randomBytes(16)
    const ivParams: cryptoFramework.IvParamsSpec = {
      iv: { data: iv },
      algName: 'IvParamsSpec'
    }
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, ivParams)
    const encoder = new util.TextEncoder()
    const plainBlob = { data: encoder.encodeInto(plainText) }
    const updateOutput = await cipher.update(plainBlob)
    const finalOutput = await cipher.doFinal(null)
    let cipherData = updateOutput?.data || new Uint8Array(0)
    if (finalOutput?.data) {
      cipherData = new Uint8Array([...cipherData, ...finalOutput.data])
    }
    const combined = new Uint8Array([...iv, ...cipherData])
    return this.base64Encode(combined)
  }

  private static async aesDecrypt(cipherText: string, key: cryptoFramework.SymKey): Promise<string> {
    const combined = this.base64Decode(cipherText)
    const iv = combined.slice(0, 16)
    const cipherData = combined.slice(16)
    const cipher = cryptoFramework.createCipher('AES256|CBC|PKCS7')
    const ivParams: cryptoFramework.IvParamsSpec = {
      iv: { data: iv },
      algName: 'IvParamsSpec'
    }
    await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, ivParams)
    const updateOutput = await cipher.update({ data: cipherData })
    const finalOutput = await cipher.doFinal(null)
    let plainData = updateOutput?.data || new Uint8Array(0)
    if (finalOutput?.data) {
      plainData = new Uint8Array([...plainData, ...finalOutput.data])
    }
    const decoder = util.TextDecoder.create()
    return decoder.decodeWithStream(plainData)
  }

  private static async sha256(input: string): Promise<Uint8Array> {
    const encoder = new util.TextEncoder()
    const md = cryptoFramework.createMd('SHA256')
    await md.update({ data: encoder.encodeInto(input) })
    const result = await md.digest()
    return result.data
  }

  private static randomBytes(length: number): Uint8Array {
    const bytes = new Uint8Array(length)
    for (let i = 0; i < length; i++) {
      bytes[i] = Math.floor(Math.random() * 256)
    }
    return bytes
  }

  private static base64Encode(bytes: Uint8Array): string {
    const helper = new util.Base64Helper()
    return helper.encodeToStringSync(bytes)
  }

  private static base64Decode(str: string): Uint8Array {
    const helper = new util.Base64Helper()
    return helper.decodeSync(str)
  }

  private static bytesToHex(bytes: Uint8Array): string {
    return Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('')
  }
}
