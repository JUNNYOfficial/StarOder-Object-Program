import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import util from '@ohos.util'
import deviceInfo from '@ohos.deviceInfo'

export class CryptoService {
  private static readonly LOCAL_SALT = 'StarOrder_v2_Salt_X7k9'
  private static readonly ENC_PREFIX = 'enc2:'
  private static localKey: cryptoFramework.SymKey | null = null
  private static keyInitPromise: Promise<void> | null = null

  // Export KDF parameters (PBKDF2-equivalent)
  private static readonly EXPORT_ITERATIONS = 10000
  private static readonly EXPORT_SALT_LEN = 16

  static async initLocalKey(): Promise<void> {
    if (CryptoService.localKey) return
    if (CryptoService.keyInitPromise) return CryptoService.keyInitPromise

    CryptoService.keyInitPromise = (async () => {
      let deviceSeed: string
      try {
        deviceSeed = `${deviceInfo.productModel || ''}_${deviceInfo.brand || ''}_${deviceInfo.marketName || ''}_${deviceInfo.deviceType || ''}_${deviceInfo.manufacture || ''}`
      } catch (e) {
        deviceSeed = 'fallback_device_seed'
      }
      const seed = `${deviceSeed}_${CryptoService.LOCAL_SALT}`
      const encoder = new util.TextEncoder()
      const seedBytes = encoder.encodeInto(seed)
      const keyData = await CryptoService.deriveKey(seedBytes, 1000)
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
    const salt = await CryptoService.randomBytes(CryptoService.EXPORT_SALT_LEN)
    const keyData = await CryptoService.deriveExportKey(password, salt)
    const generator = cryptoFramework.createSymKeyGenerator('AES256')
    const key = await generator.convertKey({ data: keyData })
    const encrypted = await CryptoService.aesEncrypt(plainText, key)
    const encryptedBytes = CryptoService.base64Decode(encrypted)
    const combined = new Uint8Array([...salt, ...encryptedBytes])
    const payload = CryptoService.base64Encode(combined)
    return `star_export_v3:${payload}`
  }

  static async decryptForImport(cipherText: string, password: string): Promise<string> {
    if (cipherText.startsWith('star_export_v3:')) {
      const payload = cipherText.slice('star_export_v3:'.length)
      const bytes = CryptoService.base64Decode(payload)
      const salt = bytes.slice(0, CryptoService.EXPORT_SALT_LEN)
      const encryptedBytes = bytes.slice(CryptoService.EXPORT_SALT_LEN)
      const keyData = await CryptoService.deriveExportKey(password, salt)
      const generator = cryptoFramework.createSymKeyGenerator('AES256')
      const key = await generator.convertKey({ data: keyData })
      const encrypted = CryptoService.base64Encode(encryptedBytes)
      return CryptoService.aesDecrypt(encrypted, key)
    }

    if (cipherText.startsWith('star_export_v2:')) {
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

    return cipherText
  }

  private static async aesEncrypt(plainText: string, key: cryptoFramework.SymKey): Promise<string> {
    const cipher = cryptoFramework.createCipher('AES256|CBC|PKCS7')
    const iv = await CryptoService.randomBytes(16)
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

  private static async deriveExportKey(password: string, salt: Uint8Array): Promise<Uint8Array> {
    const encoder = new util.TextEncoder()
    const passwordBytes = encoder.encodeInto(password)
    const input = new Uint8Array([...passwordBytes, ...salt])
    return CryptoService.deriveKey(input, CryptoService.EXPORT_ITERATIONS)
  }

  private static async deriveKey(input: Uint8Array, iterations: number): Promise<Uint8Array> {
    let data = input
    for (let i = 0; i < iterations; i++) {
      const md = cryptoFramework.createMd('SHA256')
      await md.update({ data } as cryptoFramework.DataBlob)
      const result = await md.digest()
      data = result.data
    }
    return data
  }

  private static async randomBytes(length: number): Promise<Uint8Array> {
    const rand = cryptoFramework.createRandom()
    const blob = await rand.generateRandom(length)
    return blob.data
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
