import React, { useState } from "react";
import "./DraggableItem.scss";

interface DraggableItemProps {
  id: string;
  children: React.ReactNode;
  onDragStart?: (id: string) => void;
  onDragEnd?: () => void;
  onDrop?: (targetId: string, sourceId: string) => void;
  className?: string;
}

export function DraggableItem({
  id,
  children,
  onDragStart,
  onDragEnd,
  onDrop,
  className = "",
}: DraggableItemProps) {
  const [isDragging, setIsDragging] = useState(false);
  const [dragOver, setDragOver] = useState(false);

  const handleDragStart = (e: React.DragEvent) => {
    setIsDragging(true);
    e.dataTransfer.effectAllowed = "move";
    e.dataTransfer.setData("text/plain", id);
    onDragStart?.(id);
  };

  const handleDragEnd = () => {
    setIsDragging(false);
    setDragOver(false);
    onDragEnd?.();
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = "move";
    setDragOver(true);
  };

  const handleDragLeave = () => {
    setDragOver(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    const sourceId = e.dataTransfer.getData("text/plain");
    if (sourceId && sourceId !== id) {
      onDrop?.(id, sourceId);
    }
  };

  return (
    <div
      draggable
      onDragStart={handleDragStart}
      onDragEnd={handleDragEnd}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
      className={`draggable-item ${isDragging ? "dragging" : ""} ${dragOver ? "drag-over" : ""} ${className}`}
    >
      {children}
    </div>
  );
}

