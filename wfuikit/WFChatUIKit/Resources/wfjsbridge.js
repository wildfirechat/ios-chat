function setupWebViewJavascriptBridge(callback) {
    if (window.WebViewJavascriptBridge) { return callback(WebViewJavascriptBridge); }
    if (window.WVJBCallbacks) { return window.WVJBCallbacks.push(callback); }
    window.WVJBCallbacks = [callback];
    var WVJBIframe = document.createElement('iframe');
    WVJBIframe.style.display = 'none';
    WVJBIframe.src = 'https://__bridge_loaded__';
    document.documentElement.appendChild(WVJBIframe);
    setTimeout(function() { document.documentElement.removeChild(WVJBIframe) }, 0)
}

var jsbridge_internal;

setupWebViewJavascriptBridge(function(bridge) {
    jsbridge_internal = bridge;
});


var WFJSBridge = {
    openUrl: function(url) {
        jsbridge_internal.callHandler('openUrl', {'url':url});
    },
    
    getAuthCode: function(appId, appType, callback) {
        jsbridge_internal.callHandler('getAuthCode', {'appId':appId, 'appType':appType}, function(responseData) {
            console.log("JS received response:", responseData);
            callback(responseData);
        });
    },
    
    ready: function(callback) {
        jsbridge_internal.callHandler('ready', {}, function(responseData) {
            callback();
        });
    },
    
    error: function(callback) {
        jsbridge_internal.callHandler('error', {}, function(errorCode) {
            callback(errorCode);
        });
    },
    
    config: function(appId, appType, timestamp, nonceStr, signature) {
        jsbridge_internal.callHandler('config', {'appId':appId, 'appType':appType, 'timestamp':timestamp, 'nonceStr':nonceStr, 'signature':signature});
    },
};
