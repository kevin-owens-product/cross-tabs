import { useMemo, useState, useCallback } from "react";
import { useApp } from "../context/AppContext";
import { Tab, SortBy, Selection, ProjectOwner } from "../types/list";
import { XBProject, XBFolder, IdDict } from "../types";
import { FilterOptions } from "../components/AdvancedFilters";
import { values, get } from "../utils/idDict";

export function useProjectList() {
  const { flags, state } = useApp();
  const [tab, setTab] = useState<Tab>("AllProjects");
  const [sortBy, setSortBy] = useState<SortBy>("LastModifiedDesc");
  const [currentFolderId, setCurrentFolderId] = useState<string | undefined>();
  const [searchTerm, setSearchTerm] = useState("");
  const [selection, setSelection] = useState<Selection>({ type: "NotSelected" });
  const [filters, setFilters] = useState<FilterOptions>({});

  const filterProjects = useCallback((
    projects: XBProject[],
    folders: IdDict<string, XBFolder>
  ): XBProject[] => {
    let filtered = projects;

    // Filter by tab
    if (tab === "MyProjects") {
      filtered = filtered.filter(p => isMine(p));
    } else if (tab === "SharedProjects") {
      filtered = filtered.filter(p => !isMine(p));
    }

    // Filter by folder
    if (currentFolderId !== undefined) {
      filtered = filtered.filter(p => p.folderId === currentFolderId);
    }

    // Filter by search
    if (searchTerm.trim()) {
      const term = searchTerm.toLowerCase();
      filtered = filtered.filter(p => 
        p.name.toLowerCase().includes(term)
      );
    }

    // Filter by date range
    if (filters.dateRange?.start || filters.dateRange?.end) {
      filtered = filtered.filter(p => {
        const updatedAt = new Date(p.updatedAt);
        if (filters.dateRange?.start && updatedAt < filters.dateRange.start) {
          return false;
        }
        if (filters.dateRange?.end) {
          const endDate = new Date(filters.dateRange.end);
          endDate.setHours(23, 59, 59, 999);
          if (updatedAt > endDate) {
            return false;
          }
        }
        return true;
      });
    }

    return filtered;
  }, [tab, currentFolderId, searchTerm, filters]);

  const sortProjects = useCallback((
    projects: XBProject[]
  ): XBProject[] => {
    const sorted = [...projects];
    
    switch (sortBy) {
      case "NameAsc":
        sorted.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
        break;
      case "NameDesc":
        sorted.sort((a, b) => (b.name || "").localeCompare(a.name || ""));
        break;
      case "LastModifiedAsc":
        sorted.sort((a, b) => new Date(a.updatedAt).getTime() - new Date(b.updatedAt).getTime());
        break;
      case "LastModifiedDesc":
        sorted.sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());
        break;
      case "CreatedAsc":
        sorted.sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());
        break;
      case "CreatedDesc":
        sorted.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
        break;
      case "OwnedByAsc":
        sorted.sort((a, b) => {
          const aOwner = getProjectOwner(a);
          const bOwner = getProjectOwner(b);
          if (aOwner.type === "Me" && bOwner.type !== "Me") return 1;
          if (aOwner.type !== "Me" && bOwner.type === "Me") return -1;
          return (aOwner.type === "NotMe" ? aOwner.email : "").localeCompare(
            bOwner.type === "NotMe" ? bOwner.email : ""
          );
        });
        break;
      case "OwnedByDesc":
        sorted.sort((a, b) => {
          const aOwner = getProjectOwner(a);
          const bOwner = getProjectOwner(b);
          if (aOwner.type === "Me" && bOwner.type !== "Me") return -1;
          if (aOwner.type !== "Me" && bOwner.type === "Me") return 1;
          return (bOwner.type === "NotMe" ? bOwner.email : "").localeCompare(
            aOwner.type === "NotMe" ? aOwner.email : ""
          );
        });
        break;
    }

    return sorted;
  }, [sortBy]);

  const filteredAndSortedProjects = useMemo(() => {
    if (state.projects.type !== "Success" || state.folders.type !== "Success") {
      return [];
    }

    const allProjects = values(state.projects.data);
    const filtered = filterProjects(allProjects, state.folders.data);
    return sortProjects(filtered);
  }, [state.projects, state.folders, filterProjects, sortProjects]);

  const filteredFolders = useMemo(() => {
    if (state.folders.type !== "Success") {
      return [];
    }

    let folders = values(state.folders.data);

    // Filter by search
    if (searchTerm.trim()) {
      const term = searchTerm.toLowerCase();
      folders = folders.filter(f => f.name.toLowerCase().includes(term));
    }

    // Filter by current folder context
    if (currentFolderId !== undefined) {
      // Only show folders in current context
    }

    return folders;
  }, [state.folders, searchTerm, currentFolderId]);

  const toggleSelection = useCallback((projectId: string) => {
    setSelection(prev => {
      if (prev.type === "NotSelected") {
        return { type: "SelectedProjects", projectIds: [projectId] };
      } else {
        const index = prev.projectIds.indexOf(projectId);
        if (index >= 0) {
          const newIds = prev.projectIds.filter(id => id !== projectId);
          return newIds.length > 0 
            ? { type: "SelectedProjects", projectIds: newIds }
            : { type: "NotSelected" };
        } else {
          return { type: "SelectedProjects", projectIds: [...prev.projectIds, projectId] };
        }
      }
    });
  }, []);

  const selectAll = useCallback(() => {
    setSelection({ type: "SelectedProjects", projectIds: filteredAndSortedProjects.map(p => p.id) });
  }, [filteredAndSortedProjects]);

  const clearSelection = useCallback(() => {
    setSelection({ type: "NotSelected" });
  }, []);

  return {
    tab,
    setTab,
    sortBy,
    setSortBy,
    currentFolderId,
    setCurrentFolderId,
    searchTerm,
    setSearchTerm,
    filters,
    setFilters,
    selection,
    toggleSelection,
    selectAll,
    clearSelection,
    filteredAndSortedProjects,
    filteredFolders,
  };
}

function isMine(project: XBProject): boolean {
  // TODO: Implement based on shared field
  return project.shared === "NotShared" || (typeof project.shared === "object" && project.shared.Shared.sharees.length === 0);
}

function getProjectOwner(project: XBProject): ProjectOwner {
  // TODO: Implement based on project.owner and flags.user
  return { type: "Me" };
}

