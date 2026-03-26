import { notFound } from "next/navigation";
import { Zap } from "lucide-react";

import TipCard from "@/components/TipCard";
import TipForm from "@/components/TipForm";
import { getWorkerProfile } from "@/services/api";

type WorkerPageParams = { workerId: string };

interface PageProps {
  params: WorkerPageParams | Promise<WorkerPageParams>;
}

export default async function TipPage({ params }: PageProps) {
  const { workerId } = await params;

  let worker;
  try {
    worker = await getWorkerProfile(workerId);
  } catch {
    notFound();
  }

  return (
    <main
      className="min-h-screen flex flex-col items-center justify-center p-4 relative overflow-hidden"
      style={{ background: "var(--surface)" }}
    >
      <div
        className="absolute top-0 left-1/2 -translate-x-1/2 w-96 h-96 rounded-full pointer-events-none"
        style={{
          background: "radial-gradient(circle, rgba(0,166,81,0.08) 0%, transparent 70%)",
          filter: "blur(40px)",
        }}
      />

      <div className="w-full max-w-sm relative z-10">
        <div className="flex items-center justify-center gap-2 mb-8">
          <div
            className="w-8 h-8 rounded-lg flex items-center justify-center"
            style={{ background: "var(--brand-green)" }}
          >
            <Zap size={16} fill="white" stroke="none" />
          </div>
          <span
            className="font-bold text-lg tracking-tight"
            style={{ color: "var(--text-primary)" }}
          >
            QuickTip
          </span>
        </div>

        <div
          className="rounded-3xl p-7 glass"
          style={{ border: "1px solid var(--border)" }}
        >
          <TipCard worker={worker} />

          <div
            className="my-6"
            style={{
              height: "1px",
              background:
                "linear-gradient(to right, transparent, var(--border), transparent)",
            }}
          />

          <TipForm workerId={worker.id} workerName={worker.name} />
        </div>

        <p className="text-center text-xs mt-5" style={{ color: "var(--text-muted)" }}>
          Secured by M-Pesa · Powered by QuickTip
        </p>
      </div>
    </main>
  );
}

