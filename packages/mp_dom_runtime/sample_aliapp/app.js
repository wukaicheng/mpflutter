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
engine.initWithDebuggerServerAddr("10.0.1.69:9898");
const app = new WXApp("pages/index/index", engine);
MPEnv.platformAppInstance.app = app;