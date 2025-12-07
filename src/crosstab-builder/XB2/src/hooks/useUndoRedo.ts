// Undo/Redo hook for crosstab operations
import React from "react";

export interface UndoRedoState<T> {
  past: T[];
  present: T;
  future: T[];
}

export function useUndoRedo<T>(initialState: T) {
  const [state, setState] = React.useState<UndoRedoState<T>>({
    past: [],
    present: initialState,
    future: [],
  });

  const canUndo = state.past.length > 0;
  const canRedo = state.future.length > 0;

  const undo = React.useCallback(() => {
    if (!canUndo) return;

    setState((current) => {
      const previous = current.past[current.past.length - 1];
      const newPast = current.past.slice(0, -1);
      return {
        past: newPast,
        present: previous,
        future: [current.present, ...current.future],
      };
    });
  }, [canUndo]);

  const redo = React.useCallback(() => {
    if (!canRedo) return;

    setState((current) => {
      const next = current.future[0];
      const newFuture = current.future.slice(1);
      return {
        past: [...current.past, current.present],
        present: next,
        future: newFuture,
      };
    });
  }, [canRedo]);

  const setStateWithHistory = React.useCallback((newState: T) => {
    setState((current) => ({
      past: [...current.past, current.present].slice(-50), // Keep last 50 states
      present: newState,
      future: [],
    }));
  }, []);

  const clearHistory = React.useCallback(() => {
    setState({
      past: [],
      present: state.present,
      future: [],
    });
  }, [state.present]);

  return {
    state: state.present,
    setState: setStateWithHistory,
    undo,
    redo,
    canUndo,
    canRedo,
    clearHistory,
  };
}
