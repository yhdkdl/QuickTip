import { notFound } from "next/navigation";

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
      className="min-h-screen flex flex-col items-center justify-center p-4 sm:p-6 relative overflow-hidden"
      style={{ background: "var(--surface)" }}
    >
      <div
        className="absolute -top-20 left-1/2 -translate-x-1/2 w-[560px] h-[560px] rounded-full pointer-events-none"
        style={{
          background: "radial-gradient(circle, rgba(0, 158, 68, 0.14) 0%, rgba(0, 158, 68, 0) 70%)",
          filter: "blur(28px)",
        }}
      />

      <div className="w-full max-w-[420px] relative z-10 space-y-5">
        <TipCard worker={worker} />
        <TipForm workerId={worker.id} workerName={worker.name} />

        <p className="text-center text-sm pt-2" style={{ color: "var(--text-muted)" }}>
          Secured by <span style={{ color: "var(--text-secondary)", fontWeight: 600 }}>Chapa</span> · Powered by{" "}
          <span style={{ color: "var(--brand-green-dark)", fontWeight: 700 }}>QuickTip</span>
        </p>
      </div>
    </main>
  );
}
