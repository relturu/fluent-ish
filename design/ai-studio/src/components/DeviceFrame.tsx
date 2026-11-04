import React from 'react';
import { Wifi, Battery, Signal } from 'lucide-react';
import { useTheme } from './common/HiFiElements';

export function DeviceFrame({
  children,
  bottomBar,
  isDeviceMode = true,
}: {
  children: React.ReactNode;
  bottomBar?: React.ReactNode;
  isDeviceMode?: boolean;
}) {
  const { darkMode } = useTheme();

  if (!isDeviceMode) {
    return (
      <div
        className={`w-full max-w-md mx-auto min-h-[760px] rounded-[32px] shadow-2xl flex flex-col overflow-hidden relative border transition-colors ${
          darkMode
            ? 'dark bg-[#17143A] text-[#FFF8EC] border-white/10'
            : 'bg-[#FEF8EC] text-[#1F1B4D] border-[#1F1B4D]/15'
        }`}
      >
        <div className="flex-1 overflow-y-auto overflow-x-hidden flex flex-col">
          {children}
        </div>
        {bottomBar}
      </div>
    );
  }

  return (
    <div className="relative mx-auto my-2">
      {/* Physical Phone Outer Bezel */}
      <div className="w-[392px] h-[840px] bg-[#120F32] rounded-[52px] p-3 shadow-2xl ring-2 ring-[#1F1B4D] ring-offset-4 ring-offset-[#FF6B2C]/20 flex flex-col relative select-none">
        {/* Dynamic Island / Top Camera Pill */}
        <div className="absolute top-5.5 left-1/2 -translate-x-1/2 w-28 h-6 bg-black rounded-full z-50 flex items-center justify-between px-3 border border-white/10">
          <div className="w-2.5 h-2.5 rounded-full bg-neutral-900" />
          <div className="w-2 h-2 rounded-full bg-[#7B5CFF]/50" />
        </div>

        {/* Screen Bezel Inset */}
        <div
          className={`w-full h-full rounded-[42px] overflow-hidden flex flex-col relative transition-colors ${
            darkMode
              ? 'dark bg-[#17143A] text-[#FFF8EC]'
              : 'bg-[#FEF8EC] text-[#1F1B4D]'
          }`}
        >
          {/* Status Bar */}
          <div
            className={`h-11 px-7 flex items-center justify-between z-40 shrink-0 pointer-events-none transition-colors ${
              darkMode
                ? 'bg-[#17143A] text-[#FFF8EC]'
                : 'bg-[#FEF8EC] text-[#1F1B4D]'
            }`}
          >
            <span className="text-[13px] font-extrabold tracking-tight">9:41</span>
            <div className="flex items-center gap-1.5 opacity-80">
              <Signal className="w-3.5 h-3.5" />
              <Wifi className="w-3.5 h-3.5" />
              <Battery className="w-4 h-4" />
            </div>
          </div>

          {/* Interactive Screen Scrollable Viewport */}
          <div className="flex-1 overflow-y-auto overflow-x-hidden relative flex flex-col">
            {children}
          </div>

          {/* Persistent Bottom Navigation Bar */}
          {bottomBar}

          {/* Bottom Home Indicator */}
          <div
            className={`h-4 flex items-center justify-center shrink-0 z-40 pointer-events-none transition-colors ${
              darkMode ? 'bg-[#17143A]' : 'bg-[#FEF8EC]'
            }`}
          >
            <div
              className={`w-32 h-1 rounded-full ${
                darkMode ? 'bg-white/20' : 'bg-[#1F1B4D]/25'
              }`}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
