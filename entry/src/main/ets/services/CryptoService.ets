import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import util from '@ohos.util'
import deviceInfo from '@ohos.deviceInfo'

export class CryptoService {
  private static readonly LOCAL_SALT = 'StarOrder_v2_Salt_X7k9'
  private static readonly ENC_PREFIX = 'enc2:'
  private static localKey: cryptoFramework.SymKey | null = null
  private static keyInitPromise: Promise<void> | null = null

  static async initLocalKey(): Promise<void> {
    if (CryptoService.localKey) return
    if (CryptoService.keyInitPromise) return CryptoService.keyInitPromise

    CryptoService.keyInitPromise = (async () => {
      let deviceSeed: string
      try {
        deviceSeed = `${deviceInfo.productModel || ''}_${deviceInfo.brand || ''}`
      } catch (e) {
        deviceSeed = 'fallback_device_seed'
      }
      const seed = `${deviceSeed}_${CryptoService.LOCAL_SALT}`
      const keyData = await CryptoService.sha256(seed)
      const generator = cryptoFramework.createSymKeyGenerator('AES256')
      CryptoService.localKey = await generator.convertKey({ data: keyData })
    })()

    return CryptoService.keyInitPromise
  }

  static async encryptLocal(plainText: string): Promise<string> {
    await CryptoService.initLocalKey()
    if (!CryptoService.localKey) throw new Error('Local key not initialized')
    const encrypted = await CryptoService.aesEncrypt(plainText, CryptoService.localKey)
    return CryptoService.ENC_PREFIX + encrypted
  }

  static async decryptLocal(cipherText: string): Promise<string> {
    await CryptoService.initLocalKey()
    if (!CryptoService.localKey) throw new Error('Local key not initialized')
    if (!cipherText.startsWith(CryptoService.ENC_PREFIX)) {
      return cipherText
    }
    const payload = cipherText.slice(CryptoService.ENC_PREFIX.length)
    return CryptoService.aesDecrypt(payload, CryptoService.localKey)
  }

  static isEncrypted(cipherText: string): boolean {
    return cipherText.startsWith(CryptoService.ENC_PREFIX)
  }

  static async encryptForExport(plainText: string, password: string): Promise<string> {
    const salt = CryptoService.randomBytes(16)
    const keyData = await CryptoService.sha256(password + CryptoService.bytesToHex(salt))
    const generator = cryptoFramework.createSymKeyGenerator('AES256')
    const key = await generator.convertKey({ data: keyData })
    const encrypted = await CryptoService.aesEncrypt(plainText, key)
    const encryptedBytes = CryptoService.base64Decode(encrypted)
    const combined = new Uint8Array([...salt, ...encryptedBytes])
    const payload = CryptoService.base64Encode(combined)
    return `star_export_v2:${payload}`
  }

  static async decryptForImport(cipherText: string, password: string): Promise<string> {
    if (!cipherText.startsWith('star_export_v2:')) {
      return cipherText
    }
    const payload = cipherText.slice('star_export_v2:'.length)
    const bytes = CryptoService.base64Decode(payload)
    const salt = bytes.slice(0, 16)
    const encryptedBytes = bytes.slice(16)
    const keyData = await CryptoService.sha256(password + CryptoService.bytesToHex(salt))
    const generator = cryptoFramework.createSymKeyGenerator('AES256')
    const key = await generator.convertKey({ data: keyData })
    const encrypted = CryptoService.base64Encode(encryptedBytes)
    return CryptoService.aesDecrypt(encrypted, key)
  }

  private static async aesEncrypt(plainText: string, key: cryptoFramework.SymKey): Promise<string> {
    const cipher = cryptoFramework.createCipher('AES256|CBC|PKCS7')
    const iv = CryptoService.randomBytes(16)
    const ivParams: cryptoFramework.IvParamsSpec = {
      iv: { data: iv },
      algName: 'IvParamsSpec'
    }
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, ivParams)
    const encoder = new util.TextEncoder()
    const plainBlob: cryptoFramework.DataBlob = { data: encoder.encodeInto(plainText) }
    const updateOutput = await cipher.update(plainBlob)
    const finalOutput = await cipher.doFinal(null)
    let cipherData = updateOutput?.data || new Uint8Array(0)
    if (finalOutput?.data) {
      cipherData = new Uint8Array([...cipherData, ...finalOutput.data])
    }
    const combined = new Uint8Array([...iv, ...cipherData])
    return CryptoService.base64Encode(combined)
  }

  private static async aesDecrypt(cipherText: string, key: cryptoFramework.SymKey): Promise<string> {
    const combined = CryptoService.base64Decode(cipherText)
    const iv = combined.slice(0, 16)
    const cipherData = combined.slice(16)
    const cipher = cryptoFramework.createCipher('AES256|CBC|PKCS7')
    const ivParams: cryptoFramework.IvParamsSpec = {
      iv: { data: iv },
      algName: 'IvParamsSpec'
    }
    await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, ivParams)
    const updateOutput = await cipher.update({ data: cipherData } as cryptoFramework.DataBlob)
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
    await md.update({ data: encoder.encodeInto(input) } as cryptoFramework.DataBlob)
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
