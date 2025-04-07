import * as Utils from "./utils";
import { AttributeBrowserLeftWebComponent } from "@globalwebindex/platform2-web-components/lib/attributeBrowserLeft/index.js";
import { AudienceBrowserLeftWebComponent } from "@globalwebindex/platform2-web-components/lib/audienceBrowserLeft/index.js";
import { AudienceExpressionViewerWebComponent } from "@globalwebindex/platform2-web-components/lib/audienceExpressionViewer/index.js";
import { SplashScreenWebComponent } from "@globalwebindex/platform2-web-components/lib/splashScreen/index.js";

Utils.register(`x-et-attribute-browser`, AttributeBrowserLeftWebComponent);
Utils.register(`x-et-audience-browser`, AudienceBrowserLeftWebComponent);
Utils.register(`x-et-audience-expression-viewer`, AudienceExpressionViewerWebComponent);
Utils.register(`x-et-splash-screen`, SplashScreenWebComponent);
