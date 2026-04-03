const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

export interface WorkerPublic {
  id: string;
  name: string;
  profession: string | null;
  avatar_url: string | null;
  qr_code_url: string | null;
}

export interface TipSession {
  session_id: string;
  status: string;
  amount: number;
  worker_name: string;
  message: string;
  checkout_url?: string;
}

export interface TipPayload {
  worker_id: string;
  amount: number;
  customer_phone: string;
  customer_email?: string;
  initiated_via: string;
}

export async function getWorkerProfile(workerId: string): Promise<WorkerPublic> {
  const res = await fetch(`${API_URL}/api/v1/workers/${workerId}`, {
    cache: "no-store",
  });
  if (!res.ok) throw new Error("Worker not found");
  return res.json();
}

export async function initiateTip(payload: TipPayload): Promise<TipSession> {
  const res = await fetch(`${API_URL}/api/v1/tips/initiate`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  if (!res.ok) {
    const err = await res.json();
    throw new Error(err.detail || "Failed to initiate payment");
  }
  return res.json();
}

export async function getSessionStatus(sessionId: string): Promise<TipSession> {
  const res = await fetch(`${API_URL}/api/v1/tips/session/${sessionId}`, {
    cache: "no-store",
  });
  if (!res.ok) throw new Error("Session not found");
  return res.json();
}