import React from "react";
import "./SplashScreen.scss";

interface SplashScreenProps {
  appName: string;
  email: string;
  upgradePlanUrl: string;
}

export function SplashScreen({
  appName,
  email,
  upgradePlanUrl,
}: SplashScreenProps) {
  const handleBookDemo = () => {
    // TODO: Implement analytics tracking
    window.dispatchEvent(new CustomEvent("CrosstabBuilder-bookDemoEvent"));
  };

  const handleUpgrade = () => {
    // TODO: Implement analytics tracking
    window.dispatchEvent(new CustomEvent("CrosstabBuilder-upgradeEvent"));
    window.location.href = upgradePlanUrl;
  };

  const handleTalkToExpert = () => {
    // TODO: Implement analytics tracking
    window.dispatchEvent(new CustomEvent("CrosstabBuilder-talkToAnExpertEvent"));
  };

  return (
    <div className="splash-screen">
      <div className="splash-content">
        <h1>Welcome to Crosstabs</h1>
        <p>
          You need to upgrade your plan to access Crosstabs functionality.
        </p>
        <p>Your email: {email}</p>
        <div className="splash-actions">
          <button onClick={handleBookDemo} className="splash-button">
            Book a Demo
          </button>
          <button onClick={handleUpgrade} className="splash-button primary">
            Upgrade Plan
          </button>
          <button onClick={handleTalkToExpert} className="splash-button">
            Talk to an Expert
          </button>
        </div>
      </div>
    </div>
  );
}

