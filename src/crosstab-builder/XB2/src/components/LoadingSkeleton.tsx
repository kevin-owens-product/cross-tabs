import React from "react";
import "./LoadingSkeleton.scss";

interface LoadingSkeletonProps {
  type?: "text" | "circle" | "rect" | "table-cell" | "project-card";
  width?: string | number;
  height?: string | number;
  className?: string;
}

export function LoadingSkeleton({
  type = "rect",
  width,
  height,
  className = "",
}: LoadingSkeletonProps) {
  const style: React.CSSProperties = {};
  if (width) style.width = typeof width === "number" ? `${width}px` : width;
  if (height) style.height = typeof height === "number" ? `${height}px` : height;

  return (
    <div
      className={`skeleton skeleton-${type} ${className}`}
      style={style}
      aria-hidden="true"
    />
  );
}

export function ProjectCardSkeleton() {
  return (
    <div className="project-card-skeleton">
      <LoadingSkeleton type="rect" height={24} className="skeleton-title" />
      <LoadingSkeleton type="text" width="60%" height={16} className="skeleton-meta" />
    </div>
  );
}

export function TableCellSkeleton() {
  return (
    <div className="table-cell-skeleton">
      <LoadingSkeleton type="rect" height={40} />
    </div>
  );
}

export function TableRowSkeleton({ columns = 5 }: { columns?: number }) {
  return (
    <tr>
      <td>
        <LoadingSkeleton type="rect" height={40} width={200} />
      </td>
      {Array.from({ length: columns }).map((_, i) => (
        <td key={i}>
          <TableCellSkeleton />
        </td>
      ))}
    </tr>
  );
}

