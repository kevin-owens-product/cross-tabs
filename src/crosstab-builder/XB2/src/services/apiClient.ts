// Centralized API client with retry logic and error handling
import { Flags } from "../types";

export interface ApiError {
  message: string;
  status: number;
  data?: any;
}

export class ApiClient {
  private flags: Flags;
  private retryAttempts = 3;
  private retryDelay = 1000;

  constructor(flags: Flags) {
    this.flags = flags;
  }

  private async request<T>(
    url: string,
    options: RequestInit = {}
  ): Promise<T> {
    const fullUrl = url.startsWith("http") ? url : `${this.flags.env.uri.api}${url}`;

    const defaultHeaders: HeadersInit = {
      Authorization: `Bearer ${this.flags.token}`,
      "Content-Type": "application/json",
    };

    const config: RequestInit = {
      ...options,
      headers: {
        ...defaultHeaders,
        ...options.headers,
      },
    };

    let lastError: Error | null = null;

    for (let attempt = 0; attempt < this.retryAttempts; attempt++) {
      try {
        const response = await fetch(fullUrl, config);

        if (!response.ok) {
          if (response.status === 401) {
            // Handle unauthorized - redirect to sign out
            // @ts-ignore
            if (window.singleSpaNavigate) {
              // @ts-ignore
              window.singleSpaNavigate("/sign-out");
            }
            throw new Error("Unauthorized");
          }

          const errorData = await response.json().catch(() => ({}));
          const error: ApiError = {
            message: errorData.message || response.statusText,
            status: response.status,
            data: errorData,
          };
          throw error;
        }

        // Handle empty responses
        const contentType = response.headers.get("content-type");
        if (contentType && contentType.includes("application/json")) {
          return await response.json();
        }

        return {} as T;
      } catch (error: any) {
        lastError = error;

        // Don't retry on 4xx errors (except 429)
        if (error.status && error.status >= 400 && error.status < 500 && error.status !== 429) {
          throw error;
        }

        // Retry on network errors or 5xx errors
        if (attempt < this.retryAttempts - 1) {
          await this.delay(this.retryDelay * Math.pow(2, attempt)); // Exponential backoff
        }
      }
    }

    throw lastError || new Error("Request failed");
  }

  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  async get<T>(url: string): Promise<T> {
    return this.request<T>(url, { method: "GET" });
  }

  async post<T>(url: string, data?: any): Promise<T> {
    return this.request<T>(url, {
      method: "POST",
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async patch<T>(url: string, data?: any): Promise<T> {
    return this.request<T>(url, {
      method: "PATCH",
      body: data ? JSON.stringify(data) : undefined,
    });
  }

  async delete<T>(url: string): Promise<T> {
    return this.request<T>(url, { method: "DELETE" });
  }

  async put<T>(url: string, data?: any): Promise<T> {
    return this.request<T>(url, {
      method: "PUT",
      body: data ? JSON.stringify(data) : undefined,
    });
  }
}

