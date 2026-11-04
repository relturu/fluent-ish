import React, { useState } from 'react';
import {
  LoFiTopBar,
  LoFiButton,
  LoFiInput,
  LoFiCard,
  LoFiToggle,
  FillerText,
} from '../components/common/LoFiElements';
import { Check, Lock } from 'lucide-react';

export function Flow01Onboarding({
  activeScreen,
  onNavigate,
  onCompleteOnboarding,
}: {
  activeScreen: string;
  onNavigate: (screenId: string) => void;
  onCompleteOnboarding: () => void;
}) {
  // Local state for interactive choices
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [nativeLang, setNativeLang] = useState('Lorem Ipsum');
  const [targetLang, setTargetLang] = useState('Ipsum');
  const [goalReason, setGoalReason] = useState('work');
  const [dailyGoal, setDailyGoal] = useState('10');
  const [selectedLevel, setSelectedLevel] = useState('beginner');
  const [quizAnswer, setQuizAnswer] = useState<number | null>(null);
  const [quizChecked, setQuizChecked] = useState(false);
  const [allowReminders, setAllowReminders] = useState(true);
  const [showForgotModal, setShowForgotModal] = useState(false);

  // 1A: Welcome / Entry
  if (activeScreen === '1A') {
    return (
      <div className="flex flex-col min-h-full bg-white">
        <LoFiTopBar title="Entry Point" subtitle="Flow 01 · Screen 1A" />
        <div className="flex-1 px-5 py-6 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-6">
            {/* Fluent•ish App Brand Logo */}
            <div className="flex flex-col items-center justify-center mx-auto space-y-1">
              <div className="px-5 py-2 rounded-2xl border-2 border-black bg-neutral-900 text-white shadow-xs flex items-center justify-center">
                <span className="font-mono text-2xl font-bold tracking-tight text-white">Fluent•ish</span>
              </div>
            </div>

            {/* Typography hierarchy */}
            <div className="text-center space-y-2">
              <h2 className="text-2xl font-bold tracking-tight text-neutral-900">
                <FillerText
                  semantic="A sharper, focused approach to language study"
                  tier="primary"
                />
              </h2>
              <p className="text-sm text-neutral-600 leading-relaxed max-w-xs mx-auto">
                <FillerText
                  semantic="Build lasting recall through structured daily word sets and rapid recall exercises."
                  tier="tertiary"
                  skeletonWidth="w-full"
                />
              </p>
            </div>

            {/* Feature preview list */}
            <div className="space-y-2.5 pt-2">
              {[
                'Daily 3-game progression sets',
                'Contextual review flashcards',
                'Adaptive vocabulary notebooks',
              ].map((feat, idx) => (
                <div
                  key={idx}
                  className="flex items-center gap-3 p-3 rounded-lg border border-neutral-200 bg-neutral-50/60"
                >
                  <div className="w-6 h-6 rounded-full bg-black text-white text-xs font-mono flex items-center justify-center shrink-0">
                    0{idx + 1}
                  </div>
                  <p className="text-xs font-medium text-neutral-800">
                    <FillerText semantic={feat} tier="secondary" skeletonWidth="w-40" />
                  </p>
                </div>
              ))}
            </div>
          </div>

          {/* Action Footer */}
          <div className="space-y-3 pt-6">
            <LoFiButton
              fullWidth
              size="lg"
              variant="primary"
              onClick={() => onNavigate('1B')}
            >
              <FillerText semantic="Create Account" tier="primary" skeletonWidth="w-28" />
            </LoFiButton>
            <LoFiButton
              fullWidth
              size="lg"
              variant="outline"
              onClick={() => onNavigate('1C')}
            >
              <FillerText semantic="Sign In" tier="primary" skeletonWidth="w-20" />
            </LoFiButton>
            <p className="text-[11px] text-center text-neutral-400 pt-1">
              <FillerText
                semantic="By continuing, you accept the platform usage terms."
                tier="tertiary"
                skeletonWidth="w-56"
              />
            </p>
          </div>
        </div>
      </div>
    );
  }

  // 1B: Get Started / Sign Up
  if (activeScreen === '1B') {
    return (
      <div className="flex flex-col min-h-full bg-white">
        <LoFiTopBar
          title="Account Creation"
          subtitle="Flow 01 · Screen 1B"
          onBack={() => onNavigate('1A')}
        />
        <div className="flex-1 px-5 py-6 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-5">
            <div>
              <h2 className="text-xl font-bold text-neutral-900">
                <FillerText semantic="Create your account" tier="primary" />
              </h2>
              <p className="text-xs text-neutral-500 mt-1">
                <FillerText
                  semantic="Track your daily streak, word mastery, and placement scores across devices."
                  tier="tertiary"
                />
              </p>
            </div>

            <div className="space-y-3.5">
              <LoFiInput
                label="Email Address"
                placeholder="name@organization.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
              <LoFiInput
                label="Password Field"
                type="password"
                placeholder="••••••••••••"
                helperText="Minimum 8 characters with at least one number."
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>

            <LoFiButton
              fullWidth
              size="lg"
              variant="primary"
              onClick={() => onNavigate('1D')}
            >
              <FillerText semantic="Continue to Setup" tier="primary" />
            </LoFiButton>

            <div className="relative py-2">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-neutral-200" />
              </div>
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-white px-2 text-neutral-400 font-mono text-[10px]">
                  Or authenticate with
                </span>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2.5">
              <LoFiButton variant="outline" size="md">
                <FillerText semantic="Provider Alpha" tier="secondary" />
              </LoFiButton>
              <LoFiButton variant="outline" size="md">
                <FillerText semantic="Provider Beta" tier="secondary" />
              </LoFiButton>
            </div>
          </div>

          <div className="pt-6 text-center">
            <button
              onClick={() => onNavigate('1C')}
              className="text-xs text-neutral-700 hover:text-black underline font-medium cursor-pointer"
            >
              <FillerText semantic="Already have an account? Sign in" tier="secondary" />
            </button>
          </div>
        </div>
      </div>
    );
  }

  // 1C: Sign In Screen / Modal
  if (activeScreen === '1C') {
    return (
      <div className="flex flex-col min-h-full bg-white relative">
        <LoFiTopBar
          title="Sign In"
          subtitle="Flow 01 · Screen 1C"
          onBack={() => onNavigate('1A')}
        />
        <div className="flex-1 px-5 py-6 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-5">
            <div>
              <h2 className="text-xl font-bold text-neutral-900">
                <FillerText semantic="Welcome back" tier="primary" />
              </h2>
              <p className="text-xs text-neutral-500 mt-1">
                <FillerText
                  semantic="Enter your registered credentials to resume daily practice."
                  tier="tertiary"
                />
              </p>
            </div>

            <div className="space-y-3.5">
              <LoFiInput
                label="Email Address"
                placeholder="registered@domain.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
              <LoFiInput
                label="Password"
                type="password"
                placeholder="••••••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
              <div className="text-right">
                <button
                  onClick={() => setShowForgotModal(true)}
                  className="text-xs text-neutral-600 hover:text-black underline cursor-pointer"
                >
                  <FillerText semantic="Forgot password?" tier="secondary" />
                </button>
              </div>
            </div>

            <LoFiButton
              fullWidth
              size="lg"
              variant="primary"
              onClick={onCompleteOnboarding}
            >
              <FillerText semantic="Sign In" tier="primary" />
            </LoFiButton>
          </div>

          <div className="pt-6 text-center">
            <button
              onClick={() => onNavigate('1B')}
              className="text-xs text-neutral-700 hover:text-black underline font-medium cursor-pointer"
            >
              <FillerText semantic="Don't have an account? Sign up" tier="secondary" />
            </button>
          </div>
        </div>

        {/* Modal for Password Recovery */}
        {showForgotModal && (
          <div className="fixed inset-0 z-50 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4">
            <div className="bg-white rounded-2xl border border-neutral-300 p-5 max-w-sm w-full space-y-4 shadow-xl">
              <h3 className="text-base font-bold text-neutral-900">
                <FillerText semantic="Reset Password" tier="primary" />
              </h3>
              <p className="text-xs text-neutral-600">
                <FillerText
                  semantic="A recovery link placeholder will be dispatched to your registered address."
                  tier="tertiary"
                />
              </p>
              <LoFiInput placeholder="name@organization.com" />
              <div className="grid grid-cols-2 gap-2 pt-2">
                <LoFiButton
                  variant="outline"
                  size="md"
                  onClick={() => setShowForgotModal(false)}
                >
                  <FillerText semantic="Cancel" tier="secondary" />
                </LoFiButton>
                <LoFiButton
                  variant="primary"
                  size="md"
                  onClick={() => setShowForgotModal(false)}
                >
                  <FillerText semantic="Send Link" tier="primary" />
                </LoFiButton>
              </div>
            </div>
          </div>
        )}
      </div>
    );
  }

  // 1D: About You (Profile Setup 20%)
  if (activeScreen === '1D') {
    const targetLangs = [
      'Lorem',
      'Ipsum',
      'Dolor',
      'Sit',
      'Amet',
      'Consectetur',
    ];

    return (
      <div className="flex flex-col min-h-full bg-white">
        <LoFiTopBar
          title="About You"
          subtitle="Profile Setup · 20%"
          progress={20}
          onBack={() => onNavigate('1B')}
        />
        <div className="flex-1 px-5 py-6 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-6">
            <div>
              <h2 className="text-xl font-bold text-neutral-900">
                <FillerText semantic="Tell us about yourself" tier="primary" />
              </h2>
              <p className="text-xs text-neutral-500 mt-1">
                <FillerText
                  semantic="Lorem ipsum dolor sit amet, consectetur adipiscing elit sed do eiusmod."
                  tier="tertiary"
                />
              </p>
            </div>

            {/* Native language choice */}
            <div className="space-y-2">
              <label className="text-xs font-semibold uppercase text-neutral-600 tracking-wider">
                <FillerText semantic="Native Language" tier="secondary" />
              </label>
              <div className="relative">
                <select
                  value={nativeLang}
                  onChange={(e) => setNativeLang(e.target.value)}
                  className="w-full min-h-[44px] px-3.5 py-2.5 text-sm bg-white border border-neutral-300 rounded-lg text-neutral-900 focus:outline-none focus:ring-2 focus:ring-black cursor-pointer font-mono"
                >
                  <option value="Lorem Ipsum">Lorem Ipsum</option>
                  <option value="Dolor Sit">Dolor Sit</option>
                  <option value="Amet Consectetur">Amet Consectetur</option>
                </select>
              </div>
            </div>

            {/* Target language selector chips */}
            <div className="space-y-2">
              <label className="text-xs font-semibold uppercase text-neutral-600 tracking-wider">
                <FillerText semantic="Target Language to Learn" tier="secondary" />
              </label>
              <div className="grid grid-cols-2 gap-2">
                {targetLangs.map((lang, idx) => {
                  const isSelected = targetLang === lang;
                  return (
                    <button
                      key={idx}
                      onClick={() => setTargetLang(lang)}
                      className={`min-h-[44px] px-3 py-2 text-xs font-medium rounded-lg border text-left flex items-center justify-between transition-colors cursor-pointer font-mono ${
                        isSelected
                          ? 'border-black bg-neutral-100 text-black font-semibold'
                          : 'border-neutral-200 bg-white text-neutral-700 hover:border-neutral-400'
                      }`}
                    >
                      <FillerText semantic={lang} tier="secondary" skeletonWidth="w-20" />
                      {isSelected && <Check className="w-3.5 h-3.5 text-black shrink-0" />}
                    </button>
                  );
                })}
              </div>
            </div>
          </div>

          <div className="pt-6">
            <LoFiButton
              fullWidth
              size="lg"
              variant="primary"
              onClick={() => onNavigate('1E')}
            >
              <FillerText semantic="Continue (Your Plan)" tier="primary" />
            </LoFiButton>
          </div>
        </div>
      </div>
    );
  }

  // 1E: Your Plan (Profile Setup 50%)
  if (activeScreen === '1E') {
    const reasons = [
      { id: 'travel', title: 'Travel & Exploration', sub: 'Converse comfortably during trips' },
      { id: 'work', title: 'Work & Professional', sub: 'Build career vocabulary and email fluency' },
      { id: 'family', title: 'Friends & Community', sub: 'Connect with relatives and peers' },
      { id: 'curiosity', title: 'Personal Enrichment', sub: 'Cognitive exercise and literature' },
    ];

    const goals = [
      { id: '5', label: '5 min / day', sub: 'Casual' },
      { id: '10', label: '10 min / day', sub: 'Regular' },
      { id: '15', label: '15 min / day', sub: 'Serious' },
      { id: '20', label: '20 min / day', sub: 'Intense' },
    ];

    return (
      <div className="flex flex-col min-h-full bg-white">
        <LoFiTopBar
          title="Your Plan"
          subtitle="Profile Setup · 50%"
          progress={50}
          onBack={() => onNavigate('1D')}
        />
        <div className="flex-1 px-5 py-6 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-6">
            <div>
              <h2 className="text-xl font-bold text-neutral-900">
                <FillerText semantic="Why are you learning?" tier="primary" />
              </h2>
              <p className="text-xs text-neutral-500 mt-1">
                <FillerText
                  semantic="Choose one reason to calibrate contextual flashcards and themes."
                  tier="tertiary"
                />
              </p>
            </div>

            {/* Motivation Radio Cards */}
            <div className="space-y-2.5">
              {reasons.map((r) => {
                const isSelected = goalReason === r.id;
                return (
                  <div
                    key={r.id}
                    onClick={() => setGoalReason(r.id)}
                    className={`p-3.5 rounded-xl border flex items-center justify-between cursor-pointer min-h-[52px] transition-colors ${
                      isSelected
                        ? 'border-black bg-neutral-100 ring-1 ring-black'
                        : 'border-neutral-200 bg-white hover:border-neutral-300'
                    }`}
                  >
                    <div>
                      <p className="text-sm font-semibold text-neutral-900">
                        <FillerText semantic={r.title} tier="secondary" />
                      </p>
                      <p className="text-xs text-neutral-500">
                        <FillerText semantic={r.sub} tier="tertiary" />
                      </p>
                    </div>
                    <div
                      className={`w-5 h-5 rounded-full border flex items-center justify-center shrink-0 ${
                        isSelected ? 'border-black bg-black' : 'border-neutral-300'
                      }`}
                    >
                      {isSelected && <div className="w-2 h-2 rounded-full bg-white" />}
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Daily Practice Pace (Generalized & Simplified) */}
            <div className="space-y-2 pt-2">
              <div className="flex items-center justify-between text-xs font-semibold uppercase text-neutral-600 tracking-wider">
                <FillerText semantic="Daily Practice Goal" tier="secondary" />
                <span className="font-mono text-neutral-900 font-bold lowercase">
                  ~{dailyGoal} min/day
                </span>
              </div>
              <div className="grid grid-cols-4 gap-2">
                {['5', '10', '15', '20'].map((mins) => {
                  const isSelected = dailyGoal === mins;
                  return (
                    <button
                      key={mins}
                      onClick={() => setDailyGoal(mins)}
                      className={`min-h-[44px] py-2 rounded-lg border text-center font-mono font-bold text-xs transition-colors cursor-pointer ${
                        isSelected
                          ? 'border-black bg-black text-white'
                          : 'border-neutral-200 bg-neutral-50 text-neutral-700 hover:border-neutral-400'
                      }`}
                    >
                      {mins}m
                    </button>
                  );
                })}
              </div>
              <p className="text-[11px] text-neutral-500">
                <FillerText semantic="Lorem ipsum dolor sit amet pace target" tier="tertiary" />
              </p>
            </div>
          </div>

          <div className="pt-6">
            <LoFiButton
              fullWidth
              size="lg"
              variant="primary"
              onClick={() => onNavigate('1F')}
            >
              <FillerText semantic="Continue (Your Level)" tier="primary" />
            </LoFiButton>
          </div>
        </div>
      </div>
    );
  }

  // 1F: Your Level (Profile Setup 75%)
  if (activeScreen === '1F') {
    const levels = [
      { id: 'beginner', title: 'Absolute Beginner', desc: 'Starting from zero words and basic sounds' },
      { id: 'intermediate', title: 'Intermediate Learner', desc: 'Can handle familiar everyday conversations' },
      { id: 'advanced', title: 'Advanced Fluency', desc: 'Reading complex articles and nuanced grammar' },
    ];

    const quizOptions = [
      'Option A: Lorem ipsum dolor sit amet',
      'Option B: Consectetur adipiscing elit',
      'Option C: Sed do eiusmod tempor incididunt',
    ];

    return (
      <div className="flex flex-col min-h-full bg-white">
        <LoFiTopBar
          title="Your Level"
          subtitle="Profile Setup · 75%"
          progress={75}
          onBack={() => onNavigate('1E')}
        />
        <div className="flex-1 px-5 py-6 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-6">
            <div>
              <h2 className="text-xl font-bold text-neutral-900">
                <FillerText semantic="What's your experience?" tier="primary" />
              </h2>
              <p className="text-xs text-neutral-500 mt-1">
                <FillerText
                  semantic="Pick the description that feels closest. No test is required."
                  tier="tertiary"
                />
              </p>
            </div>

            {/* Level Tier Cards */}
            <div className="space-y-2.5">
              {levels.map((lvl) => {
                const isSelected = selectedLevel === lvl.id;
                return (
                  <div
                    key={lvl.id}
                    onClick={() => setSelectedLevel(lvl.id)}
                    className={`p-3.5 rounded-xl border cursor-pointer min-h-[52px] transition-colors ${
                      isSelected
                        ? 'border-black bg-neutral-100 ring-1 ring-black'
                        : 'border-neutral-200 bg-white hover:border-neutral-300'
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <p className="text-sm font-semibold text-neutral-900">
                        <FillerText semantic={lvl.title} tier="secondary" />
                      </p>
                      <div
                        className={`w-4 h-4 rounded-full border flex items-center justify-center shrink-0 ${
                          isSelected ? 'border-black bg-black' : 'border-neutral-300'
                        }`}
                      >
                        {isSelected && <div className="w-1.5 h-1.5 rounded-full bg-white" />}
                      </div>
                    </div>
                    <p className="text-xs text-neutral-500 mt-1">
                      <FillerText semantic={lvl.desc} tier="tertiary" />
                    </p>
                  </div>
                );
              })}
            </div>

            {/* Quick Placement Check Card */}
            <div className="p-4 rounded-xl border border-neutral-300 bg-neutral-50 space-y-3">
              <div className="flex items-center justify-between text-xs text-neutral-500">
                <span className="font-mono uppercase font-semibold">
                  <FillerText semantic="Quick Check · 1 of 1" tier="secondary" />
                </span>
                <span className="text-[11px] bg-neutral-200 px-2 py-0.5 rounded text-neutral-700">Optional</span>
              </div>
              <p className="text-xs font-semibold text-neutral-800">
                <FillerText
                  semantic="Lorem ipsum dolor sit amet, consectetur adipiscing elit?"
                  tier="secondary"
                />
              </p>

              <div className="space-y-1.5">
                {quizOptions.map((opt, i) => (
                  <button
                    key={i}
                    onClick={() => setQuizAnswer(i)}
                    className={`w-full text-left min-h-[40px] px-3 py-2 text-xs rounded-lg border transition-colors cursor-pointer ${
                      quizAnswer === i
                        ? 'border-black bg-neutral-200 font-medium text-black'
                        : 'border-neutral-200 bg-white text-neutral-700 hover:border-neutral-300'
                    }`}
                  >
                    <FillerText semantic={opt} tier="secondary" />
                  </button>
                ))}
              </div>

              {quizChecked && (
                <div className="text-xs p-2 rounded bg-neutral-200 text-black font-medium">
                  ✓ <FillerText semantic="Lorem ipsum dolor sit amet recorded." tier="secondary" />
                </div>
              )}

              {!quizChecked && quizAnswer !== null && (
                <LoFiButton
                  size="sm"
                  variant="secondary"
                  onClick={() => setQuizChecked(true)}
                >
                  <FillerText semantic="Check Answer" tier="primary" />
                </LoFiButton>
              )}
            </div>
          </div>

          <div className="pt-6">
            <LoFiButton
              fullWidth
              size="lg"
              variant="primary"
              onClick={() => onNavigate('1G')}
            >
              <FillerText semantic="Continue (Readiness)" tier="primary" />
            </LoFiButton>
          </div>
        </div>
      </div>
    );
  }

  // 1G: You're Ready (Profile Setup Complete 100%)
  if (activeScreen === '1G') {
    return (
      <div className="flex flex-col min-h-full bg-white">
        <LoFiTopBar
          title="Setup Complete"
          subtitle="Profile Setup · 100%"
          progress={100}
          onBack={() => onNavigate('1F')}
        />
        <div className="flex-1 px-5 py-6 flex flex-col justify-between max-w-md mx-auto w-full">
          <div className="space-y-6">
            <div className="text-center space-y-2">
              <div className="w-14 h-14 rounded-full bg-black text-white flex items-center justify-center mx-auto">
                <Check className="w-7 h-7" />
              </div>
              <h2 className="text-2xl font-bold text-neutral-900">
                <FillerText semantic="You're ready to start" tier="primary" />
              </h2>
              <p className="text-xs text-neutral-500 max-w-xs mx-auto">
                <FillerText
                  semantic="Your starting plan is configured based on your responses and the short calibration."
                  tier="tertiary"
                />
              </p>
            </div>

            {/* Summary Specification Box */}
            <div className="p-4 rounded-xl border border-neutral-300 bg-neutral-50 space-y-3">
              <div className="text-xs font-mono uppercase text-neutral-500 border-b border-neutral-200 pb-2">
                <FillerText semantic="Starting Curriculum Profile" tier="secondary" />
              </div>
              <div className="grid grid-cols-2 gap-3 text-xs">
                <div>
                  <span className="text-neutral-400 block text-[10px] uppercase font-semibold">Tier</span>
                  <span className="font-semibold text-neutral-900 font-mono">
                    <FillerText semantic="Lorem Ipsum" tier="secondary" />
                  </span>
                </div>
                <div>
                  <span className="text-neutral-400 block text-[10px] uppercase font-semibold">Pace</span>
                  <span className="font-semibold text-neutral-900 font-mono">
                    <FillerText semantic="Dolor Sit · ~10m" tier="secondary" />
                  </span>
                </div>
                <div className="col-span-2">
                  <span className="text-neutral-400 block text-[10px] uppercase font-semibold">Daily Format</span>
                  <span className="text-neutral-700">
                    <FillerText
                      semantic="Lorem ipsum dolor sit amet, consectetur adipiscing elit."
                      tier="tertiary"
                    />
                  </span>
                </div>
              </div>
            </div>

            {/* Practice Reminders Switch */}
            <div className="border border-neutral-200 rounded-xl p-1 bg-white">
              <LoFiToggle
                checked={allowReminders}
                onChange={setAllowReminders}
                label="Allow practice notifications"
                description="Get a quiet daily prompt at your selected practice hour."
              />
            </div>
          </div>

          <div className="pt-6 space-y-2">
            <LoFiButton
              fullWidth
              size="lg"
              variant="primary"
              onClick={onCompleteOnboarding}
            >
              <FillerText semantic="Go to Home Dashboard" tier="primary" />
            </LoFiButton>
            <p className="text-[11px] text-center text-neutral-400">
              <FillerText
                semantic="You can update language, pace, and reminders anytime in settings."
                tier="tertiary"
              />
            </p>
          </div>
        </div>
      </div>
    );
  }

  return null;
}
