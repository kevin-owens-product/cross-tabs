import React, { useEffect, useState } from "react";
import { MemoryRouter, Routes, Route, useNavigate, useLocation } from "react-router-dom";
import { Flags } from "./types";
import { AppProvider } from "./context/AppContext";
import { ProjectListPage } from "./pages/ProjectListPage";
import { ProjectDetailPage } from "./pages/ProjectDetailPage";
import { SplashScreen } from "./components/SplashScreen";
import { ErrorBoundary } from "./components/ErrorBoundary";
import { ToastProvider } from "./components/ToastProvider";
import "./App.scss";

interface AppProps {
  flags: Flags;
  isAppMounted: boolean;
  onMounted: () => void;
  onUnmounted: () => void;
}

function getInitialPath(): string {
  const path = window.location.pathname;
  const crosstabsIndex = path.indexOf("/crosstabs");
  if (crosstabsIndex !== -1) {
    const crosstabsPath = path.substring(crosstabsIndex + "/crosstabs".length);
    return crosstabsPath || "/";
  }
  return "/";
}

function AppContent({ flags, isAppMounted, onMounted, onUnmounted }: AppProps) {
  const navigate = useNavigate();
  const location = useLocation();
  const [isMounted, setIsMounted] = useState(isAppMounted);

  useEffect(() => {
    if (isAppMounted && !isMounted) {
      setIsMounted(true);
      onMounted();
    } else if (!isAppMounted && isMounted) {
      setIsMounted(false);
      onUnmounted();
    }
  }, [isAppMounted, isMounted, onMounted, onUnmounted]);

  // Handle route changes from single-spa
  useEffect(() => {
    const handleRouteChange = () => {
      const newPath = getInitialPath();
      if (location.pathname !== newPath) {
        navigate(newPath);
      }
    };

    window.addEventListener("single-spa:routing-event", handleRouteChange);
    return () => {
      window.removeEventListener("single-spa:routing-event", handleRouteChange);
    };
  }, [navigate, location.pathname]);

  // Check if app is locked (user doesn't have permission)
  if (!flags.can.useCrosstabs) {
    return (
      <SplashScreen
        appName="crosstabs"
        email={flags.user.email}
        upgradePlanUrl={getUpgradePlanUrl(flags.user.planHandle)}
      />
    );
  }

  if (!isMounted) {
    return <div>App is not mounted!</div>;
  }

  return (
    <ErrorBoundary>
      <AppProvider flags={flags}>
        <ToastProvider>
          <Routes>
            <Route path="/" element={<ProjectListPage />} />
            <Route path="/new" element={<ProjectDetailPage />} />
            <Route path="/:projectId" element={<ProjectDetailPage />} />
          </Routes>
        </ToastProvider>
      </AppProvider>
    </ErrorBoundary>
  );
}

function getUpgradePlanUrl(planHandle: string): string {
  // TODO: Implement based on plan type
  return `/upgrade?plan=${planHandle}`;
}

export function App(props: AppProps) {
  const initialPath = getInitialPath();
  
  return (
    <MemoryRouter initialEntries={[initialPath]}>
      <AppContent {...props} />
    </MemoryRouter>
  );
}

