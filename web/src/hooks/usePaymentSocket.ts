import { useEffect, useRef, useCallback } from "react";

const WS_URL = process.env.NEXT_PUBLIC_WS_URL || "ws://localhost:8000";

export interface PaymentUpdate {
  type: string;
  session_id: string;
  status: "pending" | "completed" | "failed" | "cancelled";
  amount?: number;
  worker_name?: string;
  mpesa_receipt?: string;
  message: string;
}

interface UsePaymentSocketOptions {
  sessionId: string | null;
  onUpdate: (update: PaymentUpdate) => void;
}

export function usePaymentSocket({
  sessionId,
  onUpdate,
}: UsePaymentSocketOptions) {
  const wsRef = useRef<WebSocket | null>(null);
  const onUpdateRef = useRef(onUpdate);

  useEffect(() => {
    onUpdateRef.current = onUpdate;
  }, [onUpdate]);

  const connect = useCallback(() => {
    if (!sessionId) return;

    const ws = new WebSocket(`${WS_URL}/ws/tips/${sessionId}`);
    wsRef.current = ws;

    ws.onopen = () => {
      console.log(`[QuickTip] WebSocket connected for session ${sessionId}`);
    };

    ws.onmessage = (event) => {
      try {
        const data: PaymentUpdate = JSON.parse(event.data);
        onUpdateRef.current(data);
      } catch {
        console.error("[QuickTip] Failed to parse WebSocket message");
      }
    };

    ws.onerror = () => {
      console.error("[QuickTip] WebSocket error");
    };

    ws.onclose = () => {
      console.log("[QuickTip] WebSocket disconnected");
    };
  }, [sessionId]);

  const disconnect = useCallback(() => {
    if (wsRef.current) {
      wsRef.current.close();
      wsRef.current = null;
    }
  }, []);

  useEffect(() => {
    if (sessionId) {
      connect();
    }
    return () => {
      disconnect();
    };
  }, [sessionId, connect, disconnect]);

  return { disconnect };
}
