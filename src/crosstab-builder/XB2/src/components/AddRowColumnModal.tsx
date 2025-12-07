import React, { useState } from "react";
import { useApp } from "../context/AppContext";
import { AudienceItem } from "../types";
import { AudienceBrowser } from "./AudienceBrowser";
import { Modal } from "./Modal";
import "./AddRowColumnModal.scss";

interface AddRowColumnModalProps {
  type: "addRow" | "addColumn";
  onClose: () => void;
  onConfirm: (item: AudienceItem) => void;
}

export function AddRowColumnModal({
  type,
  onClose,
  onConfirm,
}: AddRowColumnModalProps) {
  const { flags } = useApp();
  const [name, setName] = useState("");
  const [showAudienceBrowser, setShowAudienceBrowser] = useState(false);
  const [selectedAudiences, setSelectedAudiences] = useState<AudienceItem[]>([]);

  const handleAudienceSelected = (audience: any) => {
    // Convert audience from web component to AudienceItem
    const item: AudienceItem = {
      id: audience.id || `audience-${Date.now()}`,
      definition: {
        type: "Expression",
        expression: audience.expression || {
          operator: "And",
          expressions: [],
        },
      },
      caption: {
        text: audience.name || "Untitled Audience",
      },
    };

    setSelectedAudiences([...selectedAudiences, item]);
  };

  const handleConfirm = () => {
    if (selectedAudiences.length > 0) {
      // Use selected audiences
      selectedAudiences.forEach((item) => onConfirm(item));
    } else if (name.trim()) {
      // Fallback to manual entry
      const item: AudienceItem = {
        id: `temp-${Date.now()}`,
        definition: {
          type: "Expression",
          expression: {
            operator: "And",
            expressions: [],
          },
        },
        caption: {
          text: name,
        },
      };
      onConfirm(item);
    }
  };

  if (showAudienceBrowser) {
    return (
      <div className="modal-overlay" onClick={onClose}>
        <div className="audience-browser-modal" onClick={(e) => e.stopPropagation()}>
          <AudienceBrowser
            flags={flags}
            onAudienceSelected={handleAudienceSelected}
            onClose={() => setShowAudienceBrowser(false)}
            stagedAudiences={selectedAudiences}
          />
        </div>
      </div>
    );
  }

  return (
    <Modal
      type={type}
      title={type === "addRow" ? "Add Row" : "Add Column"}
      onClose={onClose}
      onConfirm={handleConfirm}
    >
      <div className="add-row-column-modal">
        <div className="form-group">
          <label>Quick Add (Name Only)</label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Enter audience name"
            autoFocus
            onKeyPress={(e) => {
              if (e.key === "Enter") {
                handleConfirm();
              }
            }}
          />
        </div>
        <div className="divider">
          <span>OR</span>
        </div>
        <div className="form-group">
          <button
            onClick={() => setShowAudienceBrowser(true)}
            className="browser-button"
          >
            Browse Audiences
          </button>
        </div>
        {selectedAudiences.length > 0 && (
          <div className="selected-audiences">
            <h4>Selected Audiences:</h4>
            <ul>
              {selectedAudiences.map((audience, index) => (
                <li key={index}>
                  {audience.caption.text}
                  <button
                    onClick={() =>
                      setSelectedAudiences(
                        selectedAudiences.filter((_, i) => i !== index)
                      )
                    }
                    className="remove-audience"
                  >
                    ×
                  </button>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
    </Modal>
  );
}

