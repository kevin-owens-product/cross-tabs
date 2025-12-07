// Port integration for React app
// These replace the Elm ports

export const ports = {
  // Single-spa lifecycle
  mountedXB2: () => {
    // Signal that app is mounted
    window.dispatchEvent(new CustomEvent("crosstabs-mounted"));
  },

  unmountedXB2: () => {
    // Signal that app is unmounted
    window.dispatchEvent(new CustomEvent("crosstabs-unmounted"));
  },

  // Navigation
  navigateToXB2: (url: string) => {
    // @ts-ignore
    if (window.singleSpaNavigate) {
      // @ts-ignore
      window.singleSpaNavigate(url);
    } else {
      window.location.href = url;
    }
  },

  openNewWindowXB2: (url: string) => {
    window.open(url, "_blank");
  },

  routeChangedXB2: (url: string) => {
    // Handle route changes from single-spa
    window.dispatchEvent(new CustomEvent("crosstabs-route-changed", { detail: { url } }));
  },

  checkRouteInterruptionXB2: (url: string) => {
    // Check if route change should be interrupted
    window.dispatchEvent(new CustomEvent("crosstabs-check-route-interruption", { detail: { url } }));
  },

  interruptRoutingStatusXB2: (shouldInterrupt: boolean) => {
    // Respond to route interruption check
    window.dispatchEvent(new CustomEvent("crosstabs-route-interruption-status", { detail: { shouldInterrupt } }));
  },

  setXBProjectCheckBeforeLeave: (shouldCheck: boolean) => {
    // Set flag to check before leaving page
    window.dispatchEvent(new CustomEvent("crosstabs-check-before-leave", { detail: { shouldCheck } }));
  },

  // Analytics and events
  bookADemoButtonClicked: () => {
    window.dispatchEvent(new CustomEvent("CrosstabBuilder-bookDemoEvent"));
  },

  talkToAnExpertSplashEvent: () => {
    window.dispatchEvent(new CustomEvent("CrosstabBuilder-talkToAnExpertEvent"));
  },

  upgradeSplashEvent: () => {
    window.dispatchEvent(new CustomEvent("CrosstabBuilder-upgradeEvent"));
  },
};

// Subscribe to port events
export function subscribeToPorts(callbacks: {
  onMounted?: () => void;
  onUnmounted?: () => void;
  onRouteChanged?: (url: string) => void;
  onCheckBeforeLeave?: (shouldCheck: boolean) => void;
}) {
  const handlers: Array<() => void> = [];

  if (callbacks.onMounted) {
    const handler = () => callbacks.onMounted!();
    window.addEventListener("crosstabs-mounted", handler);
    handlers.push(() => window.removeEventListener("crosstabs-mounted", handler));
  }

  if (callbacks.onUnmounted) {
    const handler = () => callbacks.onUnmounted!();
    window.addEventListener("crosstabs-unmounted", handler);
    handlers.push(() => window.removeEventListener("crosstabs-unmounted", handler));
  }

  if (callbacks.onRouteChanged) {
    const handler = (e: Event) => {
      const customEvent = e as CustomEvent;
      callbacks.onRouteChanged!(customEvent.detail.url);
    };
    window.addEventListener("crosstabs-route-changed", handler);
    handlers.push(() => window.removeEventListener("crosstabs-route-changed", handler));
  }

  if (callbacks.onCheckBeforeLeave) {
    const handler = (e: Event) => {
      const customEvent = e as CustomEvent;
      callbacks.onCheckBeforeLeave!(customEvent.detail.shouldCheck);
    };
    window.addEventListener("crosstabs-check-before-leave", handler);
    handlers.push(() => window.removeEventListener("crosstabs-check-before-leave", handler));
  }

  return () => {
    handlers.forEach(cleanup => cleanup());
  };
}

