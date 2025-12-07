import React, { useState, useEffect } from "react";
import { Modal } from "./Modal";
import "./KeyboardShortcuts.scss";

interface Shortcut {
  keys: string[];
  description: string;
  category: string;
}

const shortcuts: Shortcut[] = [
  {
    keys: ["Ctrl", "Z"],
    description: "Undo last action",
    category: "Editing",
  },
  {
    keys: ["Ctrl", "Y"],
    description: "Redo last undone action",
    category: "Editing",
  },
  {
    keys: ["Ctrl", "S"],
    description: "Save project",
    category: "File",
  },
  {
    keys: ["Ctrl", "?"],
    description: "Show keyboard shortcuts",
    category: "Help",
  },
  {
    keys: ["Esc"],
    description: "Close modal or cancel action",
    category: "Navigation",
  },
  {
    keys: ["Ctrl", "F"],
    description: "Focus search",
    category: "Navigation",
  },
  {
    keys: ["Ctrl", "N"],
    description: "Create new project",
    category: "File",
  },
  {
    keys: ["Delete"],
    description: "Delete selected items",
    category: "Editing",
  },
];

export function KeyboardShortcutsModal({ onClose }: { onClose: () => void }) {
  const groupedShortcuts = shortcuts.reduce((acc, shortcut) => {
    if (!acc[shortcut.category]) {
      acc[shortcut.category] = [];
    }
    acc[shortcut.category].push(shortcut);
    return acc;
  }, {} as Record<string, Shortcut[]>);

  return (
    <Modal
      type="keyboard-shortcuts"
      title="Keyboard Shortcuts"
      onClose={onClose}
      onConfirm={onClose}
    >
      <div className="keyboard-shortcuts">
        {Object.entries(groupedShortcuts).map(([category, items]) => (
          <div key={category} className="shortcut-category">
            <h3>{category}</h3>
            <div className="shortcut-list">
              {items.map((shortcut, index) => (
                <div key={index} className="shortcut-item">
                  <span className="shortcut-description">{shortcut.description}</span>
                  <div className="shortcut-keys">
                    {shortcut.keys.map((key, keyIndex) => (
                      <React.Fragment key={keyIndex}>
                        <kbd>{key}</kbd>
                        {keyIndex < shortcut.keys.length - 1 && (
                          <span className="key-separator">+</span>
                        )}
                      </React.Fragment>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </Modal>
  );
}

export function useKeyboardShortcuts() {
  const [showShortcuts, setShowShortcuts] = useState(false);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Cmd/Ctrl + ? or Shift + ?
      if ((e.ctrlKey || e.metaKey) && e.key === "?") {
        e.preventDefault();
        setShowShortcuts(true);
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  return {
    showShortcuts,
    setShowShortcuts,
  };
}

