import React, { useState } from 'react';

export type MascotMood =
  | 'waving'
  | 'celebrating'
  | 'quest'
  | 'thinking'
  | 'proud'
  | 'encouraging';

interface MascotProps {
  mood?: MascotMood;
  size?: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  speech?: string;
  speechPosition?: 'top' | 'right' | 'left' | 'bottom';
  className?: string;
  animate?: boolean;
  idle?: boolean;
  onClick?: () => void;
}

export const CELEBRATION_CHEERS = [
  '¡Buen trabajo! · Great job! 🎉',
  '¡Lo lograste! · You did it! 🌟',
  '¡Increíble! · Amazing! ✨',
  '¡De rechupete! · Splendid! 🏆',
  '¡Qué crack! · You are a natural! 🔥',
  '¡Frase perfecta! · Flawless! 🎯',
];

export const ENCOURAGING_CHEERS = [
  '¡Casi casi! · Almost there! 💪',
  '¡Buen intento! · Good try! 💡',
  '¡Ánimo! Sigue probando · Keep going! ☕',
  '¡No pasa nada! · You got this! ✨',
  '¡Cerca! Una más · So close! 🎯',
];

export function getRandomCelebrationCheer(customMsg?: string): string {
  if (customMsg) return customMsg;
  const idx = Math.floor(Math.random() * CELEBRATION_CHEERS.length);
  return CELEBRATION_CHEERS[idx];
}

export function getRandomEncouragingCheer(): string {
  const idx = Math.floor(Math.random() * ENCOURAGING_CHEERS.length);
  return ENCOURAGING_CHEERS[idx];
}

/**
 * Lumi the Axolotl — The Official Fluent•ish Mascot
 * 
 * Personality:
 * Spirited, playful, and universally welcoming. Lumi has feathery external gill plumes
 * in the Fluent•ish palette (Flame Orange #FF6B2C, Royal Purple #7B5CFF, and Teal #19C3B1).
 * Lumi wears a dapper teal bandana and believes that being "fluent-ish" with daily play
 * is better than boring perfection.
 */
export function ChurroMascot({
  mood = 'waving',
  size = 'md',
  speech,
  speechPosition = 'top',
  className = '',
  animate = true,
  idle = true,
  onClick,
}: MascotProps) {
  const [isWiggling, setIsWiggling] = useState(false);

  // Size mappings (in pixels for the mascot graphic)
  const sizeMap = {
    xs: 32,
    sm: 44,
    md: 68,
    lg: 96,
    xl: 128,
  };

  const px = sizeMap[size];

  const handleClick = () => {
    setIsWiggling(true);
    setTimeout(() => setIsWiggling(false), 600);
    onClick?.();
  };

  // Determine dynamic animation classes based on mood and idle settings
  const getAnimationClasses = () => {
    if (isWiggling) return 'animate-bounce';
    if (mood === 'celebrating') return 'animate-churro-dance';
    if (mood === 'encouraging') return 'animate-churro-encourage';
    if (idle) return 'animate-churro-breathe animate-churro-tilt';
    return '';
  };

  return (
    <div
      className={`inline-flex items-center select-none ${
        speechPosition === 'top'
          ? 'flex-col'
          : speechPosition === 'bottom'
          ? 'flex-col-reverse'
          : speechPosition === 'left'
          ? 'flex-row-reverse'
          : 'flex-row'
      } gap-2 ${className}`}
    >
      {/* Optional Speech Bubble */}
      {speech && (
        <div
          className={`relative px-3 py-1.5 rounded-2xl bg-white dark:bg-[#221E52] border border-[#FF6B2C]/30 text-[#1F1B4D] dark:text-[#FFF8EC] shadow-sm text-[12px] font-bold max-w-[230px] leading-tight animate-fade-in ${
            speechPosition === 'top' ? 'mb-1' : ''
          }`}
        >
          <span>{speech}</span>
          {/* Bubble Pointer Triangle */}
          {speechPosition === 'top' && (
            <div className="absolute left-1/2 -bottom-1.5 -translate-x-1/2 w-3 h-3 bg-white dark:bg-[#221E52] border-r border-b border-[#FF6B2C]/30 rotate-45" />
          )}
          {speechPosition === 'right' && (
            <div className="absolute -left-1.5 top-1/2 -translate-y-1/2 w-3 h-3 bg-white dark:bg-[#221E52] border-l border-b border-[#FF6B2C]/30 rotate-45" />
          )}
          {speechPosition === 'left' && (
            <div className="absolute -right-1.5 top-1/2 -translate-y-1/2 w-3 h-3 bg-white dark:bg-[#221E52] border-r border-t border-[#FF6B2C]/30 rotate-45" />
          )}
        </div>
      )}

      {/* Churro Vector Graphic with Idle Bobbing, Breathing & Tilting */}
      <div
        onClick={handleClick}
        style={{ width: px, height: px }}
        title="Lumi · Fluent•ish Mascot"
        className={`relative shrink-0 cursor-pointer transition-transform duration-200 active:scale-95 ${
          animate ? 'hover:scale-105' : ''
        } ${getAnimationClasses()}`}
      >
        <svg
          viewBox="0 0 100 100"
          fill="none"
          xmlns="http://www.w3.org/2000/svg"
          className="w-full h-full drop-shadow-xs"
        >
          {/* DEFINITIONS: Gradients and Shadows */}
          <defs>
            {/* Body skin gradient: Warm Peach to Cream */}
            <linearGradient id="churroBody" x1="50" y1="20" x2="50" y2="90" gradientUnits="userSpaceOnUse">
              <stop offset="0%" stopColor="#FFEBD2" />
              <stop offset="100%" stopColor="#FFD6A5" />
            </linearGradient>

            {/* Belly highlight */}
            <radialGradient id="churroBelly" cx="50" cy="74" r="16" gradientUnits="userSpaceOnUse">
              <stop offset="0%" stopColor="#FFF8EC" />
              <stop offset="100%" stopColor="#FFEBD2" />
            </radialGradient>
          </defs>

          {/* 1. EXTERNAL GILLS (FEATHERED CREST with organic underwater flutter) */}
          <g className={idle ? 'animate-churro-flutter' : ''}>
            {/* Left Gills */}
            {/* Top Gill Left (Flame Orange) */}
            <path
              d="M 32 36 C 20 28 8 32 10 20 C 14 16 26 24 33 30"
              fill="#FF6B2C"
              stroke="#1F1B4D"
              strokeWidth="2"
              strokeLinejoin="round"
            />
            <path d="M 12 21 C 16 22 22 26 28 29" stroke="#FFA07A" strokeWidth="1.5" strokeLinecap="round" />

            {/* Middle Gill Left (Royal Purple) */}
            <path
              d="M 28 46 C 14 42 6 48 8 38 C 12 34 22 40 28 43"
              fill="#7B5CFF"
              stroke="#1F1B4D"
              strokeWidth="2"
              strokeLinejoin="round"
            />
            <path d="M 10 39 C 14 40 20 42 26 43" stroke="#B8A5FF" strokeWidth="1.5" strokeLinecap="round" />

            {/* Bottom Gill Left (Teal Aqua) */}
            <path
              d="M 30 56 C 18 56 12 66 14 58 C 16 54 24 54 29 53"
              fill="#19C3B1"
              stroke="#1F1B4D"
              strokeWidth="2"
              strokeLinejoin="round"
            />

            {/* Right Gills */}
            {/* Top Gill Right (Flame Orange) */}
            <path
              d="M 68 36 C 80 28 92 32 90 20 C 86 16 74 24 67 30"
              fill="#FF6B2C"
              stroke="#1F1B4D"
              strokeWidth="2"
              strokeLinejoin="round"
            />
            <path d="M 88 21 C 84 22 78 26 72 29" stroke="#FFA07A" strokeWidth="1.5" strokeLinecap="round" />

            {/* Middle Gill Right (Royal Purple) */}
            <path
              d="M 72 46 C 86 42 94 48 92 38 C 88 34 78 40 72 43"
              fill="#7B5CFF"
              stroke="#1F1B4D"
              strokeWidth="2"
              strokeLinejoin="round"
            />
            <path d="M 90 39 C 86 40 80 42 74 43" stroke="#B8A5FF" strokeWidth="1.5" strokeLinecap="round" />

            {/* Bottom Gill Right (Teal Aqua) */}
            <path
              d="M 70 56 C 82 56 88 66 86 58 C 84 54 76 54 71 53"
              fill="#19C3B1"
              stroke="#1F1B4D"
              strokeWidth="2"
              strokeLinejoin="round"
            />
          </g>

          {/* 2. BODY & TAIL */}
          {/* Plump adorable body */}
          <path
            d="M 35 60 C 35 55 42 55 50 55 C 58 55 65 55 65 60 C 67 70 66 84 59 89 C 54 92 46 92 41 89 C 34 84 33 70 35 60 Z"
            fill="url(#churroBody)"
            stroke="#1F1B4D"
            strokeWidth="2.5"
            strokeLinejoin="round"
          />

          {/* Soft creamy belly */}
          <ellipse cx="50" cy="74" rx="11" ry="12" fill="url(#churroBelly)" />

          {/* Tiny Feet */}
          <ellipse cx="40" cy="90" rx="4.5" ry="3" fill="#FFEBD2" stroke="#1F1B4D" strokeWidth="2" />
          <ellipse cx="60" cy="90" rx="4.5" ry="3" fill="#FFEBD2" stroke="#1F1B4D" strokeWidth="2" />

          {/* 3. HEAD */}
          {/* Rounded friendly axolotl head */}
          <path
            d="M 50 22 C 34 22 28 32 28 45 C 28 58 35 64 50 64 C 65 64 72 58 72 45 C 72 32 66 22 50 22 Z"
            fill="url(#churroBody)"
            stroke="#1F1B4D"
            strokeWidth="2.5"
            strokeLinejoin="round"
          />

          {/* Rosy Cheeks */}
          <circle cx="35" cy="48" r="4.5" fill="#FF5C6C" fillOpacity="0.45" />
          <circle cx="65" cy="48" r="4.5" fill="#FF5C6C" fillOpacity="0.45" />

          {/* 4. FACIAL EXPRESSIONS BY MOOD */}
          {mood === 'celebrating' ? (
            <>
              {/* Happy squinting curved eyes (Joy: ^ ^) */}
              <path
                d="M 36 43 Q 41 38 46 43"
                stroke="#1F1B4D"
                strokeWidth="2.8"
                strokeLinecap="round"
                fill="none"
              />
              <path
                d="M 54 43 Q 59 38 64 43"
                stroke="#1F1B4D"
                strokeWidth="2.8"
                strokeLinecap="round"
                fill="none"
              />
              {/* Open laughing mouth */}
              <path
                d="M 44 48 Q 50 58 56 48 Z"
                fill="#FF5C6C"
                stroke="#1F1B4D"
                strokeWidth="2"
                strokeLinejoin="round"
              />
              {/* Little tongue */}
              <path d="M 46 52 Q 50 55 54 52" fill="#FFA5B5" />
            </>
          ) : mood === 'encouraging' ? (
            <>
              {/* Gentle empathetic eyes with slight tilt */}
              <g className="animate-churro-blink">
                <circle cx="41" cy="42" r="4" fill="#1F1B4D" />
                <circle cx="39.5" cy="40.5" r="1.5" fill="white" />
                <circle cx="59" cy="41.5" r="4" fill="#1F1B4D" />
                <circle cx="57.5" cy="40" r="1.5" fill="white" />
              </g>
              {/* Encouraging gentle smile */}
              <path
                d="M 45 50 Q 50 54 55 50"
                stroke="#1F1B4D"
                strokeWidth="2.2"
                strokeLinecap="round"
                fill="none"
              />
            </>
          ) : mood === 'proud' ? (
            <>
              {/* Proud / Cool Wink (One open sparkle eye, one winking smile) */}
              <circle cx="41" cy="42" r="3.8" fill="#1F1B4D" />
              <circle cx="39.8" cy="40.5" r="1.3" fill="white" />
              <path
                d="M 54 43 Q 59 38 64 43"
                stroke="#1F1B4D"
                strokeWidth="2.8"
                strokeLinecap="round"
                fill="none"
              />
              {/* Confident smile */}
              <path
                d="M 44 50 Q 50 55 56 49"
                stroke="#1F1B4D"
                strokeWidth="2.2"
                strokeLinecap="round"
                fill="none"
              />
            </>
          ) : mood === 'quest' ? (
            <>
              {/* Curious explorer big sparkle eyes with natural blinks */}
              <g className="animate-churro-blink">
                <circle cx="41" cy="41" r="4.5" fill="#1F1B4D" />
                <circle cx="39.5" cy="39.5" r="1.8" fill="white" />
                <circle cx="43" cy="43" r="0.9" fill="white" />

                <circle cx="59" cy="41" r="4.5" fill="#1F1B4D" />
                <circle cx="57.5" cy="39.5" r="1.8" fill="white" />
                <circle cx="61" cy="43" r="0.9" fill="white" />
              </g>

              {/* Curious O-smile */}
              <ellipse cx="50" cy="51" rx="3" ry="3.5" fill="#FF5C6C" stroke="#1F1B4D" strokeWidth="1.8" />
            </>
          ) : (
            <>
              {/* Default Waving / Friendly big bright eyes with natural idle blinks */}
              <g className="animate-churro-blink">
                <circle cx="41" cy="42" r="4" fill="#1F1B4D" />
                <circle cx="39.5" cy="40.5" r="1.5" fill="white" />
                <circle cx="42.5" cy="43.5" r="0.7" fill="white" />

                <circle cx="59" cy="42" r="4" fill="#1F1B4D" />
                <circle cx="57.5" cy="40.5" r="1.5" fill="white" />
                <circle cx="60.5" cy="43.5" r="0.7" fill="white" />
              </g>

              {/* Sweet smile */}
              <path
                d="M 44 50 Q 50 56 56 50"
                stroke="#1F1B4D"
                strokeWidth="2.4"
                strokeLinecap="round"
                fill="none"
              />
            </>
          )}

          {/* 5. DAPPER TEAL BANDANA / SCARF */}
          <path
            d="M 33 58 Q 50 66 67 58 L 64 63 Q 50 71 36 63 Z"
            fill="#19C3B1"
            stroke="#1F1B4D"
            strokeWidth="2"
            strokeLinejoin="round"
          />
          <path
            d="M 61 61 L 67 69 L 63 70 L 59 63 Z"
            fill="#0E867A"
            stroke="#1F1B4D"
            strokeWidth="1.8"
            strokeLinejoin="round"
          />

          {/* 6. ARMS / ACCESSORIES */}
          {mood === 'waving' ? (
            <>
              {/* Left arm waving high with subtle idle wave */}
              <path
                d="M 34 62 C 28 58 20 50 24 44 C 27 40 32 46 33 54"
                fill="#FFEBD2"
                stroke="#1F1B4D"
                strokeWidth="2.2"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
              {/* Right arm resting gently */}
              <path
                d="M 66 62 C 70 65 74 70 70 74 C 67 76 65 72 64 67"
                fill="#FFEBD2"
                stroke="#1F1B4D"
                strokeWidth="2"
                strokeLinecap="round"
              />
            </>
          ) : mood === 'celebrating' ? (
            <>
              {/* Both arms up in celebratory triumph! */}
              <path
                d="M 35 62 C 28 56 22 46 26 42 C 29 39 34 46 34 54"
                fill="#FFEBD2"
                stroke="#1F1B4D"
                strokeWidth="2.2"
                strokeLinecap="round"
              />
              <path
                d="M 65 62 C 72 56 78 46 74 42 C 71 39 66 46 66 54"
                fill="#FFEBD2"
                stroke="#1F1B4D"
                strokeWidth="2.2"
                strokeLinecap="round"
              />

              {/* Festive party hat! */}
              <path
                d="M 43 23 L 50 7 L 57 23 Z"
                fill="#FF6B2C"
                stroke="#1F1B4D"
                strokeWidth="2"
                strokeLinejoin="round"
              />
              <path d="M 45 19 L 55 19" stroke="#FFC93C" strokeWidth="2" />
              <path d="M 47 13 L 53 13" stroke="#19C3B1" strokeWidth="1.8" />
              <circle cx="50" cy="6" r="3" fill="#FFC93C" stroke="#1F1B4D" strokeWidth="1.5" />

              {/* Sparkle stars */}
              <path
                d="M 18 16 L 20 22 L 26 24 L 20 26 L 18 32 L 16 26 L 10 24 L 16 22 Z"
                fill="#FFC93C"
              />
              <path
                d="M 82 14 L 83 18 L 87 19 L 83 20 L 82 24 L 81 20 L 77 19 L 81 18 Z"
                fill="#FFC93C"
              />
            </>
          ) : mood === 'encouraging' ? (
            <>
              {/* Left paw up in comforting thumbs-up gesture */}
              <path
                d="M 34 62 C 28 58 24 50 29 46 C 32 44 35 50 34 56"
                fill="#FFEBD2"
                stroke="#1F1B4D"
                strokeWidth="2.2"
                strokeLinecap="round"
              />
              {/* Right arm resting gently */}
              <ellipse cx="64" cy="66" rx="4" ry="3.5" fill="#FFEBD2" stroke="#1F1B4D" strokeWidth="2" />
            </>
          ) : mood === 'quest' ? (
            <>
              {/* Explorer tiny map pin on brow */}
              <circle cx="50" cy="19" r="3" fill="#FF6B2C" stroke="#1F1B4D" strokeWidth="1.5" />
              <ellipse cx="50" cy="68" rx="5" ry="4" fill="#FFC93C" stroke="#1F1B4D" strokeWidth="1.8" />
              <path d="M 50 65 L 50 71" stroke="#1F1B4D" strokeWidth="1.2" strokeLinecap="round" />
              <path d="M 47 68 L 53 68" stroke="#1F1B4D" strokeWidth="1.2" strokeLinecap="round" />
            </>
          ) : (
            <>
              {/* Hands held together politely */}
              <ellipse cx="44" cy="67" rx="3.5" ry="3" fill="#FFEBD2" stroke="#1F1B4D" strokeWidth="1.8" />
              <ellipse cx="56" cy="67" rx="3.5" ry="3" fill="#FFEBD2" stroke="#1F1B4D" strokeWidth="1.8" />
            </>
          )}
        </svg>
      </div>
    </div>
  );
}

export const LumiMascot = ChurroMascot;

/**
 * ChurroPin — Miniature mascot token used on the 28-Day Quest Path
 * to mark the current active day node with high game personality.
 */
export function ChurroPin({
  label = 'Today',
  active = true,
}: {
  label?: string;
  active?: boolean;
}) {
  return (
    <div className="relative inline-flex flex-col items-center group select-none">
      {/* Floating mini speech / banner */}
      <div className="absolute -top-6 whitespace-nowrap px-1.5 py-0.5 rounded-full bg-[#FF6B2C] text-white text-[9px] font-extrabold tracking-tight shadow-xs animate-bounce z-10">
        <span>{label}</span>
        <div className="absolute left-1/2 -bottom-1 -translate-x-1/2 w-1.5 h-1.5 bg-[#FF6B2C] rotate-45" />
      </div>

      {/* Mini Churro Head Avatar */}
      <div
        className={`w-7 h-7 rounded-full flex items-center justify-center p-0.5 border-2 shadow-xs transition-transform ${
          active
            ? 'bg-[#FFEBD2] border-[#FF6B2C] ring-2 ring-[#FF6B2C]/40 animate-pulse'
            : 'bg-[#FFEBD2] border-neutral-300'
        }`}
        title="Churro está aquí · Día 28"
      >
        <ChurroMascot mood="waving" size="xs" animate={false} idle={false} />
      </div>
    </div>
  );
}

/**
 * MascotEncouragementToast — Gentle reaction toast shown when a player
 * makes an incorrect guess or mistake in any game. Never negative, no confetti.
 */
export function MascotEncouragementToast({
  message,
  onClose,
}: {
  message?: string;
  onClose?: () => void;
}) {
  const cheer = message || getRandomEncouragingCheer();

  return (
    <div
      onClick={onClose}
      className="fixed bottom-20 left-1/2 -translate-x-1/2 z-[8000] px-4 w-full max-w-sm pointer-events-auto cursor-pointer animate-churro-entrance"
    >
      <div className="bg-white dark:bg-[#221E52] border-2 border-[#FF6B2C]/40 text-[#1F1B4D] dark:text-[#FFF8EC] shadow-lg rounded-2xl p-3 flex items-center gap-3 backdrop-blur-md">
        <ChurroMascot mood="encouraging" size="sm" animate={false} idle={false} />
        <div className="flex-1 min-w-0">
          <span className="text-[10px] font-extrabold uppercase tracking-wider text-[#FF6B2C] block">
            Lumi cheers you on
          </span>
          <p className="text-[12px] font-bold leading-tight">{cheer}</p>
        </div>
        <span className="text-[10px] font-extrabold opacity-40 uppercase shrink-0">
          Tap
        </span>
      </div>
    </div>
  );
}
