import React, { useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { useApp } from "../context/AppContext";
import { ProjectDetailView } from "../components/ProjectDetailView";
import { buildCrosstabsUrl } from "../utils/navigation";
import "./ProjectDetailPage.scss";

export function ProjectDetailPage() {
  const { projectId } = useParams<{ projectId?: string }>();
  const navigate = useNavigate();
  const { flags, state, fetchProjects } = useApp();

  useEffect(() => {
    if (projectId && projectId !== "new") {
      // Fetch project if needed
      fetchProjects();
    }
  }, [projectId, fetchProjects]);

  const handleBack = () => {
    const url = buildCrosstabsUrl("/", flags);
    navigate("/");
    // Also update single-spa URL
    // @ts-ignore
    if (window.singleSpaNavigate) {
      // @ts-ignore
      window.singleSpaNavigate(url);
    }
  };

  const handleSave = () => {
    // TODO: Implement save functionality
  };

  return (
    <div className="project-detail-page">
      <ProjectDetailView
        projectId={projectId === "new" ? undefined : projectId}
        onBack={handleBack}
        onSave={handleSave}
      />
    </div>
  );
}

