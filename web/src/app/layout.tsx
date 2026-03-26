import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "QuickTip — Tip with M-Pesa",
  description: "Send a tip instantly using M-Pesa. No app download needed.",
  themeColor: "#00a651",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
