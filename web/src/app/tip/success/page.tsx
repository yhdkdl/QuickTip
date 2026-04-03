"use client";

import { useEffect, useState, Suspense } from "react";
import { useSearchParams } from "next/navigation";
import { CheckCircle, Zap } from "lucide-react";
import { getSessionStatus, TipSession } from "@/services/api";

function SuccessContent() {
    const searchParams = useSearchParams();
    const sessionId = searchParams.get("session_id");
    const [session, setSession] = useState<TipSession | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (!sessionId) return;
        getSessionStatus(sessionId)
            .then(setSession)
            .finally(() => setLoading(false));
    }, [sessionId]);

    if (loading) {
        return (
            <div className="text-center py-8">
                <div className="animate-pulse-green w-12 h-12 rounded-full mx-auto mb-4"
                    style={{ background: "var(--brand-green-light)" }} />
                <p style={{ color: "var(--text-secondary)" }}>Confirming payment...</p>
            </div>
        );
    }

    return (
        <div className="text-center animate-scale-in py-4">
            <div
                className="w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4"
                style={{ background: "var(--brand-green-light)" }}
            >
                <CheckCircle size={32} style={{ color: "var(--brand-green)" }} />
            </div>
            <h2 className="text-xl font-bold mb-2" style={{ color: "var(--text-primary)" }}>
                Tip Sent! 🎉
            </h2>
            {session && (
                <>
                    <p className="text-sm mb-1" style={{ color: "var(--text-secondary)" }}>
                        ETB {session.amount} sent to {session.worker_name}
                    </p>
                    <p className="text-xs mt-4" style={{ color: "var(--text-muted)" }}>
                        Thank you for showing your appreciation
                    </p>
                </>
            )}
        </div>
    );
}

export default function SuccessPage() {
    return (
        <main
            className="min-h-screen flex flex-col items-center justify-center p-4"
            style={{ background: "var(--surface)" }}
        >
            <div className="w-full max-w-sm">
                <div className="flex items-center justify-center gap-2 mb-8">
                    <div
                        className="w-8 h-8 rounded-lg flex items-center justify-center"
                        style={{ background: "var(--brand-green)" }}
                    >
                        <Zap size={16} fill="white" stroke="none" />
                    </div>
                    <span className="font-bold text-lg" style={{ color: "var(--text-primary)" }}>
                        QuickTip
                    </span>
                </div>
                <div className="rounded-3xl p-7 glass" style={{ border: "1px solid var(--border)" }}>
                    <Suspense fallback={<div>Loading...</div>}>
                        <SuccessContent />
                    </Suspense>
                </div>
            </div>
        </main>
    );
}