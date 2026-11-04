import React, { useEffect, useState, useRef } from 'react';
import {
  BarChart3,
  Users,
  Flame,
  Settings,
  ArrowLeft,
  ArrowRight,
  Volume2,
} from 'lucide-react';
import { MainTabId } from '../../types';
import { ChurroMascot, getRandomCelebrationCheer } from './Mascot';

export interface ThemeContextType {
  darkMode: boolean;
  setDarkMode: (val: boolean) => void;
}

export const ThemeContext = React.createContext<ThemeContextType>({
  darkMode: false,
  setDarkMode: () => {},
});

export const useTheme = () => React.useContext(ThemeContext);

// Pronounce Spanish text using Web Speech API
export function speakSpanish(text: string) {
  if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
    try {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = 'es-ES';
      utterance.rate = 0.92;
      window.speechSynthesis.speak(utterance);
    } catch {
      // Ignore speech errors in restricted environments
    }
  }
}

// Uplifting celebration sound using Web Audio API
export function playCelebrationSound() {
  if (typeof window === 'undefined') return;
  try {
    const AudioContextClass =
      window.AudioContext ||
      (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    if (!AudioContextClass) return;
    const ctx = new AudioContextClass();
    if (ctx.state === 'suspended') {
      ctx.resume();
    }
    const notes = [
      { freq: 523.25, time: 0.0, dur: 0.25 }, // C5
      { freq: 659.25, time: 0.07, dur: 0.25 }, // E5
      { freq: 783.99, time: 0.15, dur: 0.3 }, // G5
      { freq: 1046.5, time: 0.25, dur: 0.5 }, // C6
      { freq: 1318.51, time: 0.36, dur: 0.65 }, // E6 sparkle
    ];

    notes.forEach(({ freq, time, dur }) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(freq, ctx.currentTime + time);
      gain.gain.setValueAtTime(0, ctx.currentTime + time);
      gain.gain.linearRampToValueAtTime(0.18, ctx.currentTime + time + 0.03);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + time + dur);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(ctx.currentTime + time);
      osc.stop(ctx.currentTime + time + dur + 0.05);
    });
  } catch {
    // Ignore audio errors gracefully
  }
}

// Gentle tap / select sound using Web Audio API
export function playSelectSound() {
  if (typeof window === 'undefined') return;
  try {
    const AudioContextClass =
      window.AudioContext ||
      (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
    if (!AudioContextClass) return;
    const ctx = new AudioContextClass();
    if (ctx.state === 'suspended') {
      ctx.resume();
    }
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(587.33, ctx.currentTime); // D5
    gain.gain.setValueAtTime(0.08, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.08);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start(ctx.currentTime);
    osc.stop(ctx.currentTime + 0.09);
  } catch {
    // Ignore audio errors gracefully
  }
}

/**
 * HiFiButton: Chunky 3D-style tactile buttons
 * Depresses on active click/press, with rounded corners and solid darker bottom edge.
 */
export function HiFiButton({
  children,
  size = 'lg',
  variant = 'primary',
  fullWidth = false,
  disabled = false,
  onClick,
  icon,
  className = '',
  type = 'button',
  forceDarkMode,
}: {
  children: React.ReactNode;
  size?: 'lg' | 'sm';
  variant?: 'primary' | 'secondary' | 'purple' | 'yellow' | 'aqua' | 'outline';
  fullWidth?: boolean;
  disabled?: boolean;
  onClick?: () => void;
  icon?: React.ReactNode;
  className?: string;
  type?: 'button' | 'submit';
  forceDarkMode?: boolean;
}) {
  const { darkMode: contextDark } = useTheme();
  const isDark = forceDarkMode !== undefined ? forceDarkMode : contextDark;

  const sizeClasses =
    size === 'lg'
      ? 'min-h-[46px] px-5 py-2.5 text-[14px] font-bold rounded-2xl gap-2'
      : 'min-h-[38px] px-3.5 py-1.5 text-[12px] font-bold rounded-xl gap-1.5';

  let variantClass = '';
  switch (variant) {
    case 'primary':
      variantClass = 'btn-3d-primary';
      break;
    case 'purple':
      variantClass = 'btn-3d-purple';
      break;
    case 'yellow':
      variantClass = 'btn-3d-yellow';
      break;
    case 'aqua':
      variantClass = 'btn-3d-aqua';
      break;
    case 'secondary':
      variantClass = isDark
        ? 'bg-[#292461] text-[#FFF8EC] border-b-4 border-[#1A1646] active:border-b-0 active:translate-y-1'
        : 'btn-3d-secondary';
      break;
    case 'outline':
    default:
      variantClass = isDark
        ? 'bg-transparent text-[#FFF8EC] border-2 border-white/20 border-b-4 border-b-white/30 hover:bg-white/10 active:border-b-2 active:translate-y-0.5'
        : 'bg-transparent text-[#1F1B4D] border-2 border-[#1F1B4D]/25 border-b-4 border-b-[#1F1B4D]/40 hover:bg-[#1F1B4D]/5 active:border-b-2 active:translate-y-0.5';
      break;
  }

  return (
    <button
      type={type}
      disabled={disabled}
      onClick={onClick}
      className={`inline-flex items-center justify-center cursor-pointer select-none tracking-tight ${sizeClasses} ${variantClass} ${
        fullWidth ? 'w-full' : ''
      } ${disabled ? 'opacity-40 pointer-events-none' : ''} ${className}`}
    >
      {icon && <span className="shrink-0">{icon}</span>}
      <span>{children}</span>
    </button>
  );
}

/**
 * Animated Score/XP Count-Up Component
 */
export function CountUpNumber({
  target,
  duration = 800,
  prefix = '',
  suffix = '',
  className = '',
}: {
  target: number;
  duration?: number;
  prefix?: string;
  suffix?: string;
  className?: string;
}) {
  const [current, setCurrent] = useState(0);

  useEffect(() => {
    // Check reduced motion
    const prefersReducedMotion =
      typeof window !== 'undefined' &&
      window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    if (prefersReducedMotion) {
      setCurrent(target);
      return;
    }

    let startTime: number | null = null;
    let animId: number;

    const step = (timestamp: number) => {
      if (!startTime) startTime = timestamp;
      const progress = Math.min((timestamp - startTime) / duration, 1);
      const easeOutProgress = 1 - Math.pow(1 - progress, 3);
      setCurrent(Math.floor(easeOutProgress * target));

      if (progress < 1) {
        animId = requestAnimationFrame(step);
      } else {
        setCurrent(target);
      }
    };

    animId = requestAnimationFrame(step);
    return () => cancelAnimationFrame(animId);
  }, [target, duration]);

  return (
    <span className={className}>
      {prefix}
      {current.toLocaleString()}
      {suffix}
    </span>
  );
}

/**
 * ConfettiBurst Component:
 * - Full-screen multi-stage Canvas celebration engine covering the entire display
 * - Dual corner cannons + top rain cascade + middle starburst wave (240+ particles)
 * - 3D tumbling paper physics, ribbons, sparkle stars, circles
 * - Uplifting major-chord Web Audio celebration chime
 * - Prominent celebratory floating banner
 * - pointer-events: none (completely unblocks taps/clicks)
 * - Auto-dismisses and cleans up cleanly
 */
interface CelebrationParticle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  gravity: number;
  drag: number;
  color: string;
  shape: 'rect' | 'ribbon' | 'circle' | 'star';
  size: number;
  length: number;
  angle: number;
  angleSpeed: number;
  tiltAngle: number;
  tiltSpeed: number;
  wobble: number;
  wobbleSpeed: number;
  alpha: number;
}

function drawConfettiStar(
  ctx: CanvasRenderingContext2D,
  cx: number,
  cy: number,
  spikes: number,
  outerRadius: number,
  innerRadius: number
) {
  let rot = (Math.PI / 2) * 3;
  const step = Math.PI / spikes;
  ctx.beginPath();
  ctx.moveTo(cx, cy - outerRadius);
  for (let i = 0; i < spikes; i++) {
    const x1 = cx + Math.cos(rot) * outerRadius;
    const y1 = cy + Math.sin(rot) * outerRadius;
    ctx.lineTo(x1, y1);
    rot += step;
    const x2 = cx + Math.cos(rot) * innerRadius;
    const y2 = cy + Math.sin(rot) * innerRadius;
    ctx.lineTo(x2, y2);
    rot += step;
  }
  ctx.lineTo(cx, cy - outerRadius);
  ctx.closePath();
  ctx.fill();
}

export function ConfettiBurst({
  onDone,
  durationMs = 2800,
  message,
  playSound = true,
}: {
  onDone?: () => void;
  durationMs?: number;
  message?: string;
  playSound?: boolean;
}) {
  const [visible, setVisible] = useState(true);
  const [isExiting, setIsExiting] = useState(false);
  const [cheer] = useState(() => getRandomCelebrationCheer(message));
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  const prefersReducedMotion =
    typeof window !== 'undefined' &&
    window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const handleDismiss = () => {
    if (isExiting) return;
    setIsExiting(true);
    setTimeout(() => {
      setVisible(false);
      onDone?.();
    }, 280);
  };

  useEffect(() => {
    if (playSound) {
      playCelebrationSound();
    }

    const exitTimer = setTimeout(() => {
      setIsExiting(true);
    }, Math.max(0, durationMs - 320));

    const doneTimer = setTimeout(() => {
      setVisible(false);
      onDone?.();
    }, durationMs);

    return () => {
      clearTimeout(exitTimer);
      clearTimeout(doneTimer);
    };
  }, [durationMs, onDone, playSound]);

  useEffect(() => {
    if (!visible) return;

    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const prefersReducedMotion =
      typeof window !== 'undefined' &&
      window.matchMedia('(prefers-reduced-motion: reduce)').matches;

    let animId: number;
    let width = window.innerWidth;
    let height = window.innerHeight;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);

    const handleResize = () => {
      if (!canvas) return;
      width = window.innerWidth;
      height = window.innerHeight;
      canvas.width = width * dpr;
      canvas.height = height * dpr;
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.scale(dpr, dpr);
    };

    handleResize();
    window.addEventListener('resize', handleResize);

    const colors = [
      '#FF6B2C', // Flame Orange
      '#7B5CFF', // Royal Purple
      '#19C3B1', // Aqua Teal
      '#1F1B4D', // Deep Navy
      '#FFF8EC', // Warm Cream
      '#FFC93C', // Sunny Yellow
    ];

    const particles: CelebrationParticle[] = [];

    const createParticle = (
      x: number,
      y: number,
      vx: number,
      vy: number,
      shape?: 'rect' | 'ribbon' | 'circle' | 'star'
    ): CelebrationParticle => {
      const selectedShape =
        shape ||
        (Math.random() > 0.65
          ? 'ribbon'
          : Math.random() > 0.4
          ? 'rect'
          : Math.random() > 0.2
          ? 'star'
          : 'circle');

      return {
        x,
        y,
        vx,
        vy,
        gravity: prefersReducedMotion ? 0.08 : 0.32 + Math.random() * 0.12,
        drag: 0.985,
        color: colors[Math.floor(Math.random() * colors.length)],
        shape: selectedShape,
        size:
          selectedShape === 'ribbon'
            ? 6 + Math.random() * 3
            : selectedShape === 'star'
            ? 7 + Math.random() * 5
            : 8 + Math.random() * 6,
        length: selectedShape === 'ribbon' ? 22 + Math.random() * 22 : 12 + Math.random() * 8,
        angle: Math.random() * Math.PI * 2,
        angleSpeed: (Math.random() - 0.5) * 0.16,
        tiltAngle: Math.random() * Math.PI * 2,
        tiltSpeed: 0.08 + Math.random() * 0.14,
        wobble: Math.random() * 10,
        wobbleSpeed: 0.04 + Math.random() * 0.06,
        alpha: 1,
      };
    };

    // Wave 1: Immediate Left & Right Cannons + Top Rain Cascade across the entire screen
    const spawnWave1 = () => {
      // Left Cannon (blasts up-right across screen)
      for (let i = 0; i < 70; i++) {
        const angle = -Math.PI / 4 + (Math.random() - 0.5) * 0.65; // ~45 deg up-right
        const speed = 16 + Math.random() * 22;
        particles.push(
          createParticle(
            width * 0.05,
            height * 0.96,
            Math.cos(angle) * speed,
            Math.sin(angle) * speed
          )
        );
      }

      // Right Cannon (blasts up-left across screen)
      for (let i = 0; i < 70; i++) {
        const angle = (-3 * Math.PI) / 4 + (Math.random() - 0.5) * 0.65; // ~135 deg up-left
        const speed = 16 + Math.random() * 22;
        particles.push(
          createParticle(
            width * 0.95,
            height * 0.96,
            Math.cos(angle) * speed,
            Math.sin(angle) * speed
          )
        );
      }

      // Top Shower: Spread 100% across viewport width
      for (let i = 0; i < 60; i++) {
        particles.push(
          createParticle(
            Math.random() * width,
            -20 - Math.random() * 80,
            (Math.random() - 0.5) * 5,
            2 + Math.random() * 6
          )
        );
      }
    };

    spawnWave1();

    // Wave 2: Explosive Starburst in the Upper-Center (t = 280ms)
    const timer2 = setTimeout(() => {
      for (let i = 0; i < 50; i++) {
        const angle = Math.random() * Math.PI * 2;
        const speed = 6 + Math.random() * 16;
        particles.push(
          createParticle(
            width * 0.5,
            height * 0.35,
            Math.cos(angle) * speed,
            Math.sin(angle) * speed - 5,
            'star'
          )
        );
      }
    }, 280);

    // Wave 3: Secondary Cascading Ribbons Shower (t = 650ms)
    const timer3 = setTimeout(() => {
      for (let i = 0; i < 55; i++) {
        particles.push(
          createParticle(
            Math.random() * width,
            -20 - Math.random() * 60,
            (Math.random() - 0.5) * 4,
            2.5 + Math.random() * 5,
            'ribbon'
          )
        );
      }
    }, 650);

    const startTime = performance.now();

    const loop = (now: number) => {
      const elapsed = now - startTime;
      ctx.clearRect(0, 0, width, height);

      // Fade out smoothly in the final 900ms
      let globalFade = 1;
      if (elapsed > durationMs - 900) {
        globalFade = Math.max(0, (durationMs - elapsed) / 900);
      }

      for (let i = 0; i < particles.length; i++) {
        const p = particles[i];

        p.vx *= p.drag;
        p.vy *= p.drag;
        p.vy += p.gravity;
        p.wobble += p.wobbleSpeed;
        p.x += p.vx + Math.sin(p.wobble) * 1.4;
        p.y += p.vy;

        p.angle += p.angleSpeed;
        p.tiltAngle += p.tiltSpeed;

        const effectiveAlpha = p.alpha * globalFade;
        if (effectiveAlpha <= 0.01) continue;

        ctx.save();
        ctx.translate(p.x, p.y);
        ctx.rotate(p.angle);
        // Realistic 3D paper fluttering rotation
        ctx.scale(Math.cos(p.tiltAngle), 1);
        ctx.fillStyle = p.color;
        ctx.globalAlpha = effectiveAlpha;

        if (p.shape === 'star') {
          drawConfettiStar(ctx, 0, 0, 5, p.size, p.size * 0.45);
        } else if (p.shape === 'circle') {
          ctx.beginPath();
          ctx.arc(0, 0, p.size / 2, 0, Math.PI * 2);
          ctx.fill();
        } else if (p.shape === 'ribbon') {
          ctx.fillRect(-p.size / 2, -p.length / 2, p.size, p.length);
        } else {
          // Classic confetti rectangular sheet
          ctx.fillRect(-p.size / 2, -p.size * 0.7, p.size, p.size * 1.4);
        }

        ctx.restore();
      }

      if (elapsed < durationMs) {
        animId = requestAnimationFrame(loop);
      }
    };

    animId = requestAnimationFrame(loop);

    return () => {
      cancelAnimationFrame(animId);
      clearTimeout(timer2);
      clearTimeout(timer3);
      window.removeEventListener('resize', handleResize);
    };
  }, [visible, durationMs]);

  if (!visible) return null;

  return (
    <div
      role="dialog"
      aria-label="Celebration"
      onClick={handleDismiss}
      className={`fixed inset-0 z-[9999] flex flex-col items-center justify-center p-4 select-none cursor-pointer overflow-hidden transition-opacity duration-300 ${
        isExiting ? 'opacity-0 pointer-events-none' : 'opacity-100 pointer-events-auto'
      }`}
    >
      {/* Light scrim behind celebration so user still sees the solved game underneath */}
      <div className="absolute inset-0 bg-black/25 dark:bg-black/50 backdrop-blur-[2px] transition-opacity duration-300 pointer-events-none" />

      {/* Synchronized Confetti Canvas */}
      {!prefersReducedMotion && (
        <canvas
          ref={canvasRef}
          className="absolute inset-0 w-full h-full pointer-events-none"
        />
      )}

      {/* Synchronized Mascot Celebration & Bilingual Speech Cheer */}
      <div
        className={`relative z-[10000] flex flex-col items-center text-center max-w-sm mx-auto px-4 ${
          prefersReducedMotion
            ? 'transition-opacity duration-300'
            : isExiting
            ? 'animate-churro-exit'
            : 'animate-churro-entrance'
        }`}
      >
        {/* Animated Speech Bubble with Rotated Cheer */}
        <div className="mb-3 px-5 py-2.5 rounded-2xl bg-white dark:bg-[#1F1B4D] border-2 border-[#FF6B2C] shadow-[0_12px_32px_rgba(255,107,44,0.35)] text-[#1F1B4D] dark:text-[#FFF8EC] text-[13px] sm:text-[14px] font-black tracking-wide leading-snug drop-shadow-sm flex items-center justify-center gap-2 animate-scale-bounce">
          <span>{cheer}</span>
        </div>

        {/* Mascot in Joyful Celebrating Pose (Arms up, continuous party dance) */}
        <div className={prefersReducedMotion ? '' : 'animate-churro-dance'}>
          <ChurroMascot
            mood="celebrating"
            size="lg"
            animate={!prefersReducedMotion}
            idle={false}
          />
        </div>

        {/* Tap Anywhere / Continue Button */}
        <button
          type="button"
          onClick={(e) => {
            e.stopPropagation();
            handleDismiss();
          }}
          className="mt-4 px-5 py-2 rounded-full bg-white dark:bg-[#221E52] border border-[#FF6B2C]/40 text-[#1F1B4D] dark:text-[#FFF8EC] text-[12px] font-extrabold shadow-md hover:scale-105 active:scale-95 transition-transform flex items-center gap-1.5 cursor-pointer"
        >
          <span>Continue</span>
          <ArrowRight className="w-3.5 h-3.5" />
        </button>
      </div>
    </div>
  );
}

/**
 * Game Header Bar for active games
 */
export function GameHeaderBar({
  title,
  subtitle,
  onOpenHowToPlay,
  onOpenHint,
  onBack,
  rightBadge,
}: {
  title: string;
  subtitle?: string;
  onOpenHowToPlay?: () => void;
  onOpenHint?: () => void;
  onBack?: () => void;
  rightBadge?: React.ReactNode;
}) {
  const { darkMode } = useTheme();

  return (
    <header
      className={`sticky top-0 z-30 px-4 py-2.5 border-b transition-colors ${
        darkMode
          ? 'bg-[#17143A]/95 border-white/10 text-[#FFF8EC]'
          : 'bg-[#FFF8EC]/95 border-[#1F1B4D]/10 text-[#1F1B4D]'
      } backdrop-blur-md`}
    >
      <div className="flex items-center justify-between gap-2">
        {/* Left Slot: Back button */}
        <div className="flex items-center justify-start shrink-0 min-w-[64px]">
          {onBack ? (
            <button
              type="button"
              onClick={onBack}
              className="text-[13px] font-bold flex items-center gap-1 opacity-80 hover:opacity-100 transition-opacity cursor-pointer min-h-[44px]"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>Back</span>
            </button>
          ) : (
            <div />
          )}
        </div>

        {/* Center Title */}
        <div className="text-center flex-1 min-w-0">
          <h2 className="type-h3 truncate">{title}</h2>
          {subtitle && (
            <p className="text-[11px] opacity-60 font-semibold truncate">
              {subtitle}
            </p>
          )}
        </div>

        {/* Right Slot: How to Play (?) and Hint (!) buttons or rightBadge */}
        <div className="flex items-center justify-end gap-1.5 shrink-0 min-w-[64px]">
          {rightBadge}
          {onOpenHowToPlay && (
            <button
              type="button"
              onClick={onOpenHowToPlay}
              aria-label="How this game works"
              title="How to Play"
              className={`w-9 h-9 rounded-xl font-extrabold text-[13px] flex items-center justify-center border transition-all cursor-pointer ${
                darkMode
                  ? 'bg-[#252156] text-[#FFF8EC] border-white/15 hover:bg-[#312B70]'
                  : 'bg-white text-[#1F1B4D] border-[#1F1B4D]/15 hover:bg-[#FFF8EC]'
              }`}
            >
              ?
            </button>
          )}

          {onOpenHint && (
            <button
              type="button"
              onClick={onOpenHint}
              aria-label="Get a hint"
              title="Game Hint"
              className={`w-9 h-9 rounded-xl font-extrabold text-[13px] flex items-center justify-center border transition-all cursor-pointer ${
                darkMode
                  ? 'bg-[#FF6B2C]/20 text-[#FF6B2C] border-[#FF6B2C]/40 hover:bg-[#FF6B2C] hover:text-white'
                  : 'bg-[#FF6B2C]/10 text-[#FF6B2C] border-[#FF6B2C]/30 hover:bg-[#FF6B2C] hover:text-white'
              }`}
            >
              !
            </button>
          )}
        </div>
      </div>
    </header>
  );
}

/**
 * Top Page Header for primary navigation tabs
 */
export function BrandWordmark({ className = '' }: { className?: string }) {
  const { darkMode } = useTheme();
  return (
    <span
      className={`text-[17px] font-extrabold tracking-tight select-none inline-flex items-center ${
        darkMode ? 'text-[#FFF8EC]' : 'text-[#1F1B4D]'
      } ${className}`}
    >
      <span>Fluent</span>
      <span
        className="text-[#FF6B2C] font-black mx-0.5 leading-none inline-block"
        style={{ color: '#FF6B2C' }}
      >
        •
      </span>
      <span>ish</span>
    </span>
  );
}

export function PageTopBar({
  title,
  rightAction,
}: {
  title: string;
  subtitle?: string;
  rightAction?: React.ReactNode;
}) {
  const { darkMode } = useTheme();

  return (
    <header
      className={`sticky top-0 z-30 px-4 py-3 border-b transition-colors ${
        darkMode
          ? 'bg-[#17143A]/95 border-white/10 text-[#FFF8EC]'
          : 'bg-[#FFF8EC]/95 border-[#1F1B4D]/10 text-[#1F1B4D]'
      } backdrop-blur-md`}
    >
      <div className="flex items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <BrandWordmark />
          <span aria-hidden="true" className="opacity-30 font-bold">
            /
          </span>
          <h1 className="text-[14px] font-bold opacity-90">{title}</h1>
        </div>
        {rightAction && <div>{rightAction}</div>}
      </div>
    </header>
  );
}

export function StreakIndicator({
  streakCount,
  streakCountedToday,
  onClick,
  className = '',
}: {
  streakCount: number;
  streakCountedToday: boolean;
  onClick?: () => void;
  className?: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex items-center gap-1 text-[#FF6B2C] font-bold text-[13px] hover:scale-105 active:scale-95 transition-transform cursor-pointer select-none ${className}`}
      title={
        streakCountedToday
          ? `Streak: ${streakCount}d active today! ✓`
          : `Streak: ${streakCount}d (Pending - finish 1 game or lesson to extend)`
      }
    >
      <Flame
        className={`w-3.5 h-3.5 fill-[#FF6B2C] text-[#FF6B2C] ${
          streakCountedToday ? 'animate-flame-glow' : ''
        }`}
      />
      <span className="tabular-nums">{streakCount}</span>
      {streakCountedToday ? (
        <span
          className="w-1.5 h-1.5 rounded-full bg-[#3DDC84] inline-block shadow-2xs"
          title="Today's streak active"
        />
      ) : (
        <span
          className="w-1.5 h-1.5 rounded-full bg-[#FF6B2C]/40 inline-block"
          title="Finish 1 game to count today"
        />
      )}
    </button>
  );
}


/**
 * Persistent 4-Tab Bottom Navigation Bar
 * Order: Today, Progress, Friends, Settings
 */
export function BottomNavBar({
  activeTab,
  onSelectTab,
}: {
  activeTab: MainTabId;
  onSelectTab: (tab: MainTabId) => void;
}) {
  const { darkMode } = useTheme();

  const tabs: { id: MainTabId; label: string; icon: React.ReactNode }[] = [
    {
      id: 'daily',
      label: 'Today',
      icon: <Flame className="w-4 h-4" />,
    },
    {
      id: 'progress',
      label: 'Progress',
      icon: <BarChart3 className="w-4 h-4" />,
    },
    {
      id: 'friends',
      label: 'Friends',
      icon: <Users className="w-4 h-4" />,
    },
    {
      id: 'settings',
      label: 'Settings',
      icon: <Settings className="w-4 h-4" />,
    },
  ];

  return (
    <nav
      aria-label="Primary bottom navigation"
      className={`sticky bottom-0 left-0 right-0 z-30 border-t px-2 py-1 transition-colors ${
        darkMode
          ? 'bg-[#17143A]/98 border-white/10 text-[#FFF8EC]'
          : 'bg-[#FEF8EC]/98 border-[#1F1B4D]/10 text-[#1F1B4D]'
      } backdrop-blur-md`}
    >
      <div className="grid grid-cols-4 gap-1">
        {tabs.map((tab) => {
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              type="button"
              onClick={() => onSelectTab(tab.id)}
              aria-current={isActive ? 'page' : undefined}
              className={`min-h-[46px] py-1 px-1 rounded-xl flex flex-col items-center justify-center relative transition-colors cursor-pointer ${
                isActive
                  ? 'text-[#FF6B2C]'
                  : darkMode
                  ? 'text-white/50 hover:text-white'
                  : 'text-[#706E7B] hover:text-[#1F1B4D]'
              }`}
            >
              {/* Active top accent indicator bar */}
              {isActive && (
                <span className="absolute top-0 left-1/2 -translate-x-1/2 w-6 h-0.5 rounded-full bg-[#FF6B2C]" />
              )}
              <span className={`transition-transform duration-150 ${isActive ? 'scale-105' : ''}`}>
                {tab.icon}
              </span>
              <span
                className={`text-[11px] mt-1 leading-none tracking-tight ${
                  isActive ? 'font-bold text-[#FF6B2C]' : 'font-medium'
                }`}
              >
                {tab.label}
              </span>
            </button>
          );
        })}
      </div>
    </nav>
  );
}

/**
 * Reusable Modal Sheet for '?' (How to Play) and '!' (Game Hints)
 */
export function GameAssistModal({
  isOpen,
  mode,
  title,
  howToPlaySteps,
  hintText,
  hintActionLabel,
  onApplyHint,
  onClose,
}: {
  isOpen: boolean;
  mode: 'how-to' | 'hint' | null;
  title: string;
  howToPlaySteps: string[];
  hintText: string;
  hintActionLabel?: string;
  onApplyHint?: () => void;
  onClose: () => void;
}) {
  const { darkMode } = useTheme();

  if (!isOpen || !mode) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/60 backdrop-blur-xs p-4">
      <div
        className={`w-full max-w-sm rounded-3xl p-5 space-y-4 border shadow-2xl transition-colors ${
          darkMode
            ? 'bg-[#221E52] border-white/15 text-[#FFF8EC]'
            : 'bg-white border-[#1F1B4D]/15 text-[#1F1B4D]'
        }`}
      >
        <div className="flex items-center justify-between border-b border-current/10 pb-2.5">
          <div className="flex items-center gap-2">
            <span
              className={`w-7 h-7 rounded-full flex items-center justify-center font-extrabold text-[13px] ${
                mode === 'how-to'
                  ? 'bg-[#1F1B4D] text-[#FFF8EC]'
                  : 'bg-[#FF6B2C] text-white'
              }`}
            >
              {mode === 'how-to' ? '?' : '!'}
            </span>
            <h3 className="text-[16px] font-bold">
              {mode === 'how-to' ? `How to Play` : `Hint`} · {title}
            </h3>
          </div>
        </div>

        {mode === 'how-to' ? (
          <div className="space-y-2.5">
            {howToPlaySteps.map((step, i) => (
              <div key={i} className="flex items-start gap-2.5">
                <span className="w-5 h-5 rounded-full bg-[#FF6B2C]/15 text-[#FF6B2C] font-extrabold text-[11px] flex items-center justify-center shrink-0 mt-0.5">
                  {i + 1}
                </span>
                <p className="text-[13px] leading-snug opacity-90">{step}</p>
              </div>
            ))}
          </div>
        ) : (
          <div className="space-y-3.5">
            <p className="text-[13px] leading-relaxed opacity-90">{hintText}</p>

            {onApplyHint && hintActionLabel && (
              <HiFiButton
                fullWidth
                size="sm"
                variant="primary"
                onClick={() => {
                  onApplyHint();
                  onClose();
                }}
              >
                {hintActionLabel}
              </HiFiButton>
            )}
          </div>
        )}

        <HiFiButton fullWidth size="sm" variant="outline" onClick={onClose}>
          Close
        </HiFiButton>
      </div>
    </div>
  );
}

/**
 * Audio Speaker Button for Spanish Words
 */
export function AudioButton({
  text,
  size = 'sm',
}: {
  text: string;
  size?: 'sm' | 'lg';
}) {
  const { darkMode } = useTheme();
  return (
    <button
      type="button"
      onClick={(e) => {
        e.stopPropagation();
        speakSpanish(text);
      }}
      title={`Listen to "${text}"`}
      className={`${
        size === 'lg' ? 'w-11 h-11 rounded-2xl' : 'w-8 h-8 rounded-xl'
      } flex items-center justify-center transition-all cursor-pointer shrink-0 ${
        darkMode
          ? 'bg-[#292461] text-[#FFC93C] hover:bg-[#FFC93C] hover:text-[#1F1B4D]'
          : 'bg-[#FF6B2C]/15 text-[#FF6B2C] hover:bg-[#FF6B2C] hover:text-white'
      }`}
    >
      <Volume2 className={size === 'lg' ? 'w-5 h-5' : 'w-4 h-4'} />
    </button>
  );
}
