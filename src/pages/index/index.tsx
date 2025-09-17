import { useRef } from "react";
import { SafeAreaView } from "react-native";
import { WebView } from "react-native-webview"; // webview h5
import "./index.scss";
import { handleMessage } from "../../utils";

export default () => {
  const webRef = useRef(null);

  function onMessage(e: any) {
    const message = JSON.parse(e.nativeEvent.data);
    const s: string = handleMessage(message);
    if (webRef.current && s) {
      webRef.current.injectJavaScript(s);
    }
  }

  return (
    <SafeAreaView style={{ display: "flex", flex: 1, backgroundColor: "#fff" }}>
      <WebView
        ref={webRef}
        style={{ flex: 1 }}
        onMessage={onMessage}
        allowsBackForwardNavigationGestures
        allowsInlineMediaPlayback
        allowsAirPlayForMediaPlayback
        allowsLinkPreview
        allowsProtectedMedia
        geolocationEnabled
        allowFileAccessFromFileURLs
        allowUniversalAccessFromFileURLs
        allowFileAccess
        allowsFullscreenVideo
        scalesPageToFit
        javaScriptEnabled // 启用 JavaScript
        domStorageEnabled // 启用 DOM 存储
        useWebKit
        startInLoadingState
        // onNavigationStateChange={onNavigationStateChange}
        // onShouldStartLoadWithRequest={onShouldStartLoadWithRequest}
        mixedContentMode="always"
        originWhitelist={[
          "https://*",
          "http://*",
          "file://*",
          "sms://*",
          "atrium://*",
        ]}
        source={{
          uri: "https://www.btosolarman.com/orderh5/#/login",
          androidHardwareAccelerationDisabled: true,
          originWhitelist: ["*"],
        }}
      />
    </SafeAreaView>
  );
};
