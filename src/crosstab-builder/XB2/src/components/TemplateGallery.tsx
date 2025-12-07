import React, { useState } from "react";
import { Modal } from "./Modal";
import { useToastContext } from "./ToastProvider";
import "./TemplateGallery.scss";

export interface ProjectTemplate {
  id: string;
  name: string;
  description: string;
  thumbnail?: string;
  rows: number;
  columns: number;
  createdAt: string;
  createdBy: string;
}

interface TemplateGalleryProps {
  templates: ProjectTemplate[];
  onCreateFromTemplate: (templateId: string) => Promise<void>;
  onClose: () => void;
}

export function TemplateGallery({
  templates,
  onCreateFromTemplate,
  onClose,
}: TemplateGalleryProps) {
  const toast = useToastContext();
  const [selectedTemplate, setSelectedTemplate] = useState<string | null>(null);

  const handleCreate = async () => {
    if (!selectedTemplate) return;
    try {
      await onCreateFromTemplate(selectedTemplate);
      toast.success("Project created from template");
      onClose();
    } catch (error) {
      toast.error(`Failed to create project: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
  };

  return (
    <Modal
      type="template-gallery"
      title="Project Templates"
      onClose={onClose}
      onConfirm={handleCreate}
    >
      <div className="template-gallery">
        {templates.length === 0 ? (
          <div className="empty-templates">
            <p>No templates available yet.</p>
            <p className="hint">Save a project as a template to get started.</p>
          </div>
        ) : (
          <div className="template-grid">
            {templates.map((template) => (
              <div
                key={template.id}
                className={`template-card ${selectedTemplate === template.id ? "selected" : ""}`}
                onClick={() => setSelectedTemplate(template.id)}
              >
                {template.thumbnail && (
                  <div className="template-thumbnail">
                    <img src={template.thumbnail} alt={template.name} />
                  </div>
                )}
                <div className="template-content">
                  <h3>{template.name}</h3>
                  <p className="template-description">{template.description}</p>
                  <div className="template-meta">
                    <span>{template.rows} rows × {template.columns} columns</span>
                    <span>{new Date(template.createdAt).toLocaleDateString()}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </Modal>
  );
}

