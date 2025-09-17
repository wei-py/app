import { scanCode, getAppBaseInfo, setClipboardData, downloadFile, saveImageToPhotosAlbum, getAppInfo, vibrateShort } from "@tarojs/taro"
import { Platform } from "react-native"

export function handleMessage(message: any): string {
  console.log(message.func);
  switch (message.func) {
    case "openCode":
      openCode(message);
      break;
    case "closeCode":
      break;
    case "saveImg":
      saveImg(message);
      break;
    case "vibration":
      vibrateShort();
      break;
    case "getInfo":
      return getInfo();
    case "copyText":
      copyText(message)
      break;
  }
  return ""
}

function openCode(message: any) {
  scanCode({
    success(code) {
      // code.result
    },
    fail(code) {
      // code.errMsg
    }
  })

}

function saveImg(message: any) {
  downloadFile({
    url: message.src,
    success(file) {
      saveImageToPhotosAlbum({
        filePath: file.tempFilePath
      })
    }
  })
}

function getInfo(): string {
  const appInfo = getAppBaseInfo();
  console.log(appInfo.version, Platform.OS);
  appInfo.version = "2.1.0" // 测试使用
  const info = { version: appInfo.version, os: Platform.OS };
  return `window.getDeviceInfo('${JSON.stringify(info)}');`
}

function copyText(message: any) {
  setClipboardData({
    data: message.text
  })
  const msg = `window.copy('${message.text}');`
}

function test() {
  scanCode({
    success(code) {
      console.log(111111);
    },
    fail(code) {
      console.log(22222);
    }
  })
}