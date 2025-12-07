import React, { useEffect, useRef } from "react";
import { Flags, AudienceItem } from "../types";
import "./AudienceBrowser.scss";

interface AudienceBrowserProps {
  flags: Flags;
  onAudienceSelected: (audience: AudienceItem) => void;
  onClose: () => void;
  preexistingAudiences?: AudienceItem[];
  stagedAudiences?: AudienceItem[];
  compatibleNamespaces?: string[];
  allDatasets?: any[];
  isBase?: boolean;
}

export function AudienceBrowser({
  flags,
  onAudienceSelected,
  onClose,
  preexistingAudiences = [],
  stagedAudiences = [],
  compatibleNamespaces = [],
  allDatasets = [],
  isBase = false,
}: AudienceBrowserProps) {
  const browserRef = useRef<HTMLElement>(null);

  useEffect(() => {
    const element = browserRef.current;
    if (!element) return;

    // Configure the web component
    const apiEncoded = JSON.stringify({
      AUDIENCES_CORE_HOST: flags.env.uri.audiencesCore || "",
      SERVICE_LAYER_HOST: flags.env.uri.serviceLayer || "",
      ANALYTICS_HOST: flags.env.uri.analytics || "",
      API_ROOT_HOST: flags.env.uri.api,
      COLLECTIONS_HOST: flags.env.uri.collections || "",
    });

    const userEncoded = JSON.stringify({
      token: flags.token,
      email: flags.user.email,
      customer_features: [], // TODO: Get from flags.user
    });

    const encodedConfig = JSON.stringify({
      appName: "CrosstabBuilder",
      environment: "production", // TODO: Get from flags.env
      api: JSON.parse(apiEncoded),
      user: JSON.parse(userEncoded),
    });

    // Set attributes
    element.setAttribute("x-env-values", encodedConfig);
    element.setAttribute("modal-type", "add");
    element.setAttribute("staged-audiences", JSON.stringify(stagedAudiences));
    element.setAttribute("selected-audiences", JSON.stringify(preexistingAudiences));
    element.setAttribute("all-datasets", JSON.stringify(allDatasets));
    element.setAttribute("compatible-namespaces", JSON.stringify(compatibleNamespaces));
    element.setAttribute("hide-my-audiences-tab", "false");

    // Listen for events
    const handleToggle = (e: CustomEvent) => {
      try {
        const audience = e.detail.payload;
        onAudienceSelected(audience);
      } catch (error) {
        console.error("Error parsing audience:", error);
      }
    };

    const handleClose = () => {
      onClose();
    };

    element.addEventListener("audienceBrowserLeftToggledEvent", handleToggle as EventListener);
    element.addEventListener("audienceBrowserLeftCloseEvent", handleClose);

    return () => {
      element.removeEventListener("audienceBrowserLeftToggledEvent", handleToggle as EventListener);
      element.removeEventListener("audienceBrowserLeftCloseEvent", handleClose);
    };
  }, [flags, onAudienceSelected, onClose, preexistingAudiences, stagedAudiences, compatibleNamespaces, allDatasets]);

  return (
    <div className="audience-browser-wrapper">
      <div className="audience-browser-header">
        <h2>Select Audience</h2>
        <button onClick={onClose} className="close-button">
          ×
        </button>
      </div>
      <div className="audience-browser-content">
        {/* @ts-ignore - Web component */}
        <x-et-audience-browser ref={browserRef} />
      </div>
    </div>
  );
}

