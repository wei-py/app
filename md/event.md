## 定位

message.func == "location"
webRef.current.injectJavaScript(`window.toast('定位功能暂时关闭', 'success');`);

## 打开扫码

message.func == "openCode"

## 关闭扫码

message.func == "closeCode"

## 保存图片

message.func == "saveImg"
saveImg(message.src, message.name, webRef);

## 震动

message.func == "vibration"

## 获取设备信息

message.func == "getInfo"
const info = { version: appVersion, os: Platform.OS };
webRef.current.injectJavaScript(`window.getDeviceInfo('${JSON.stringify(info)}');`);

## 复制文本

message.func == "copyText"
webRef.current.injectJavaScript(`window.copy('${message.text}');`);