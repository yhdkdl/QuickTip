"use client";

import { useSearchParams, useRouter } from "next/navigation";
import { XCircle, Zap } from "lucide-react";
import { Suspense } from "react";

function CancelledContent() {
    const searchParams = useSearchParams();
    const router = useRouter();
    const sessionId = searchParams.get("session_id");

    return (
        <div className="text-center animate-scale-in py-4">
            <div
                className="w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4"
                style={{ background: "var(--error-bg)" }}
            >
                <XCircle size={32} style={{ color: "var(--error)" }} />
            </div>
            <h2 className="text-xl font-bold mb-2" style={{ color: "var(--text-primary)" }}>
                Payment Cancelled
            </h2>
            <p className="text-sm" style={{ color: "var(--text-secondary)" }}>
                Your payment was not processed.
            </p>
            <button
                onClick={() => router.back()}
                className="mt-6 px-6 py-3 rounded-xl text-sm font-bold text-white transition-all hover:scale-105 active:scale-95"
                style={{ background: "var(--brand-green)" }}
            >
                No worries, try again
            </button>
        </div>
    );
}

export default function CancelledPage() {
    return (
        <main
            className="min-h-screen flex flex-col items-center justify-center p-4"
            style={{ background: "var(--surface)" }}
        >
            <div className="w-full max-w-[420px] relative z-10">
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
                        <CancelledContent />
                    </Suspense>
                </div>
            </div>
        </main>
    );
}