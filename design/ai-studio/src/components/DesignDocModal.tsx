import React, { useState } from 'react';
import { X, Check, Copy } from 'lucide-react';
import { HiFiButton } from './common/HiFiElements';
import { ChurroMascot } from './common/Mascot';

export function DesignDocModal({
  isOpen,
  onClose,
}: {
  isOpen: boolean;
  onClose: () => void;
}) {
  const [copiedHex, setCopiedHex] = useState<string | null>(null);

  if (!isOpen) return null;

  const colors = [
    {
      hex: '#FF6B2C',
      name: 'Flame Orange',
      role: 'Primary Action & CTAs',
      textColor: 'text-white',
    },
    {
      hex: '#1F1B4D',
      name: 'Deep Indigo',
      role: 'Primary Text & Ink',
      textColor: 'text-[#FFF8EC]',
    },
    {
      hex: '#7B5CFF',
      name: 'Connections Purple',
      role: 'Game Accent: Connections',
      textColor: 'text-white',
    },
    {
      hex: '#FFC93C',
      name: 'Sunny Yellow',
      role: 'Game Accent: Word Guess (Dark text)',
      textColor: 'text-[#1F1B4D]',
    },
    {
      hex: '#19C3B1',
      name: 'Aqua',
      role: 'Game Accent: Mini Crossword',
      textColor: 'text-[#1F1B4D]',
    },
    {
      hex: '#3DDC84',
      name: 'Success Green',
      role: 'Success feedback & Solved state',
      textColor: 'text-[#1F1B4D]',
    },
    {
      hex: '#FF5C6C',
      name: 'Error Coral',
      role: 'Mistakes & warnings',
      textColor: 'text-white',
    },
    {
      hex: '#FFF8EC',
      name: 'Warm Off-White',
      role: 'App Canvas Light Mode',
      textColor: 'text-[#1F1B4D]',
    },
  ];

  const typeScale = [
    {
      level: 'Display',
      className: 'type-display',
      size: '30px · ExtraBold',
      sampleEs: '¡Hola, Sofía!',
    },
    {
      level: 'H1',
      className: 'type-h1',
      size: '24px · ExtraBold',
      sampleEs: 'la sobremesa',
    },
    {
      level: 'H2',
      className: 'type-h2',
      size: '19px · Bold',
      sampleEs: "Today's Games",
    },
    {
      level: 'H3',
      className: 'type-h3',
      size: '15px · Bold',
      sampleEs: 'Connections · Conexiones',
    },
    {
      level: 'Body & Caption',
      className: 'type-body',
      size: '13px / 11px',
      sampleEs: '70% Review · 30% New',
    },
  ];

  const handleCopyHex = (hex: string) => {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(hex);
    }
    setCopiedHex(hex);
    setTimeout(() => setCopiedHex(null), 1500);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 overflow-y-auto">
      <div className="bg-white text-[#1F1B4D] w-full max-w-2xl rounded-3xl border border-[#1F1B4D]/15 shadow-2xl overflow-hidden my-auto max-h-[90vh] flex flex-col">
        {/* Header */}
        <div className="bg-[#1F1B4D] text-[#FFF8EC] px-5 py-3.5 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-2">
            <span className="px-2.5 py-0.5 rounded-full bg-[#FF6B2C] text-white text-[11px] font-extrabold uppercase">
              DESIGN DOC
            </span>
            <h2 className="text-[16px] font-bold text-white">
              Fluent•ish Style Guide
            </h2>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-lg bg-white/10 hover:bg-white/20 text-white flex items-center justify-center cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Body */}
        <div className="p-5 overflow-y-auto space-y-6">
          {/* Palette */}
          <section className="space-y-2.5">
            <h3 className="type-h3">Color Palette (Game-Centric Scheme)</h3>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
              {colors.map((c) => (
                <div
                  key={c.hex}
                  onClick={() => handleCopyHex(c.hex)}
                  className="rounded-2xl border border-black/10 overflow-hidden cursor-pointer bg-white shadow-xs"
                >
                  <div
                    className={`h-16 p-2.5 flex items-start justify-between ${c.textColor}`}
                    style={{ backgroundColor: c.hex }}
                  >
                    <span className="text-[12px] font-extrabold">{c.hex}</span>
                    {copiedHex === c.hex ? (
                      <Check className="w-3.5 h-3.5 stroke-[3]" />
                    ) : (
                      <Copy className="w-3 h-3 opacity-70" />
                    )}
                  </div>
                  <div className="p-2.5">
                    <span className="text-[13px] font-extrabold block">{c.name}</span>
                    <span className="text-[10px] opacity-65 font-medium leading-tight block mt-0.5">
                      {c.role}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </section>

          {/* Typography */}
          <section className="space-y-2.5">
            <h3 className="type-h3">Typography — Plus Jakarta Sans</h3>
            <div className="divide-y divide-[#1F1B4D]/10 border border-[#1F1B4D]/15 rounded-2xl overflow-hidden">
              {typeScale.map((t) => (
                <div
                  key={t.level}
                  className="px-3.5 py-2.5 flex items-center justify-between gap-3"
                >
                  <div>
                    <span className="text-[12px] font-extrabold text-[#FF6B2C] block">
                      {t.level}
                    </span>
                    <span className="text-[11px] opacity-60 font-semibold">{t.size}</span>
                  </div>
                  <span className={`${t.className} text-[#1F1B4D]`}>
                    {t.sampleEs}
                  </span>
                </div>
              ))}
            </div>
          </section>

          {/* Tactile 3D Buttons */}
          <section className="space-y-2.5">
            <h3 className="type-h3">Chunky 3D Tactile Buttons</h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="p-4 rounded-2xl bg-[#FFF8EC] border border-[#1F1B4D]/15 space-y-3">
                <span className="type-caption opacity-60 block">Light Mode</span>
                <HiFiButton
                  size="lg"
                  variant="primary"
                  fullWidth
                  forceDarkMode={false}
                >
                  Play Game (Flame)
                </HiFiButton>
                <div className="grid grid-cols-3 gap-2">
                  <HiFiButton size="sm" variant="purple" forceDarkMode={false}>
                    Purple
                  </HiFiButton>
                  <HiFiButton size="sm" variant="yellow" forceDarkMode={false}>
                    Yellow
                  </HiFiButton>
                  <HiFiButton size="sm" variant="aqua" forceDarkMode={false}>
                    Aqua
                  </HiFiButton>
                </div>
              </div>

              <div className="p-4 rounded-2xl bg-[#17143A] border border-white/15 space-y-3 text-[#FFF8EC]">
                <span className="type-caption text-[#FF6B2C] block">
                  Dark Mode
                </span>
                <HiFiButton
                  size="lg"
                  variant="primary"
                  fullWidth
                  forceDarkMode={true}
                >
                  Play Game (Flame)
                </HiFiButton>
                <div className="grid grid-cols-3 gap-2">
                  <HiFiButton size="sm" variant="purple" forceDarkMode={true}>
                    Purple
                  </HiFiButton>
                  <HiFiButton size="sm" variant="yellow" forceDarkMode={true}>
                    Yellow
                  </HiFiButton>
                  <HiFiButton size="sm" variant="aqua" forceDarkMode={true}>
                    Aqua
                  </HiFiButton>
                </div>
              </div>
            </div>
          </section>

          {/* Official Mascot: Churro el Ajolote */}
          <section className="space-y-3 pt-2 border-t border-current/10">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="type-h3">Mascot · Churro el Ajolote</h3>
                <p className="text-xs opacity-65">
                  Fluent•ish official Spanish learning companion. Playful, encouraging Mexican axolotl.
                </p>
              </div>
              <span className="px-2.5 py-0.5 rounded-full text-[11px] font-extrabold uppercase tracking-wide bg-[#FF6B2C]/15 text-[#FF6B2C] border border-[#FF6B2C]/30">
                Mascot
              </span>
            </div>

            <div className="grid grid-cols-3 gap-3">
              <div className="p-3 rounded-2xl bg-black/5 dark:bg-white/5 border border-current/10 flex flex-col items-center text-center gap-2">
                <ChurroMascot mood="waving" size="sm" />
                <span className="text-[11px] font-extrabold">Waving / Greeting</span>
                <span className="text-[10px] opacity-60">Today screen header</span>
              </div>
              <div className="p-3 rounded-2xl bg-black/5 dark:bg-white/5 border border-current/10 flex flex-col items-center text-center gap-2">
                <ChurroMascot mood="celebrating" size="sm" />
                <span className="text-[11px] font-extrabold">Celebrating</span>
                <span className="text-[10px] opacity-60">Game completion screen</span>
              </div>
              <div className="p-3 rounded-2xl bg-black/5 dark:bg-white/5 border border-current/10 flex flex-col items-center text-center gap-2">
                <ChurroMascot mood="quest" size="sm" />
                <span className="text-[11px] font-extrabold">Quest Explorer</span>
                <span className="text-[10px] opacity-60">28-day Quest Path</span>
              </div>
            </div>
          </section>
        </div>
      </div>
    </div>
  );
}
