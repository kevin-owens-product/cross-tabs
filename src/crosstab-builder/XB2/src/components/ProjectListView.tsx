import React, { useState } from "react";
import { useProjectList } from "../hooks/useProjectList";
import { Tab, SortBy } from "../types/list";
import { ProjectCardSkeleton } from "./LoadingSkeleton";
import { AdvancedFilters } from "./AdvancedFilters";
import { BulkActions } from "./BulkActions";
import { TemplateGallery } from "./TemplateGallery";
import { useApp } from "../context/AppContext";
import { useToastContext } from "./ToastProvider";
import "./ProjectListView.scss";

interface ProjectListViewProps {
  onCreateProject: () => void;
  onProjectClick: (projectId: string) => void;
}

export function ProjectListView({
  onCreateProject,
  onProjectClick,
}: ProjectListViewProps) {
  const { deleteProject, state } = useApp();
  const toast = useToastContext();
  const {
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
  } = useProjectList();

  const [showSortDropdown, setShowSortDropdown] = useState(false);
  const [showFilters, setShowFilters] = useState(false);
  const [showBulkActions, setShowBulkActions] = useState(false);
  const [showTemplates, setShowTemplates] = useState(false);

  const handleProjectClick = (projectId: string, e: React.MouseEvent) => {
    if (e.ctrlKey || e.metaKey) {
      e.stopPropagation();
      toggleSelection(projectId);
    } else {
      onProjectClick(projectId);
    }
  };

  const isSelected = (projectId: string) => {
    return selection.type === "SelectedProjects" && selection.projectIds.includes(projectId);
  };

  return (
    <div className="project-list-view">
      <div className="project-list-header">
        <h1>Crosstabs</h1>
          <div className="header-actions">
          <input
            type="text"
            placeholder="Search crosstabs..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="search-input"
          />
          <button
            onClick={() => setShowFilters(true)}
            className={`filter-button ${Object.keys(filters).length > 0 ? "active" : ""}`}
            title="Advanced Filters"
          >
            🔍 Filters
          </button>
          <button
            onClick={() => setShowTemplates(true)}
            className="template-button"
            title="Browse Templates"
          >
            📋 Templates
          </button>
          <div className="sort-dropdown">
            <button
              onClick={() => setShowSortDropdown(!showSortDropdown)}
              className="sort-button"
            >
              Sort: {sortByToString(sortBy)} ▼
            </button>
            {showSortDropdown && (
              <div className="sort-menu">
                {(["NameAsc", "NameDesc", "LastModifiedAsc", "LastModifiedDesc", "CreatedAsc", "CreatedDesc", "OwnedByAsc", "OwnedByDesc"] as SortBy[]).map((option) => (
                  <button
                    key={option}
                    onClick={() => {
                      setSortBy(option);
                      setShowSortDropdown(false);
                    }}
                    className={sortBy === option ? "active" : ""}
                  >
                    {sortByToString(option)}
                  </button>
                ))}
              </div>
            )}
          </div>
          <button onClick={onCreateProject} className="create-button">
            Create Crosstab
          </button>
        </div>
      </div>

      <div className="tabs">
        {(["AllProjects", "MyProjects", "SharedProjects"] as Tab[]).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={tab === t ? "active" : ""}
          >
            {tabToString(t)}
          </button>
        ))}
      </div>

      {currentFolderId && (
        <div className="folder-breadcrumb">
          <button onClick={() => setCurrentFolderId(undefined)}>
            ← Back to All
          </button>
        </div>
      )}

      {selection.type === "SelectedProjects" && selection.projectIds.length > 0 && (
        <div className="selection-bar">
          <span>{selection.projectIds.length} selected</span>
          <button onClick={() => setShowBulkActions(true)}>Bulk Actions</button>
          <button onClick={clearSelection}>Clear</button>
        </div>
      )}

      {filteredAndSortedProjects.length === 0 && filteredFolders.length === 0 ? (
        <div className="empty-state">
          <div className="empty-state-icon">📊</div>
          <h2>No crosstabs found</h2>
          <p>
            {searchTerm
              ? "Try adjusting your search or clear filters"
              : "Create your first crosstab to start analyzing your audience data"}
          </p>
          {!searchTerm && (
            <button onClick={onCreateProject} className="create-button">
              Create Your First Crosstab
            </button>
          )}
          {searchTerm && (
            <button
              onClick={() => setSearchTerm("")}
              className="clear-search-button"
            >
              Clear Search
            </button>
          )}
        </div>
      ) : (
        <div className="project-grid">
          {filteredFolders.map((folder) => (
            <div
              key={folder.id}
              className="folder-card"
              onClick={() => setCurrentFolderId(folder.id)}
            >
              <h3>{folder.name}</h3>
              <p className="folder-meta">Folder</p>
            </div>
          ))}
          {filteredAndSortedProjects.map((project) => (
            <div
              key={project.id}
              className={`project-card ${isSelected(project.id) ? "selected" : ""}`}
              onClick={(e) => handleProjectClick(project.id, e)}
            >
              <input
                type="checkbox"
                checked={isSelected(project.id)}
                onChange={() => toggleSelection(project.id)}
                onClick={(e) => e.stopPropagation()}
                className="project-checkbox"
              />
              <div className="project-content">
                <h3>{project.name || "Untitled Crosstab"}</h3>
                <p className="project-meta">
                  Updated {formatDate(project.updatedAt)}
                </p>
              </div>
            </div>
          ))}
        </div>
      )}

      {showFilters && (
        <AdvancedFilters
          filters={filters}
          onFiltersChange={setFilters}
          onClose={() => setShowFilters(false)}
        />
      )}

      {showBulkActions && selection.type === "SelectedProjects" && (
        <BulkActions
          selectedIds={selection.projectIds}
          onClose={() => setShowBulkActions(false)}
          onDelete={async (ids) => {
            await Promise.all(ids.map(id => deleteProject(id)));
            clearSelection();
          }}
          folders={state.folders.type === "Success" ? Object.values(state.folders.data) : []}
        />
      )}

      {showTemplates && (
        <TemplateGallery
          templates={[]} // TODO: Fetch templates from API
          onCreateFromTemplate={async (templateId) => {
            // TODO: Implement template creation
            toast.info("Template creation coming soon");
            setShowTemplates(false);
          }}
          onClose={() => setShowTemplates(false)}
        />
      )}
    </div>
  );
}

function formatDate(dateString: string): string {
  const date = new Date(dateString);
  return date.toLocaleDateString();
}

function tabToString(tab: Tab): string {
  switch (tab) {
    case "AllProjects":
      return "All";
    case "MyProjects":
      return "My Crosstabs";
    case "SharedProjects":
      return "Shared";
  }
}

function sortByToString(sortBy: SortBy): string {
  switch (sortBy) {
    case "NameAsc":
      return "Name Ascending";
    case "NameDesc":
      return "Name Descending";
    case "LastModifiedAsc":
      return "Last Modified Ascending";
    case "LastModifiedDesc":
      return "Last Modified Descending";
    case "CreatedAsc":
      return "Date Created Ascending";
    case "CreatedDesc":
      return "Date Created Descending";
    case "OwnedByAsc":
      return "Owner Ascending";
    case "OwnedByDesc":
      return "Owner Descending";
  }
}

