"use client";

import { useEffect, useState, useCallback } from "react";
import {
  fetchSeasonalTipWeeks,
  type SeasonalTipWeek,
  type SeasonalTip,
} from "@/lib/firestore";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  CardDescription,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Lightbulb,
  RefreshCw,
  ChevronDown,
  ChevronUp,
  Sparkles,
  Calendar,
  Coins,
  Loader2,
} from "lucide-react";
import { format } from "date-fns";

const CATEGORY_COLORS: Record<string, string> = {
  watering: "bg-blue-100 text-blue-700",
  light: "bg-amber-100 text-amber-700",
  pests: "bg-red-100 text-red-700",
  fertilizing: "bg-green-100 text-green-700",
  seasonal: "bg-purple-100 text-purple-700",
  general: "bg-gray-100 text-gray-700",
};

const DAY_LABELS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

function getGenerateUrl(): string {
  const projectId = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || "";
  return `https://us-central1-${projectId}.cloudfunctions.net/generateSeasonalTips`;
}

function getCurrentWeekKey(): string {
  const now = new Date();
  const d = new Date(
    Date.UTC(now.getFullYear(), now.getMonth(), now.getDate())
  );
  const dayNum = d.getUTCDay() || 7;
  d.setUTCDate(d.getUTCDate() + 4 - dayNum);
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  const week = Math.ceil(
    ((d.getTime() - yearStart.getTime()) / 86400000 + 1) / 7
  );
  return `${now.getFullYear()}-W${String(week).padStart(2, "0")}`;
}

function TipRow({ tip, lang }: { tip: SeasonalTip; lang: string }) {
  const text = (tip as unknown as Record<string, string>)[lang] || tip.en;
  return (
    <TableRow>
      <TableCell className="w-10 text-center font-mono text-xs text-muted-foreground">
        {tip.index + 1}
      </TableCell>
      <TableCell className="w-20 text-center text-xs text-muted-foreground">
        {DAY_LABELS[Math.floor(tip.index / 3)] ?? "—"}
      </TableCell>
      <TableCell>
        <Badge
          variant="secondary"
          className={`text-[11px] ${CATEGORY_COLORS[tip.category] || CATEGORY_COLORS.general}`}
        >
          {tip.category}
        </Badge>
      </TableCell>
      <TableCell className="text-sm">{text}</TableCell>
    </TableRow>
  );
}

function WeekCard({ week }: { week: SeasonalTipWeek }) {
  const [open, setOpen] = useState(false);
  const [lang, setLang] = useState("en");
  const isCurrent = week.weekKey === getCurrentWeekKey();

  const dayIndex = new Date().getDay() === 0 ? 6 : new Date().getDay() - 1;
  const todayStart = dayIndex * 3;
  const todayTips = week.tips.slice(todayStart, todayStart + 3);

  return (
    <Card>
      <CardHeader
        className="cursor-pointer select-none"
        onClick={() => setOpen(!open)}
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <CardTitle className="text-base">{week.weekKey}</CardTitle>
            {isCurrent && (
              <Badge className="bg-green-600 text-white text-[10px]">
                Current
              </Badge>
            )}
            <Badge variant="outline" className="text-[10px]">
              {week.season} · {week.month}
            </Badge>
          </div>
          <div className="flex items-center gap-4">
            <span className="text-xs text-muted-foreground">
              {week.tips.length} tips
            </span>
            {open ? (
              <ChevronUp className="h-4 w-4" />
            ) : (
              <ChevronDown className="h-4 w-4" />
            )}
          </div>
        </div>
        <CardDescription className="flex items-center gap-4 mt-1">
          {week.generatedAt && (
            <span className="flex items-center gap-1">
              <Calendar className="h-3 w-3" />
              {format(week.generatedAt, "MMM d, yyyy HH:mm")}
            </span>
          )}
          {week.model && (
            <span className="flex items-center gap-1">
              <Sparkles className="h-3 w-3" />
              {week.model}
            </span>
          )}
          {week.usage && (
            <span className="flex items-center gap-1">
              <Lightbulb className="h-3 w-3" />
              {week.usage.total_tokens.toLocaleString()} tokens
            </span>
          )}
          {week.estimatedCostUsd != null && (
            <span className="flex items-center gap-1">
              <Coins className="h-3 w-3" />${week.estimatedCostUsd.toFixed(4)}
            </span>
          )}
        </CardDescription>
      </CardHeader>

      {isCurrent && !open && todayTips.length > 0 && (
        <CardContent className="pt-0">
          <p className="mb-2 text-xs font-medium text-muted-foreground">
            Today&apos;s tips ({DAY_LABELS[dayIndex]}):
          </p>
          <div className="space-y-2">
            {todayTips.map((t) => (
              <div
                key={t.index}
                className="flex items-start gap-2 rounded-md border p-3"
              >
                <Badge
                  variant="secondary"
                  className={`mt-0.5 text-[10px] shrink-0 ${CATEGORY_COLORS[t.category] || CATEGORY_COLORS.general}`}
                >
                  {t.category}
                </Badge>
                <span className="text-sm">{t.en}</span>
              </div>
            ))}
          </div>
        </CardContent>
      )}

      {open && (
        <CardContent className="pt-0">
          <div className="mb-3 flex items-center gap-2">
            <span className="text-xs text-muted-foreground">Language:</span>
            {["en", "de", "es", "fr"].map((l) => (
              <Button
                key={l}
                variant={lang === l ? "default" : "outline"}
                size="sm"
                className="h-6 px-2 text-xs"
                onClick={(e) => {
                  e.stopPropagation();
                  setLang(l);
                }}
              >
                {l.toUpperCase()}
              </Button>
            ))}
          </div>

          <div className="rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-10 text-center">#</TableHead>
                  <TableHead className="w-20 text-center">Day</TableHead>
                  <TableHead className="w-28">Category</TableHead>
                  <TableHead>Tip</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {week.tips.map((tip) => (
                  <TipRow key={tip.index} tip={tip} lang={lang} />
                ))}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      )}
    </Card>
  );
}

export default function TipsPage() {
  const [weeks, setWeeks] = useState<SeasonalTipWeek[]>([]);
  const [loading, setLoading] = useState(true);
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState("");

  const load = useCallback(() => {
    setLoading(true);
    fetchSeasonalTipWeeks(12)
      .then(setWeeks)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const handleGenerate = async () => {
    if (
      !confirm(
        "Generate 21 new seasonal tips for this week? This will call OpenAI."
      )
    )
      return;
    setGenerating(true);
    try {
      const res = await fetch(getGenerateUrl(), { method: "POST" });
      const data = await res.json();
      if (!data.success) throw new Error(data.error || "Generation failed");
      load();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Generation failed");
    } finally {
      setGenerating(false);
    }
  };

  if (loading) {
    return (
      <div className="flex h-full items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-green-600 border-t-transparent" />
      </div>
    );
  }

  const totalCost = weeks.reduce(
    (sum, w) => sum + (w.estimatedCostUsd ?? 0),
    0
  );
  const totalTokens = weeks.reduce(
    (sum, w) => sum + (w.usage?.total_tokens ?? 0),
    0
  );

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">Seasonal Tips</h1>
          <p className="text-sm text-muted-foreground">
            AI-generated weekly plant care tips · {weeks.length} weeks
          </p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={load}>
            <RefreshCw className="mr-1 h-3.5 w-3.5" />
            Refresh
          </Button>
          <Button
            size="sm"
            className="bg-green-600 hover:bg-green-700"
            onClick={handleGenerate}
            disabled={generating}
          >
            {generating ? (
              <Loader2 className="mr-1 h-3.5 w-3.5 animate-spin" />
            ) : (
              <Sparkles className="mr-1 h-3.5 w-3.5" />
            )}
            Generate This Week
          </Button>
        </div>
      </div>

      {error && (
        <div className="rounded-md bg-destructive/10 p-4 text-sm text-destructive">
          {error}
        </div>
      )}

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Total Weeks
            </CardTitle>
            <Calendar className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold">{weeks.length}</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Total Tips
            </CardTitle>
            <Lightbulb className="h-4 w-4 text-green-600" />
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold">
              {weeks.reduce((s, w) => s + w.tips.length, 0)}
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Total Tokens
            </CardTitle>
            <Sparkles className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold">
              {totalTokens.toLocaleString()}
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-sm font-medium text-muted-foreground">
              Total Cost
            </CardTitle>
            <Coins className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold">${totalCost.toFixed(4)}</p>
          </CardContent>
        </Card>
      </div>

      <div className="space-y-4">
        {weeks.length === 0 ? (
          <Card>
            <CardContent className="flex flex-col items-center justify-center py-12 text-center">
              <Lightbulb className="mb-3 h-10 w-10 text-muted-foreground" />
              <p className="text-muted-foreground">
                No tips generated yet. Click &quot;Generate This Week&quot; to
                create the first batch.
              </p>
            </CardContent>
          </Card>
        ) : (
          weeks.map((week) => <WeekCard key={week.weekKey} week={week} />)
        )}
      </div>
    </div>
  );
}
