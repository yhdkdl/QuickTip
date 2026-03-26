"use client";

import { useState } from "react";
import type { ChangeEvent } from "react";
import {
  ArrowRight,
  Banknote,
  CheckCircle,
  Phone,
  XCircle,
} from "lucide-react";

import { getSessionStatus, initiateTip, TipSession } from "@/services/api";
import LoadingSpinner from "./LoadingSpinner";

interface TipFormProps {
  workerId: string;
  workerName: string;
}

const PRESET_AMOUNTS = [50, 100, 200, 500];

type Stage = "form" | "loading" | "pending" | "completed" | "failed";

export default function TipForm({ workerId, workerName }: TipFormProps) {
  const [amount, setAmount] = useState<string>("");
  const [phone, setPhone] = useState<string>("");
  const [stage, setStage] = useState<Stage>("form");
  const [session, setSession] = useState<TipSession | null>(null);
  const [error, setError] = useState<string>("");

  const formatPhone = (value: string) => {
    const digits = value.replace(/\D/g, "");
    if (digits.startsWith("0") && digits.length <= 10) {
      return "254" + digits.slice(1);
    }
    return digits;
  };

  const displayPhone = (value: string) => {
    if (value.startsWith("254")) return "0" + value.slice(3);
    return value;
  };

  const handlePhoneChange = (e: ChangeEvent<HTMLInputElement>) => {
    const raw = e.target.value;
    setPhone(formatPhone(raw));
  };

  const pollStatus = async (sessionId: string) => {
    setStage("pending");
    let attempts = 0;
    const maxAttempts = 24;

    const interval = setInterval(async () => {
      attempts++;
      try {
        const updated = await getSessionStatus(sessionId);
        setSession(updated);

        if (updated.status === "completed") {
          clearInterval(interval);
          setStage("completed");
        } else if (
          updated.status === "failed" ||
          updated.status === "cancelled"
        ) {
          clearInterval(interval);
          setStage("failed");
        } else if (attempts >= maxAttempts) {
          clearInterval(interval);
          setStage("failed");
          setError("Payment timed out. Please try again.");
        }
      } catch {
        clearInterval(interval);
        setStage("failed");
        setError("Could not verify payment status.");
      }
    }, 5000);
  };

  const handleSubmit = async () => {
    setError("");

    const amountNum = parseFloat(amount);
    if (!amountNum || amountNum < 1) {
      setError("Please enter a valid tip amount");
      return;
    }

    const phoneRegex = /^2547\d{8}$|^2541\d{8}$/;
    if (!phoneRegex.test(phone)) {
      setError("Please enter a valid Safaricom number (e.g. 0712 345678)");
      return;
    }

    setStage("loading");

    try {
      const result = await initiateTip({
        worker_id: workerId,
        amount: amountNum,
        customer_phone: phone,
        initiated_via: "qr",
      });

      setSession(result);
      await pollStatus(result.session_id);
    } catch (err: unknown) {
      setStage("form");
      setError(err instanceof Error ? err.message : "Something went wrong");
    }
  };

  if (stage === "completed") {
    return (
      <div className="text-center animate-scale-in py-4">
        <div
          className="w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4"
          style={{ background: "var(--brand-green-light)" }}
        >
          <CheckCircle size={32} style={{ color: "var(--brand-green)" }} />
        </div>
        <h2
          className="text-xl font-bold mb-2"
          style={{ color: "var(--text-primary)" }}
        >
          Tip Sent! 🎉
        </h2>
        <p
          className="text-sm mb-1"
          style={{ color: "var(--text-secondary)" }}
        >
          KES {session?.amount} sent to {workerName}
        </p>
        <p className="text-xs" style={{ color: "var(--text-muted)" }}>
          Thank you for showing your appreciation
        </p>
        <button
          onClick={() => {
            setStage("form");
            setAmount("");
            setPhone("");
            setSession(null);
          }}
          className="mt-6 text-sm font-medium underline"
          style={{ color: "var(--brand-green)" }}
        >
          Send another tip
        </button>
      </div>
    );
  }

  if (stage === "failed") {
    return (
      <div className="text-center animate-scale-in py-4">
        <div
          className="w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4"
          style={{ background: "var(--error-bg)" }}
        >
          <XCircle size={32} style={{ color: "var(--error)" }} />
        </div>
        <h2
          className="text-xl font-bold mb-2"
          style={{ color: "var(--text-primary)" }}
        >
          Payment Failed
        </h2>
        <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
          {error || "The payment was not completed. Please try again."}
        </p>
        <button
          onClick={() => {
            setStage("form");
            setError("");
            setSession(null);
          }}
          className="mt-6 px-6 py-2.5 rounded-xl text-sm font-semibold text-white"
          style={{ background: "var(--brand-green)" }}
        >
          Try Again
        </button>
      </div>
    );
  }

  if (stage === "pending") {
    return (
      <div className="text-center animate-scale-in py-4">
        <div className="animate-float mb-4">
          <div
            className="w-16 h-16 rounded-full flex items-center justify-center mx-auto"
            style={{ background: "var(--brand-green-light)" }}
          >
            <Phone size={28} style={{ color: "var(--brand-green)" }} />
          </div>
        </div>
        <h2
          className="text-xl font-bold mb-2"
          style={{ color: "var(--text-primary)" }}
        >
          Check Your Phone
        </h2>
        <p
          className="text-sm mb-4"
          style={{ color: "var(--text-secondary)" }}
        >
          An M-Pesa prompt has been sent to{" "}
          <span
            className="font-semibold"
            style={{ color: "var(--text-primary)" }}
          >
            {displayPhone(phone)}
          </span>
        </p>
        <p className="text-xs mb-6" style={{ color: "var(--text-muted)" }}>
          Enter your M-Pesa PIN to complete the tip
        </p>
        <div
          className="flex items-center justify-center gap-2 text-xs py-2 px-4 rounded-full mx-auto w-fit"
          style={{ background: "var(--surface-3)", color: "var(--text-muted)" }}
        >
          <LoadingSpinner size={14} />
          Waiting for confirmation...
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-5 animate-slide-up">
      <div>
        <p
          className="text-xs font-semibold uppercase tracking-wider mb-3"
          style={{ color: "var(--text-muted)" }}
        >
          Quick amounts
        </p>
        <div className="grid grid-cols-4 gap-2">
          {PRESET_AMOUNTS.map((preset) => (
            <button
              key={preset}
              onClick={() => setAmount(String(preset))}
              className="py-2.5 rounded-xl text-sm font-semibold transition-all duration-200"
              style={{
                background:
                  amount === String(preset)
                    ? "var(--brand-green)"
                    : "var(--surface-3)",
                color:
                  amount === String(preset)
                    ? "white"
                    : "var(--text-secondary)",
                border:
                  amount === String(preset)
                    ? "1px solid var(--brand-green)"
                    : "1px solid var(--border)",
              }}
            >
              {preset}
            </button>
          ))}
        </div>
      </div>

      <div>
        <label
          className="text-xs font-semibold uppercase tracking-wider block mb-2"
          style={{ color: "var(--text-muted)" }}
        >
          Amount (KES)
        </label>
        <div className="relative">
          <div className="absolute left-4 top-1/2 -translate-y-1/2">
            <Banknote size={18} style={{ color: "var(--text-muted)" }} />
          </div>
          <input
            type="number"
            placeholder="Enter amount"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            min={1}
            className="w-full pl-11 pr-4 py-3.5 rounded-xl text-sm font-medium outline-none transition-all duration-200"
            style={{
              background: "var(--surface-3)",
              border: "1px solid var(--border)",
              color: "var(--text-primary)",
            }}
            onFocus={(e) => {
              e.target.style.borderColor = "var(--brand-green)";
            }}
            onBlur={(e) => {
              e.target.style.borderColor = "var(--border)";
            }}
          />
        </div>
      </div>

      <div>
        <label
          className="text-xs font-semibold uppercase tracking-wider block mb-2"
          style={{ color: "var(--text-muted)" }}
        >
          Your M-Pesa Number
        </label>
        <div className="relative">
          <div className="absolute left-4 top-1/2 -translate-y-1/2">
            <Phone size={18} style={{ color: "var(--text-muted)" }} />
          </div>
          <input
            type="tel"
            placeholder="07XX XXX XXX"
            value={displayPhone(phone)}
            onChange={handlePhoneChange}
            className="w-full pl-11 pr-4 py-3.5 rounded-xl text-sm font-medium outline-none transition-all duration-200"
            style={{
              background: "var(--surface-3)",
              border: "1px solid var(--border)",
              color: "var(--text-primary)",
            }}
            onFocus={(e) => {
              e.target.style.borderColor = "var(--brand-green)";
            }}
            onBlur={(e) => {
              e.target.style.borderColor = "var(--border)";
            }}
          />
        </div>
        <p className="text-xs mt-1.5" style={{ color: "var(--text-muted)" }}>
          You will receive an M-Pesa prompt on this number
        </p>
      </div>

      {error && (
        <div
          className="flex items-center gap-2 px-4 py-3 rounded-xl text-sm animate-scale-in"
          style={{ background: "var(--error-bg)", color: "var(--error)" }}
        >
          <XCircle size={16} />
          {error}
        </div>
      )}

      <button
        onClick={handleSubmit}
        disabled={stage === "loading"}
        className="w-full py-4 rounded-xl font-bold text-white flex items-center justify-center gap-2 transition-all duration-200 active:scale-95"
        style={{
          background:
            stage === "loading"
              ? "var(--surface-4)"
              : "linear-gradient(135deg, var(--brand-green-dark), var(--brand-green))",
          cursor: stage === "loading" ? "not-allowed" : "pointer",
        }}
      >
        {stage === "loading" ? (
          <>
            <LoadingSpinner size={18} />
            Sending STK Push...
          </>
        ) : (
          <>
            Pay KES {amount || "0"} with M-Pesa
            <ArrowRight size={18} />
          </>
        )}
      </button>
    </div>
  );
}

