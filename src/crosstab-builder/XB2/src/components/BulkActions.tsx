import React, { useState } from "react";
import { Modal } from "./Modal";
import { useToastContext } from "./ToastProvider";
import "./BulkActions.scss";

interface BulkActionsProps {
  selectedIds: string[];
  onClose: () => void;
  onDelete: (ids: string[]) => Promise<void>;
  onMoveToFolder?: (ids: string[], folderId: string | null) => Promise<void>;
  onShare?: (ids: string[]) => Promise<void>;
  onUnshare?: (ids: string[]) => Promise<void>;
  folders?: Array<{ id: string; name: string }>;
}

export function BulkActions({
  selectedIds,
  onClose,
  onDelete,
  onMoveToFolder,
  onShare,
  onUnshare,
  folders = [],
}: BulkActionsProps) {
  const toast = useToastContext();
  const [action, setAction] = useState<"delete" | "move" | "share" | "unshare" | null>(null);
  const [selectedFolderId, setSelectedFolderId] = useState<string>("");

  const handleDelete = async () => {
    try {
      await onDelete(selectedIds);
      toast.success(`Deleted ${selectedIds.length} item(s)`);
      onClose();
    } catch (error) {
      toast.error(`Failed to delete: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
  };

  const handleMove = async () => {
    if (!onMoveToFolder) return;
    try {
      await onMoveToFolder(selectedIds, selectedFolderId || null);
      toast.success(`Moved ${selectedIds.length} item(s)`);
      onClose();
    } catch (error) {
      toast.error(`Failed to move: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
  };

  const handleShare = async () => {
    if (!onShare) return;
    try {
      await onShare(selectedIds);
      toast.success(`Shared ${selectedIds.length} item(s)`);
      onClose();
    } catch (error) {
      toast.error(`Failed to share: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
  };

  const handleUnshare = async () => {
    if (!onUnshare) return;
    try {
      await onUnshare(selectedIds);
      toast.success(`Unshared ${selectedIds.length} item(s)`);
      onClose();
    } catch (error) {
      toast.error(`Failed to unshare: ${error instanceof Error ? error.message : "Unknown error"}`);
    }
  };

  return (
    <Modal
      type="bulk-actions"
      title={`Bulk Actions (${selectedIds.length} selected)`}
      onClose={onClose}
      onConfirm={() => {
        if (action === "delete") handleDelete();
        else if (action === "move") handleMove();
        else if (action === "share") handleShare();
        else if (action === "unshare") handleUnshare();
      }}
    >
      <div className="bulk-actions">
        <div className="action-buttons">
          <button
            onClick={() => setAction("delete")}
            className={`action-button ${action === "delete" ? "active" : ""}`}
          >
            Delete ({selectedIds.length})
          </button>
          {onMoveToFolder && (
            <button
              onClick={() => setAction("move")}
              className={`action-button ${action === "move" ? "active" : ""}`}
            >
              Move to Folder
            </button>
          )}
          {onShare && (
            <button
              onClick={() => setAction("share")}
              className={`action-button ${action === "share" ? "active" : ""}`}
            >
              Share ({selectedIds.length})
            </button>
          )}
          {onUnshare && (
            <button
              onClick={() => setAction("unshare")}
              className={`action-button ${action === "unshare" ? "active" : ""}`}
            >
              Unshare ({selectedIds.length})
            </button>
          )}
        </div>

        {action === "delete" && (
          <div className="action-confirmation">
            <p>Are you sure you want to delete {selectedIds.length} item(s)?</p>
            <p className="warning">This action cannot be undone.</p>
          </div>
        )}

        {action === "move" && onMoveToFolder && (
          <div className="action-options">
            <label>
              Select Folder
              <select
                value={selectedFolderId}
                onChange={(e) => setSelectedFolderId(e.target.value)}
              >
                <option value="">No Folder (Root)</option>
                {folders.map((folder) => (
                  <option key={folder.id} value={folder.id}>
                    {folder.name}
                  </option>
                ))}
              </select>
            </label>
          </div>
        )}

        {action === "share" && (
          <div className="action-confirmation">
            <p>Share {selectedIds.length} item(s) with others?</p>
          </div>
        )}

        {action === "unshare" && (
          <div className="action-confirmation">
            <p>Unshare {selectedIds.length} item(s)?</p>
          </div>
        )}
      </div>
    </Modal>
  );
}

