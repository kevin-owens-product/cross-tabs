// Navigation utilities for single-spa integration

export function navigateToRoute(path: string) {
  // @ts-ignore
  if (window.singleSpaNavigate) {
    // @ts-ignore
    window.singleSpaNavigate(path);
  } else {
    // Fallback to regular navigation
    window.history.pushState(null, "", path);
    window.dispatchEvent(new PopStateEvent("popstate"));
  }
}

export function getCrosstabsPath(fullPath: string): string {
  const crosstabsIndex = fullPath.indexOf("/crosstabs");
  if (crosstabsIndex !== -1) {
    return fullPath.substring(crosstabsIndex + "/crosstabs".length) || "/";
  }
  return "/";
}

export function buildCrosstabsUrl(path: string, flags?: { feature?: string; pathPrefix?: string }): string {
  const prefix = flags?.feature && flags?.pathPrefix 
    ? `/${flags.feature}/${flags.pathPrefix}` 
    : flags?.feature 
    ? `/${flags.feature}` 
    : "";
  
  return `${prefix}/crosstabs${path === "/" ? "" : path}`;
}

