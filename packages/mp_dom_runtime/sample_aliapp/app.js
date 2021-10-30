const { MPEnv, Engine, WXApp } = require("./mpdom.min");
MPEnv.platformAppInstance = App({
  onLaunch(options) {
    engine.start();
  },
});
MPEnv.platformAppInstance.mpDEBUG = true;
try {
  require("./plugins.min");
} catch (error) { }
const engine = new Engine();
engine.initWithDebuggerServerAddr("192.172.22.206:9898");
const app = new WXApp("pages/index/index", engine);
MPEnv.platformAppInstance.app = app;