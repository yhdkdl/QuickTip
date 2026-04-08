"use client";

import { useEffect, useMemo, useState, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { CheckCircle2, Copy, Check } from "lucide-react";
import { getSessionStatus, TipSession } from "@/services/api";

function SuccessContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const sessionId = searchParams.get("session_id");
  const [session, setSession] = useState<TipSession | null>(null);
  const [loading, setLoading] = useState(true);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (!sessionId) return;
    getSessionStatus(sessionId)
      .then(setSession)
      .finally(() => setLoading(false));
  }, [sessionId]);

  const receiptCode = useMemo(() => {
    if (!session?.session_id) return "-";
    return session.session_id.replace(/-/g, "-").toUpperCase().slice(0, 14);
  }, [session?.session_id]);

  const copyReceipt = async () => {
    if (!session?.session_id) return;
    try {
      await navigator.clipboard.writeText(session.session_id);
      setCopied(true);
      setTimeout(() => setCopied(false), 1800);
    } catch {
      setCopied(false);
    }
  };

  if (loading) {
    return (
      <div className="text-center py-8">
        <div
          className="w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4"
          style={{ background: "var(--brand-green-light)", color: "var(--brand-green)" }}
        >
          <div className="animate-pulse-green">
            <CheckCircle2 size={28} />
          </div>
        </div>
        <p style={{ color: "var(--text-secondary)" }}>Confirming payment...</p>
      </div>
    );
  }

  return (
    <div className="text-center animate-scale-in py-1">
      <div className="relative mb-7">
        <div
          className="w-32 h-32 rounded-full mx-auto"
          style={{ background: "var(--brand-green-light)", opacity: 0.9 }}
        />
        <div
          className="w-20 h-20 rounded-full flex items-center justify-center absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2"
          style={{ background: "var(--brand-green)" }}
        >
          <CheckCircle2 size={44} color="white" />
        </div>
      </div>

      {session && (
        <>
          <h2 className="text-[42px] font-extrabold mb-2" style={{ color: "var(--text-primary)", lineHeight: 1.15 }}>
            ETB {session.amount} sent to {session.worker_name.split(" ")[0]}
          </h2>
          <p className="text-lg mb-7" style={{ color: "var(--text-secondary)" }}>
            Your tip was sent successfully
          </p>

          <div
            className="rounded-3xl py-5 px-5 mb-6 border"
            style={{ background: "var(--surface-2)", borderColor: "var(--border)" }}
          >
            <p className="text-sm mb-2" style={{ color: "var(--text-secondary)" }}>
              Receipt Code
            </p>
            <div className="flex items-center justify-between gap-3">
              <p className="font-mono text-2xl font-bold" style={{ color: "var(--text-primary)" }}>
                {receiptCode}
              </p>
              <button
                type="button"
                onClick={copyReceipt}
                className="w-10 h-10 rounded-xl flex items-center justify-center border transition-colors"
                style={{ borderColor: "var(--border)", color: "var(--text-secondary)", background: "white" }}
                aria-label="Copy receipt code"
              >
                {copied ? <Check size={18} /> : <Copy size={18} />}
              </button>
            </div>
          </div>

          <button
            type="button"
            onClick={() => router.push("/")}
            className="w-full rounded-[18px] py-4 text-xl font-bold text-white"
            style={{ background: "var(--brand-green)" }}
          >
            Done
          </button>
        </>
      )}
    </div>
  );
}

export default function SuccessPage() {
  return (
    <main
      className="min-h-screen flex flex-col items-center justify-center p-4 sm:p-6"
      style={{ background: "var(--surface)" }}
    >
      <div
        className="absolute top-0 left-1/2 -translate-x-1/2 w-[560px] h-[380px] pointer-events-none"
        style={{
          background: "radial-gradient(ellipse at center, rgba(0, 158, 68, 0.16) 0%, rgba(0, 158, 68, 0) 72%)",
          filter: "blur(16px)",
        }}
      />

      <div className="w-full max-w-[560px] relative z-10">
        <div
          className="rounded-[28px] p-7 sm:p-10 bg-white border shadow-[0_14px_30px_rgba(11,35,22,0.1)]"
          style={{ borderColor: "var(--border)" }}
        >
          <Suspense fallback={<div className="text-center py-8">Loading...</div>}>
            <SuccessContent />
          </Suspense>
        </div>
        <p className="text-center text-sm mt-7" style={{ color: "var(--text-secondary)" }}>
          Thank you for using <span style={{ color: "var(--brand-green)", fontWeight: 700 }}>QuickTip</span>
        </p>
      </div>
    </main>
  );
}

