import { register } from "./_helpers/webcomponents";
import { AttributeBrowserLeftWebComponent } from "@globalwebindex/platform2-web-components/lib/attributeBrowserLeft/index.js";
import { AudienceBrowserLeftWebComponent } from "@globalwebindex/platform2-web-components/lib/audienceBrowserLeft/index.js";
import { AudienceExpressionViewerWebComponent } from "@globalwebindex/platform2-web-components/lib/audienceExpressionViewer/index.js";
import { SplashScreenWebComponent } from "@globalwebindex/platform2-web-components/lib/splashScreen/index.js";

register(`x-et-attribute-browser`, AttributeBrowserLeftWebComponent);
register(`x-et-audience-browser`, AudienceBrowserLeftWebComponent);
register(`x-et-audience-expression-viewer`, AudienceExpressionViewerWebComponent);
register(`x-et-splash-screen`, SplashScreenWebComponent);
