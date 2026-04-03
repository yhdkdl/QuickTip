"use client";

import { useState, useCallback } from "react";
import { Phone, Banknote, ArrowRight, XCircle, ExternalLink } from "lucide-react";
import { initiateTip } from "@/services/api";
import { usePaymentSocket, PaymentUpdate } from "@/hooks/usePaymentSocket";
import LoadingSpinner from "./LoadingSpinner";

interface TipFormProps {
  workerId: string;
  workerName: string;
}

const PRESET_AMOUNTS = [50, 100, 200, 500];

type Stage = "form" | "loading" | "redirecting";

export default function TipForm({ workerId, workerName }: TipFormProps) {
  const [amount, setAmount] = useState<string>("");
  const [phone, setPhone] = useState<string>("");
  const [email, setEmail] = useState<string>("");
  const [stage, setStage] = useState<Stage>("form");
  const [socketSessionId, setSocketSessionId] = useState<string | null>(null);
  const [error, setError] = useState<string>("");

  const handlePaymentUpdate = useCallback((update: PaymentUpdate) => {
    if (update.status === "completed" || update.status === "failed") {
      setSocketSessionId(null);
    }
  }, []);

  usePaymentSocket({
    sessionId: socketSessionId,
    onUpdate: handlePaymentUpdate,
  });

  const formatPhone = (value: string): string => {
    return value.replace(/\D/g, "");
  };

  const handleSubmit = async () => {
    setError("");

    const amountNum = parseFloat(amount);
    if (!amountNum || amountNum < 1) {
      setError("Please enter a valid tip amount");
      return;
    }

    const phoneClean = phone.replace(/\D/g, "");
    const phoneRegex = /^(09|07)\d{8}$|^(2519|2517)\d{8}$/;
    if (!phoneRegex.test(phoneClean)) {
      setError("Please enter a valid Ethiopian phone number (e.g. 0911 234 567)");
      return;
    }

    setStage("loading");

    try {
      const result = await initiateTip({
        worker_id: workerId,
        amount: amountNum,
        customer_phone: phoneClean,
        customer_email: email || undefined,
        initiated_via: "qr",
      });

      setSocketSessionId(result.session_id);
      setStage("redirecting");

      if (result.checkout_url) {
        setTimeout(() => {
          window.location.href = result.checkout_url!;
        }, 1500);
      }
    } catch (err: unknown) {
      setStage("form");
      setError(err instanceof Error ? err.message : "Something went wrong");
    }
  };

  if (stage === "redirecting") {
    return (
      <div className="text-center animate-scale-in py-4">
        <div className="animate-float mb-4">
          <div
            className="w-16 h-16 rounded-full flex items-center justify-center mx-auto"
            style={{ background: "var(--brand-green-light)" }}
          >
            <ExternalLink size={28} style={{ color: "var(--brand-green)" }} />
          </div>
        </div>
        <h2 className="text-xl font-bold mb-2" style={{ color: "var(--text-primary)" }}>
          Redirecting to Chapa
        </h2>
        <p className="text-sm mb-4" style={{ color: "var(--text-secondary)" }}>
          You will be taken to Chapa's secure payment page to complete your ETB {amount} tip
        </p>
        <div
          className="flex items-center justify-center gap-2 text-xs py-2 px-4 rounded-full mx-auto w-fit"
          style={{ background: "var(--surface-3)", color: "var(--text-muted)" }}
        >
          <LoadingSpinner size={14} />
          Taking you there...
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-5 animate-slide-up">
      <div>
        <p className="text-xs font-semibold uppercase tracking-wider mb-3"
          style={{ color: "var(--text-muted)" }}>
          Quick amounts (ETB)
        </p>
        <div className="grid grid-cols-4 gap-2">
          {PRESET_AMOUNTS.map((preset) => (
            <button
              key={preset}
              onClick={() => setAmount(String(preset))}
              className="py-2.5 rounded-xl text-sm font-semibold transition-all duration-200"
              style={{
                background: amount === String(preset)
                  ? "var(--brand-green)"
                  : "var(--surface-3)",
                color: amount === String(preset)
                  ? "white"
                  : "var(--text-secondary)",
                border: amount === String(preset)
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
        <label className="text-xs font-semibold uppercase tracking-wider block mb-2"
          style={{ color: "var(--text-muted)" }}>
          Amount (ETB)
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
            onFocus={(e) => { e.target.style.borderColor = "var(--brand-green)"; }}
            onBlur={(e) => { e.target.style.borderColor = "var(--border)"; }}
          />
        </div>
      </div>

      <div>
        <label className="text-xs font-semibold uppercase tracking-wider block mb-2"
          style={{ color: "var(--text-muted)" }}>
          Your Phone Number
        </label>
        <div className="relative">
          <div className="absolute left-4 top-1/2 -translate-y-1/2">
            <Phone size={18} style={{ color: "var(--text-muted)" }} />
          </div>
          <input
            type="tel"
            placeholder="09XX XXX XXXX"
            value={phone}
            onChange={(e) => setPhone(formatPhone(e.target.value))}
            className="w-full pl-11 pr-4 py-3.5 rounded-xl text-sm font-medium outline-none transition-all duration-200"
            style={{
              background: "var(--surface-3)",
              border: "1px solid var(--border)",
              color: "var(--text-primary)",
            }}
            onFocus={(e) => { e.target.style.borderColor = "var(--brand-green)"; }}
            onBlur={(e) => { e.target.style.borderColor = "var(--border)"; }}
          />
        </div>
      </div>

      <div>
        <label className="text-xs font-semibold uppercase tracking-wider block mb-2"
          style={{ color: "var(--text-muted)" }}>
          Email (optional — for receipt)
        </label>
        <input
          type="email"
          placeholder="you@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="w-full px-4 py-3.5 rounded-xl text-sm font-medium outline-none transition-all duration-200"
          style={{
            background: "var(--surface-3)",
            border: "1px solid var(--border)",
            color: "var(--text-primary)",
          }}
          onFocus={(e) => { e.target.style.borderColor = "var(--brand-green)"; }}
          onBlur={(e) => { e.target.style.borderColor = "var(--border)"; }}
        />
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
          background: stage === "loading"
            ? "var(--surface-4)"
            : "linear-gradient(135deg, var(--brand-green-dark), var(--brand-green))",
          cursor: stage === "loading" ? "not-allowed" : "pointer",
        }}
      >
        {stage === "loading" ? (
          <>
            <LoadingSpinner size={18} />
            Preparing payment...
          </>
        ) : (
          <>
            Pay ETB {amount || "0"} with Chapa
            <ArrowRight size={18} />
          </>
        )}
      </button>

      <p className="text-center text-xs" style={{ color: "var(--text-muted)" }}>
        Supports Telebirr & Bank Transfer
      </p>
    </div>
  );
}