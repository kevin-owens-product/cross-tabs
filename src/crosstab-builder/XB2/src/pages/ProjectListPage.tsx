import React, { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useApp } from "../context/AppContext";
import { ProjectListView } from "../components/ProjectListView";
import { buildCrosstabsUrl } from "../utils/navigation";
import "./ProjectListPage.scss";

export function ProjectListPage() {
  const { flags, fetchProjects, fetchFolders } = useApp();
  const navigate = useNavigate();

  useEffect(() => {
    fetchProjects();
    fetchFolders();
  }, [fetchProjects, fetchFolders]);

  const handleCreateProject = () => {
    const url = buildCrosstabsUrl("/new", flags);
    navigate("/new");
    // Also update single-spa URL
    // @ts-ignore
    if (window.singleSpaNavigate) {
      // @ts-ignore
      window.singleSpaNavigate(url);
    }
  };

  const handleProjectClick = (projectId: string) => {
    const url = buildCrosstabsUrl(`/${projectId}`, flags);
    navigate(`/${projectId}`);
    // Also update single-spa URL
    // @ts-ignore
    if (window.singleSpaNavigate) {
      // @ts-ignore
      window.singleSpaNavigate(url);
    }
  };

  return (
    <div className="project-list-page">
      <ProjectListView
        onCreateProject={handleCreateProject}
        onProjectClick={handleProjectClick}
      />
    </div>
  );
}

