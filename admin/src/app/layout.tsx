import type { Metadata } from 'next';
import { Geist, Geist_Mono } from 'next/font/google';
import './globals.css';

const geistSans = Geist({ variable: '--font-geist-sans', subsets: ['latin'] });
const geistMono = Geist_Mono({ variable: '--font-geist-mono', subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'ZYNORA Admin Dashboard',
  description: 'ZYNORA Games administration console',
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ar" dir="rtl" className={`${geistSans.variable} ${geistMono.variable} h-full`}>
      <body className="min-h-full bg-[#080b17] text-white antialiased">
        <div className="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(124,77,255,0.32),_transparent_32%),radial-gradient(circle_at_bottom_left,_rgba(20,241,217,0.18),_transparent_25%),linear-gradient(180deg,#070a14_0%,#0b1122_45%,#090d1b_100%)]">
          {children}
        </div>
      </body>
    </html>
  );
}
