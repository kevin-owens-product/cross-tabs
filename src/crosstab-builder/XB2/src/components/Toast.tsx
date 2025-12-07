import React, { useEffect, useState } from "react";
import "./Toast.scss";

export type ToastType = "success" | "error" | "warning" | "info";

export interface Toast {
  id: string;
  type: ToastType;
  message: string;
  duration?: number;
  action?: {
    label: string;
    onClick: () => void;
  };
}

interface ToastProps {
  toast: Toast;
  onClose: (id: string) => void;
}

export function ToastItem({ toast, onClose }: ToastProps) {
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    setIsVisible(true);
    const duration = toast.duration ?? 5000;
    const timer = setTimeout(() => {
      setIsVisible(false);
      setTimeout(() => onClose(toast.id), 300); // Wait for animation
    }, duration);

    return () => clearTimeout(timer);
  }, [toast, onClose]);

  return (
    <div
      className={`toast toast-${toast.type} ${isVisible ? "visible" : ""}`}
      role="alert"
      aria-live={toast.type === "error" ? "assertive" : "polite"}
    >
      <div className="toast-content">
        <span className="toast-message">{toast.message}</span>
        {toast.action && (
          <button
            onClick={toast.action.onClick}
            className="toast-action"
          >
            {toast.action.label}
          </button>
        )}
      </div>
      <button
        onClick={() => {
          setIsVisible(false);
          setTimeout(() => onClose(toast.id), 300);
        }}
        className="toast-close"
        aria-label="Close notification"
      >
        ×
      </button>
    </div>
  );
}

interface ToastContainerProps {
  toasts: Toast[];
  onClose: (id: string) => void;
}

export function ToastContainer({ toasts, onClose }: ToastContainerProps) {
  return (
    <div className="toast-container" aria-live="polite" aria-atomic="true">
      {toasts.map((toast) => (
        <ToastItem key={toast.id} toast={toast} onClose={onClose} />
      ))}
    </div>
  );
}

// Toast manager hook
export function useToast() {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const showToast = (
    type: ToastType,
    message: string,
    options?: { duration?: number; action?: { label: string; onClick: () => void } }
  ) => {
    const id = `toast-${Date.now()}-${Math.random()}`;
    const newToast: Toast = {
      id,
      type,
      message,
      duration: options?.duration,
      action: options?.action,
    };

    setToasts((prev) => [...prev, newToast]);
  };

  const removeToast = (id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  };

  return {
    toasts,
    showToast,
    removeToast,
    success: (message: string, options?: Parameters<typeof showToast>[2]) =>
      showToast("success", message, options),
    error: (message: string, options?: Parameters<typeof showToast>[2]) =>
      showToast("error", message, options),
    warning: (message: string, options?: Parameters<typeof showToast>[2]) =>
      showToast("warning", message, options),
    info: (message: string, options?: Parameters<typeof showToast>[2]) =>
      showToast("info", message, options),
  };
}

