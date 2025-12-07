import { useEffect, useRef, useCallback } from "react";
import { useDebounce } from "./usePerformance";

interface UseAutoSaveOptions {
  onSave: () => Promise<void> | void;
  interval?: number;
  enabled?: boolean;
  onSaveStart?: () => void;
  onSaveSuccess?: () => void;
  onSaveError?: (error: Error) => void;
}

export function useAutoSave<T>(
  data: T,
  options: UseAutoSaveOptions
) {
  const {
    onSave,
    interval = 30000, // 30 seconds
    enabled = true,
    onSaveStart,
    onSaveSuccess,
    onSaveError,
  } = options;

  const previousDataRef = useRef<T>(data);
  const isSavingRef = useRef(false);
  const saveTimerRef = useRef<NodeJS.Timeout>();

  const debouncedSave = useDebounce(
    useCallback(async () => {
      if (isSavingRef.current) return;
      if (JSON.stringify(previousDataRef.current) === JSON.stringify(data)) return;

      isSavingRef.current = true;
      onSaveStart?.();

      try {
        await onSave();
        previousDataRef.current = data;
        onSaveSuccess?.();
      } catch (error) {
        onSaveError?.(error instanceof Error ? error : new Error("Save failed"));
      } finally {
        isSavingRef.current = false;
      }
    }, [data, onSave, onSaveStart, onSaveSuccess, onSaveError]),
    2000 // Debounce by 2 seconds
  );

  useEffect(() => {
    if (!enabled) return;

    // Clear existing timer
    if (saveTimerRef.current) {
      clearInterval(saveTimerRef.current);
    }

    // Set up interval-based auto-save
    saveTimerRef.current = setInterval(() => {
      debouncedSave();
    }, interval);

    return () => {
      if (saveTimerRef.current) {
        clearInterval(saveTimerRef.current);
      }
    };
  }, [enabled, interval, debouncedSave]);

  // Also save on data change (debounced)
  useEffect(() => {
    if (enabled && data !== previousDataRef.current) {
      debouncedSave();
    }
  }, [data, enabled, debouncedSave]);

  const forceSave = useCallback(async () => {
    if (isSavingRef.current) return;
    
    isSavingRef.current = true;
    onSaveStart?.();

    try {
      await onSave();
      previousDataRef.current = data;
      onSaveSuccess?.();
    } catch (error) {
      onSaveError?.(error instanceof Error ? error : new Error("Save failed"));
    } finally {
      isSavingRef.current = false;
    }
  }, [data, onSave, onSaveStart, onSaveSuccess, onSaveError]);

  return {
    forceSave,
    isSaving: isSavingRef.current,
  };
}

