import React, { createContext, useContext, useState, useCallback, ReactNode } from "react";
import { Flags, XBProject, XBFolder, XBUserSettings, WebData } from "../types";
import { IdDict } from "../utils/idDict";

interface AppState {
  projects: WebData<IdDict<string, XBProject>>;
  folders: WebData<IdDict<string, XBFolder>>;
  userSettings: WebData<XBUserSettings>;
}

interface AppContextValue {
  flags: Flags;
  state: AppState;
  updateState: (updater: (state: AppState) => AppState) => void;
  // Add action methods here
  fetchProjects: () => Promise<void>;
  fetchFolders: () => Promise<void>;
  fetchUserSettings: () => Promise<void>;
  createProject: (projectData: Partial<any>) => Promise<any>;
  updateProject: (projectId: string, projectData: Partial<any>) => Promise<any>;
  deleteProject: (projectId: string) => Promise<void>;
}

const AppContext = createContext<AppContextValue | undefined>(undefined);

export function useApp() {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error("useApp must be used within AppProvider");
  }
  return context;
}

interface AppProviderProps {
  flags: Flags;
  children: ReactNode;
}

export function AppProvider({ flags, children }: AppProviderProps) {
  const [state, setState] = useState<AppState>({
    projects: { type: "NotAsked" },
    folders: { type: "NotAsked" },
    userSettings: { type: "NotAsked" },
  });

  const updateState = useCallback((updater: (state: AppState) => AppState) => {
    setState(updater);
  }, []);

  const fetchProjects = useCallback(async () => {
    setState((prev) => ({ ...prev, projects: { type: "Loading" } }));
    try {
      const response = await fetch(`${flags.env.uri.api}/api/v1/crosstabs`, {
        headers: {
          Authorization: `Bearer ${flags.token}`,
          "Content-Type": "application/json",
        },
      });
      if (!response.ok) {
        if (response.status === 401) {
          // Handle unauthorized - redirect to sign out
          // @ts-ignore
          if (window.singleSpaNavigate) {
            // @ts-ignore
            window.singleSpaNavigate("/sign-out");
          }
          throw new Error("Unauthorized");
        }
        throw new Error(`Failed to fetch projects: ${response.statusText}`);
      }
      const data = await response.json();
      setState((prev) => ({
        ...prev,
        projects: { type: "Success", data: arrayToIdDict(data) },
      }));
    } catch (error) {
      setState((prev) => ({
        ...prev,
        projects: {
          type: "Failure",
          error: error instanceof Error ? error.message : "Unknown error",
        },
      }));
    }
  }, [flags]);

  const fetchFolders = useCallback(async () => {
    setState((prev) => ({ ...prev, folders: { type: "Loading" } }));
    try {
      const response = await fetch(`${flags.env.uri.api}/api/v1/crosstabs/folders`, {
        headers: {
          Authorization: `Bearer ${flags.token}`,
          "Content-Type": "application/json",
        },
      });
      if (!response.ok) {
        if (response.status === 401) {
          // @ts-ignore
          if (window.singleSpaNavigate) {
            // @ts-ignore
            window.singleSpaNavigate("/sign-out");
          }
          throw new Error("Unauthorized");
        }
        throw new Error(`Failed to fetch folders: ${response.statusText}`);
      }
      const data = await response.json();
      setState((prev) => ({
        ...prev,
        folders: { type: "Success", data: arrayToIdDict(data) },
      }));
    } catch (error) {
      setState((prev) => ({
        ...prev,
        folders: {
          type: "Failure",
          error: error instanceof Error ? error.message : "Unknown error",
        },
      }));
    }
  }, [flags]);

  const fetchUserSettings = useCallback(async () => {
    setState((prev) => ({ ...prev, userSettings: { type: "Loading" } }));
    try {
      const response = await fetch(`${flags.env.uri.api}/api/v1/crosstabs/user-settings`, {
        headers: {
          Authorization: `Bearer ${flags.token}`,
          "Content-Type": "application/json",
        },
      });
      if (!response.ok) {
        if (response.status === 401) {
          // @ts-ignore
          if (window.singleSpaNavigate) {
            // @ts-ignore
            window.singleSpaNavigate("/sign-out");
          }
          throw new Error("Unauthorized");
        }
        throw new Error(`Failed to fetch user settings: ${response.statusText}`);
      }
      const data = await response.json();
      setState((prev) => ({
        ...prev,
        userSettings: { type: "Success", data },
      }));
    } catch (error) {
      setState((prev) => ({
        ...prev,
        userSettings: {
          type: "Failure",
          error: error instanceof Error ? error.message : "Unknown error",
        },
      }));
    }
  }, [flags]);

  const createProject = useCallback(async (projectData: Partial<any>) => {
    try {
      const response = await fetch(`${flags.env.uri.api}/api/v1/crosstabs`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${flags.token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(projectData),
      });
      if (!response.ok) {
        throw new Error(`Failed to create project: ${response.statusText}`);
      }
      const data = await response.json();
      // Refresh projects list
      await fetchProjects();
      return data;
    } catch (error) {
      throw error;
    }
  }, [flags, fetchProjects]);

  const updateProject = useCallback(async (projectId: string, projectData: Partial<any>) => {
    try {
      const response = await fetch(`${flags.env.uri.api}/api/v1/crosstabs/${projectId}`, {
        method: "PATCH",
        headers: {
          Authorization: `Bearer ${flags.token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(projectData),
      });
      if (!response.ok) {
        throw new Error(`Failed to update project: ${response.statusText}`);
      }
      const data = await response.json();
      // Refresh projects list
      await fetchProjects();
      return data;
    } catch (error) {
      throw error;
    }
  }, [flags, fetchProjects]);

  const deleteProject = useCallback(async (projectId: string) => {
    try {
      const response = await fetch(`${flags.env.uri.api}/api/v1/crosstabs/${projectId}`, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${flags.token}`,
        },
      });
      if (!response.ok) {
        throw new Error(`Failed to delete project: ${response.statusText}`);
      }
      // Refresh projects list
      await fetchProjects();
    } catch (error) {
      throw error;
    }
  }, [flags, fetchProjects]);

  const value: AppContextValue = {
    flags,
    state,
    updateState,
    fetchProjects,
    fetchFolders,
    fetchUserSettings,
    createProject,
    updateProject,
    deleteProject,
  } as AppContextValue;

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

// Helper function to convert array to IdDict
function arrayToIdDict<T extends { id: string }>(items: T[]): IdDict<string, T> {
  const dict: IdDict<string, T> = {};
  for (const item of items) {
    dict[item.id] = item;
  }
  return dict;
}

