// Performance optimization hooks
import { useMemo, useCallback, useRef } from "react";

// Debounce hook
export function useDebounce<T extends (...args: any[]) => any>(
  callback: T,
  delay: number
): T {
  const timeoutRef = useRef<NodeJS.Timeout>();

  return useCallback(
    ((...args: Parameters<T>) => {
      if (timeoutRef.current) {
        clearTimeout(timeoutRef.current);
      }
      timeoutRef.current = setTimeout(() => {
        callback(...args);
      }, delay);
    }) as T,
    [callback, delay]
  );
}

// Throttle hook
export function useThrottle<T extends (...args: any[]) => any>(
  callback: T,
  delay: number
): T {
  const lastRun = useRef<number>(0);

  return useCallback(
    ((...args: Parameters<T>) => {
      const now = Date.now();
      if (now - lastRun.current >= delay) {
        callback(...args);
        lastRun.current = now;
      }
    }) as T,
    [callback, delay]
  );
}

// Memoized value with equality check
export function useMemoizedValue<T>(
  value: T,
  equalityFn?: (a: T, b: T) => boolean
): T {
  const ref = useRef<T>(value);
  const equality = equalityFn || ((a, b) => a === b);

  if (!equality(ref.current, value)) {
    ref.current = value;
  }

  return ref.current;
}

