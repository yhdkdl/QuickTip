import { Briefcase } from "lucide-react";
import Image from "next/image";

import { WorkerPublic } from "@/services/api";

interface TipCardProps {
  worker: WorkerPublic;
}

export default function TipCard({ worker }: TipCardProps) {
  const initials = worker.name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2);

  return (
    <div className="text-center animate-slide-up">
      <div className="relative inline-block mb-4">
        <div
          className="w-24 h-24 rounded-full flex items-center justify-center text-2xl font-bold mx-auto glow-green"
          style={{
            background:
              "linear-gradient(135deg, var(--brand-green-dark), var(--brand-green))",
          }}
        >
          {worker.avatar_url ? (
            <Image
              src={worker.avatar_url}
              alt={worker.name}
              width={96}
              height={96}
              className="w-24 h-24 rounded-full object-cover"
            />
          ) : (
            <span className="text-white text-2xl font-bold">{initials}</span>
          )}
        </div>

        <div
          className="absolute -bottom-1 -right-1 w-7 h-7 rounded-full flex items-center justify-center"
          style={{
            background: "var(--brand-green)",
            border: "2px solid var(--surface)",
          }}
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="white">
            <path d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
      </div>

      <h1
        className="text-2xl font-bold mb-1"
        style={{ color: "var(--text-primary)" }}
      >
        {worker.name}
      </h1>

      {worker.profession && (
        <div
          className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-sm font-medium"
          style={{
            background: "var(--brand-green-light)",
            color: "var(--brand-green-dark)",
          }}
        >
          <Briefcase size={13} />
          {worker.profession}
        </div>
      )}

      <p
        className="mt-3 text-sm"
        style={{ color: "var(--text-secondary)" }}
      >
        Send a tip instantly with M-Pesa
      </p>
    </div>
  );
}

