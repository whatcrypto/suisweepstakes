//@ts-nocheck
import "./globals.css";
import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { Viewport } from "next";
const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Sui Template App",
  description:
    "Start your Sui journey here, without unnecessary configuration and setup. Just clone it and code on top of it. Powered by Nightly Wallet.",
};

const inter = Inter({ subsets: ["latin"] });

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
  userScalable: true,
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className} suppressHydrationWarning>
        {children}
      </body>
    </html>
  );
}
