import React, { createContext, useContext, useState, useCallback, useEffect } from "react";
import { Toast, ToastContainer } from "./Toast";

interface ToastContextType {
  showToast: (type: Toast["type"], message: string, options?: { duration?: number; action?: { label: string; onClick: () => void } }) => void;
  success: (message: string, options?: Parameters<ToastContextType["showToast"]>[2]) => void;
  error: (message: string, options?: Parameters<ToastContextType["showToast"]>[2]) => void;
  warning: (message: string, options?: Parameters<ToastContextType["showToast"]>[2]) => void;
  info: (message: string, options?: Parameters<ToastContextType["showToast"]>[2]) => void;
}

const ToastContext = createContext<ToastContextType | null>(null);

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const showToast = useCallback((
    type: Toast["type"],
    message: string,
    options?: { duration?: number; action?: { label: string; onClick: () => void } }
  ) => {
    const id = `toast-${Date.now()}-${Math.random()}`;
    setToasts((prev) => [...prev, { id, type, message, ...options }]);
  }, []);

  const removeToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  return (
    <ToastContext.Provider
      value={{
        showToast,
        success: (msg, opts) => showToast("success", msg, opts),
        error: (msg, opts) => showToast("error", msg, opts),
        warning: (msg, opts) => showToast("warning", msg, opts),
        info: (msg, opts) => showToast("info", msg, opts),
      }}
    >
      {children}
      <ToastContainer toasts={toasts} onClose={removeToast} />
    </ToastContext.Provider>
  );
}

export function useToastContext() {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error("useToastContext must be used within ToastProvider");
  }
  return context;
}

