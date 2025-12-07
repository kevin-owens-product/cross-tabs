import React from "react";
import "./Modal.scss";

interface ModalProps {
  type: string;
  onClose: () => void;
  onConfirm: () => void;
  title?: string;
  message?: string;
  children?: React.ReactNode;
}

export function Modal({
  type,
  onClose,
  onConfirm,
  title,
  message,
  children,
}: ModalProps) {
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <div className="modal-header">
          <h2>{title || "Confirm"}</h2>
          <button onClick={onClose} className="close-button">
            ×
          </button>
        </div>
        <div className="modal-body">
          {message && <p>{message}</p>}
          {children}
        </div>
        <div className="modal-footer">
          <button onClick={onClose} className="cancel-button">
            Cancel
          </button>
          <button onClick={onConfirm} className="confirm-button">
            Confirm
          </button>
        </div>
      </div>
    </div>
  );
}

