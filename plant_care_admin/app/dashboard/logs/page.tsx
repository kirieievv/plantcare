"use client";

import { useEffect, useState } from "react";
import {
  fetchMailLogs,
  fetchFcmTokens,
  fetchUsers,
  fetchHealthChecks,
  fetchAiUsage,
  fetchAiTotals,
  fetchAiDailyStats,
  type MailLog,
  type FcmToken,
  type AdminUser,
  type HealthCheck,
  type AiUsageRecord,
  type AiTotals,
  type AiDailyRecord,
} from "@/lib/firestore";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { format } from "date-fns";
import { Search, Mail, CheckCircle2, XCircle, Clock, Smartphone, Users, HeartPulse, Sparkles } from "lucide-react";
import Link from "next/link";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";

const TYPE_LABELS: Record<string, string> = {
  health_check: "Health Check",
  chat: "Chat",
  watering_email: "Watering Email",
  plant_analysis: "Plant Analysis",
  plant_identification: "Plant ID",
};

function deliveryBadge(state?: string) {
  if (!state) return <Badge variant="secondary" className="text-xs gap-1"><Clock className="h-3 w-3" />Pending</Badge>;
  if (state === "SUCCESS") return <Badge className="bg-green-100 text-green-700 text-xs gap-1"><CheckCircle2 className="h-3 w-3" />Sent</Badge>;
  if (state === "ERROR") return <Badge variant="destructive" className="text-xs gap-1"><XCircle className="h-3 w-3" />Error</Badge>;
  return <Badge variant="outline" className="text-xs">{state}</Badge>;
}

function StatCard({ icon: Icon, value, label, color }: { icon: React.ElementType; value: number | string; label: string; color: string }) {
  return (
    <Card>
      <CardContent className="pt-4 pb-4 flex items-center gap-3">
        <div className={`h-10 w-10 rounded-lg flex items-center justify-center ${color}`}>
          <Icon className="h-5 w-5" />
        </div>
        <div>
          <p className="text-2xl font-bold">{value}</p>
          <p className="text-xs text-muted-foreground">{label}</p>
        </div>
      </CardContent>
    </Card>
  );
}

export default function LogsPage() {
  const [logs, setLogs] = useState<MailLog[]>([]);
  const [tokens, setTokens] = useState<FcmToken[]>([]);
  const [users, setUsers] = useState<Record<string, AdminUser>>({});
  const [healthChecks, setHealthChecks] = useState<HealthCheck[]>([]);
  const [aiRecords, setAiRecords] = useState<AiUsageRecord[]>([]);
  const [aiTotals, setAiTotals] = useState<AiTotals | null>(null);
  const [aiDaily, setAiDaily] = useState<AiDailyRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [emailSearch, setEmailSearch] = useState("");
  const [pushSearch, setPushSearch] = useState("");
  const [hcSearch, setHcSearch] = useState("");
  const [aiTypeFilter, setAiTypeFilter] = useState<string>("all");
  const [emailFilter, setEmailFilter] = useState<"all" | "sent" | "error" | "pending">("all");

  useEffect(() => {
    Promise.all([
      fetchMailLogs(200),
      fetchFcmTokens(),
      fetchUsers(),
      fetchHealthChecks(300),
      fetchAiUsage(500),
      fetchAiTotals(),
      fetchAiDailyStats(30),
    ])
      .then(([l, t, u, hc, ai, totals, daily]) => {
        setLogs(l);
        setTokens(t);
        const map: Record<string, AdminUser> = {};
        u.forEach((user) => { map[user.uid] = user; });
        setUsers(map);
        setHealthChecks(hc);
        setAiRecords(ai);
        setAiTotals(totals);
        setAiDaily(daily);
      })
      .finally(() => setLoading(false));
  }, []);

  const errorCount = logs.filter((l) => l.delivery?.state === "ERROR").length;
  const sentCount = logs.filter((l) => l.delivery?.state === "SUCCESS").length;
  const pendingCount = logs.filter((l) => !l.delivery?.state).length;

  const usersWithTokens = new Set(tokens.map((t) => t.userId)).size;

  // ── AI usage index by userId ──
  const aiByUser: Record<string, AiUsageRecord[]> = {};
  aiRecords.forEach((r) => {
    if (r.userId) {
      if (!aiByUser[r.userId]) aiByUser[r.userId] = [];
      aiByUser[r.userId].push(r);
    }
  });
  const hcAiMap = new Map<string, AiUsageRecord>();
  const hcAiByUserPlant: Record<string, AiUsageRecord[]> = {};
  for (const r of aiRecords) {
    if (r.type !== "health_check" || !r.userId || !r.plantId) continue;
    const key = `${r.userId}|${r.plantId}`;
    if (!hcAiByUserPlant[key]) hcAiByUserPlant[key] = [];
    hcAiByUserPlant[key].push(r);
  }
  for (const hc of healthChecks) {
    const candidates = hcAiByUserPlant[`${hc.userId}|${hc.plantId}`];
    if (!candidates?.length) continue;
    const hcTime = hc.createdAt?.getTime() ?? 0;
    let best = candidates[0];
    let bestDiff = Math.abs((best.timestamp?.getTime() ?? 0) - hcTime);
    for (const c of candidates) {
      const diff = Math.abs((c.timestamp?.getTime() ?? 0) - hcTime);
      if (diff < bestDiff) { best = c; bestDiff = diff; }
    }
    if (bestDiff < 5 * 60 * 1000) hcAiMap.set(hc.id, best);
  }

  const filteredHc = healthChecks.filter((hc) => {
    const q = hcSearch.toLowerCase();
    if (!q) return true;
    const user = users[hc.userId];
    return (
      hc.plantId.toLowerCase().includes(q) ||
      hc.userId.toLowerCase().includes(q) ||
      (hc.plantName || "").toLowerCase().includes(q) ||
      (user?.name || "").toLowerCase().includes(q) ||
      (user?.email || "").toLowerCase().includes(q)
    );
  });

  const filteredLogs = logs.filter((l) => {
    const q = emailSearch.toLowerCase();
    const matchesSearch = !q || l.to.toLowerCase().includes(q) || (l.subject || "").toLowerCase().includes(q);
    const matchesFilter =
      emailFilter === "all" ||
      (emailFilter === "sent" && l.delivery?.state === "SUCCESS") ||
      (emailFilter === "error" && l.delivery?.state === "ERROR") ||
      (emailFilter === "pending" && !l.delivery?.state);
    return matchesSearch && matchesFilter;
  });

  const filteredTokens = tokens.filter((t) => {
    const q = pushSearch.toLowerCase();
    const user = users[t.userId];
    return (
      !q ||
      t.userId.toLowerCase().includes(q) ||
      (user?.email || "").toLowerCase().includes(q) ||
      (user?.name || "").toLowerCase().includes(q)
    );
  });

  if (loading) {
    return (
      <div className="flex h-full items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-green-600 border-t-transparent" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <h1 className="text-2xl font-bold">Logs</h1>

      <Tabs defaultValue="emails">
        <TabsList>
          <TabsTrigger value="emails" className="gap-2">
            <Mail className="h-4 w-4" /> Emails
            {errorCount > 0 && (
              <Badge variant="destructive" className="ml-1 h-5 px-1.5 text-xs">{errorCount}</Badge>
            )}
          </TabsTrigger>
          <TabsTrigger value="push" className="gap-2">
            <Smartphone className="h-4 w-4" /> Push Tokens
            <Badge variant="secondary" className="ml-1 h-5 px-1.5 text-xs">{tokens.length}</Badge>
          </TabsTrigger>
          <TabsTrigger value="health" className="gap-2">
            <HeartPulse className="h-4 w-4" /> Health Checks
            <Badge variant="secondary" className="ml-1 h-5 px-1.5 text-xs">{healthChecks.length}</Badge>
          </TabsTrigger>
          <TabsTrigger value="ai" className="gap-2">
            <Sparkles className="h-4 w-4" /> AI Usage
            <Badge variant="secondary" className="ml-1 h-5 px-1.5 text-xs">{aiRecords.length}</Badge>
          </TabsTrigger>
        </TabsList>

        {/* ── EMAIL TAB ──────────────────────────────────────────── */}
        <TabsContent value="emails" className="space-y-4 mt-4">
          <div className="grid grid-cols-3 gap-4">
            <StatCard icon={Mail} value={logs.length} label="Total emails" color="bg-blue-100 text-blue-600" />
            <StatCard icon={CheckCircle2} value={sentCount} label="Delivered" color="bg-green-100 text-green-600" />
            <StatCard icon={XCircle} value={errorCount} label="Failed" color="bg-red-100 text-red-600" />
          </div>

          <Card>
            <CardHeader className="pb-3 flex flex-row items-center gap-3">
              <div className="relative flex-1">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  placeholder="Search by recipient or subject…"
                  value={emailSearch}
                  onChange={(e) => setEmailSearch(e.target.value)}
                  className="pl-9"
                />
              </div>
              <div className="flex gap-1">
                {(["all", "sent", "error", "pending"] as const).map((f) => (
                  <button
                    key={f}
                    onClick={() => setEmailFilter(f)}
                    className={`px-3 py-1.5 rounded-md text-xs font-medium transition-colors ${
                      emailFilter === f
                        ? "bg-foreground text-background"
                        : "bg-muted text-muted-foreground hover:text-foreground"
                    }`}
                  >
                    {f === "all" ? `All (${logs.length})` :
                     f === "sent" ? `Sent (${sentCount})` :
                     f === "error" ? `Errors (${errorCount})` :
                     `Pending (${pendingCount})`}
                  </button>
                ))}
              </div>
            </CardHeader>
            <CardContent className="p-0">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">To</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Subject</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Status</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Attempts</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Sent at</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredLogs.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} className="py-10 text-center text-muted-foreground">
                        No emails found.
                      </TableCell>
                    </TableRow>
                  ) : (
                    filteredLogs.map((log) => (
                      <TableRow key={log.id} className="hover:bg-muted/50">
                        <TableCell className="text-sm font-medium">{log.to}</TableCell>
                        <TableCell className="text-sm max-w-xs truncate text-muted-foreground">{log.subject || "—"}</TableCell>
                        <TableCell>
                          <div className="flex flex-col gap-1">
                            {deliveryBadge(log.delivery?.state)}
                            {log.delivery?.error && (
                              <p className="text-xs text-destructive max-w-[260px] break-words leading-tight">
                                {log.delivery.error}
                              </p>
                            )}
                          </div>
                        </TableCell>
                        <TableCell className="text-sm text-muted-foreground">{log.delivery?.attempts ?? "—"}</TableCell>
                        <TableCell className="text-xs text-muted-foreground">
                          {log.createdAt ? format(log.createdAt, "MMM d, HH:mm") : "—"}
                        </TableCell>
                      </TableRow>
                    ))
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* ── PUSH TAB ───────────────────────────────────────────── */}
        <TabsContent value="push" className="space-y-4 mt-4">
          <div className="grid grid-cols-3 gap-4">
            <StatCard icon={Smartphone} value={tokens.length} label="Registered tokens" color="bg-purple-100 text-purple-600" />
            <StatCard icon={Users} value={usersWithTokens} label="Users with push" color="bg-green-100 text-green-600" />
            <StatCard icon={Smartphone} value={tokens.length - usersWithTokens} label="Extra tokens (multi-device)" color="bg-orange-100 text-orange-600" />
          </div>

          <Card>
            <CardHeader className="pb-3">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  placeholder="Search by user name or email…"
                  value={pushSearch}
                  onChange={(e) => setPushSearch(e.target.value)}
                  className="pl-9"
                />
              </div>
            </CardHeader>
            <CardContent className="p-0">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">User</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Tokens</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Token (truncated)</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Platform</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Registered</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredTokens.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} className="py-10 text-center text-muted-foreground">
                        No push tokens found.
                      </TableCell>
                    </TableRow>
                  ) : (() => {
                    // Group by userId
                    const grouped: Record<string, FcmToken[]> = {};
                    filteredTokens.forEach((t) => {
                      if (!grouped[t.userId]) grouped[t.userId] = [];
                      grouped[t.userId].push(t);
                    });
                    return Object.entries(grouped).flatMap(([uid, userTokens]) => {
                      const user = users[uid];
                      return userTokens.map((t, idx) => (
                        <TableRow key={t.id} className={`hover:bg-muted/50 ${userTokens.length > 1 ? "bg-orange-50/40" : ""}`}>
                          <TableCell>
                            {idx === 0 ? (
                              user ? (
                                <Link href={`/dashboard/users/${uid}`} className="hover:underline">
                                  <p className="text-sm font-medium">{user.name || "—"}</p>
                                  <p className="text-xs text-muted-foreground">{user.email}</p>
                                </Link>
                              ) : (
                                <div>
                                  <p className="text-xs font-mono text-muted-foreground">{uid.slice(0, 20)}…</p>
                                  <Badge variant="destructive" className="text-xs mt-1">No profile — orphan</Badge>
                                </div>
                              )
                            ) : null}
                          </TableCell>
                          <TableCell>
                            {idx === 0 && userTokens.length > 1 && (
                              <Badge className="bg-orange-100 text-orange-700 text-xs">{userTokens.length} devices</Badge>
                            )}
                            {idx === 0 && userTokens.length === 1 && (
                              <Badge variant="outline" className="text-xs">1 device</Badge>
                            )}
                          </TableCell>
                          <TableCell className="font-mono text-xs text-muted-foreground">
                            {t.token.slice(0, 20)}…
                          </TableCell>
                          <TableCell>
                            <Badge variant="outline" className="text-xs">{t.platform || "iOS"}</Badge>
                          </TableCell>
                          <TableCell className="text-xs text-muted-foreground">
                            {t.createdAt ? format(t.createdAt, "MMM d, yyyy") : "—"}
                          </TableCell>
                        </TableRow>
                      ));
                    });
                  })()}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* ── HEALTH CHECKS TAB ──────────────────────────────── */}
        <TabsContent value="health" className="space-y-4 mt-4">
          <div className="grid grid-cols-3 gap-4">
            <StatCard icon={HeartPulse} value={healthChecks.length} label="Total checks" color="bg-green-100 text-green-600" />
            <StatCard icon={Users} value={new Set(healthChecks.map((h) => h.userId)).size} label="Users checked" color="bg-blue-100 text-blue-600" />
            <StatCard icon={Sparkles} value={aiRecords.filter((r) => r.type === "health_check").length} label="AI calls" color="bg-purple-100 text-purple-600" />
          </div>

          <Card>
            <CardHeader className="pb-3">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                <Input
                  placeholder="Search by user or plant…"
                  value={hcSearch}
                  onChange={(e) => setHcSearch(e.target.value)}
                  className="pl-9"
                />
              </div>
            </CardHeader>
            <CardContent className="p-0">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">User</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Plant</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Status</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground text-right">Cost</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Date</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredHc.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={5} className="py-10 text-center text-muted-foreground">
                        No health checks found.
                      </TableCell>
                    </TableRow>
                  ) : (
                    filteredHc.map((hc) => {
                      const user = users[hc.userId];
                      return (
                        <TableRow key={hc.id} className="hover:bg-muted/50">
                          <TableCell>
                            {user ? (
                              <Link href={`/dashboard/users/${hc.userId}`} className="hover:underline">
                                <p className="text-sm font-medium">{user.name || "—"}</p>
                                <p className="text-xs text-muted-foreground">{user.email}</p>
                              </Link>
                            ) : (
                              <p className="text-xs font-mono text-muted-foreground">{hc.userId.slice(0, 16)}…</p>
                            )}
                          </TableCell>
                          <TableCell className="text-sm text-muted-foreground">
                            {hc.plantName || hc.plantId.slice(0, 12) + "…"}
                          </TableCell>
                          <TableCell>
                            {hc.status === "ok" ? (
                              <Badge className="bg-green-100 text-green-700 text-xs">OK</Badge>
                            ) : hc.status === "issue" ? (
                              <Badge variant="destructive" className="text-xs">Issue</Badge>
                            ) : (
                              <Badge variant="outline" className="text-xs">{hc.status || "—"}</Badge>
                            )}
                          </TableCell>
                          <TableCell className="text-right text-xs">
                            {(() => {
                              const ai = hcAiMap.get(hc.id);
                              if (!ai) return <span className="text-muted-foreground">—</span>;
                              return (
                                <span className="font-mono">
                                  ${ai.costUsd?.toFixed(4) ?? "?"}
                                  <span className="ml-1 text-muted-foreground">
                                    ({ai.totalTokens.toLocaleString()})
                                  </span>
                                </span>
                              );
                            })()}
                          </TableCell>
                          <TableCell className="text-xs text-muted-foreground">
                            {hc.createdAt ? format(hc.createdAt, "MMM d, yyyy HH:mm") : "—"}
                          </TableCell>
                        </TableRow>
                      );
                    })
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>

        {/* ── AI USAGE TAB ───────────────────────────────────── */}
        <TabsContent value="ai" className="space-y-4 mt-4">
          {/* Stat cards — accurate totals from aggregation */}
          <div className="grid grid-cols-4 gap-4">
            <StatCard icon={Sparkles} value={aiTotals?.totalCalls.toLocaleString() ?? "—"} label="Total AI calls (all time)" color="bg-purple-100 text-purple-600" />
            <StatCard icon={Users} value={new Set(aiRecords.filter((r) => r.userId).map((r) => r.userId!)).size} label="Users using AI (last 500)" color="bg-blue-100 text-blue-600" />
            <Card>
              <CardContent className="pt-4 pb-4 flex items-center gap-3">
                <div className="h-10 w-10 rounded-lg flex items-center justify-center bg-green-100 text-green-600">
                  <Sparkles className="h-5 w-5" />
                </div>
                <div>
                  <p className="text-2xl font-bold">{aiTotals ? `$${aiTotals.totalCostUsd.toFixed(4)}` : "—"}</p>
                  <p className="text-xs text-muted-foreground">Total AI cost (all time)</p>
                </div>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="pt-4 pb-4 flex items-center gap-3">
                <div className="h-10 w-10 rounded-lg flex items-center justify-center bg-orange-100 text-orange-600">
                  <Sparkles className="h-5 w-5" />
                </div>
                <div>
                  <p className="text-2xl font-bold">{aiTotals ? aiTotals.totalTokens.toLocaleString() : "—"}</p>
                  <p className="text-xs text-muted-foreground">Total tokens (all time)</p>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Daily cost chart */}
          {aiDaily.some((d) => d.totalCostUsd > 0) && (
            <Card>
              <CardHeader>
                <CardTitle className="text-base">AI Cost — Last 30 Days</CardTitle>
                <CardDescription>Daily spend in USD (from ai_usage_daily)</CardDescription>
              </CardHeader>
              <CardContent>
                <ResponsiveContainer width="100%" height={200}>
                  <BarChart data={aiDaily}>
                    <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                    <XAxis
                      dataKey="date"
                      tick={{ fontSize: 10 }}
                      tickFormatter={(v: string) => v.slice(5)}
                      interval={4}
                    />
                    <YAxis tick={{ fontSize: 10 }} tickFormatter={(v: number) => `$${v.toFixed(2)}`} />
                    <Tooltip
                      formatter={(v: unknown) => [`$${Number(v ?? 0).toFixed(4)}`, "Cost"]}
                      labelFormatter={(v: unknown) => `Date: ${String(v ?? "")}`}
                    />
                    <Bar dataKey="totalCostUsd" fill="#a855f7" radius={[3, 3, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </Card>
          )}

          {/* Records table with type filter */}
          <Card>
            <CardHeader className="pb-3 flex flex-row items-center gap-3">
              <p className="text-xs text-muted-foreground flex-1">Last 500 records</p>
              <div className="flex gap-1 flex-wrap">
                {(["all", "watering_email", "plant_analysis", "plant_identification", "health_check", "chat", "seasonal_tips"] as const).map((f) => (
                  <button
                    key={f}
                    onClick={() => setAiTypeFilter(f)}
                    className={`px-2 py-1 rounded-md text-xs font-medium transition-colors ${
                      aiTypeFilter === f
                        ? "bg-foreground text-background"
                        : "bg-muted text-muted-foreground hover:text-foreground"
                    }`}
                  >
                    {f === "all" ? "All" : (TYPE_LABELS[f] ?? f)}
                  </button>
                ))}
              </div>
            </CardHeader>
            <CardContent className="p-0">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">User</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Type</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Model</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground text-right">In</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground text-right">Out</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground text-right">Cost</TableHead>
                    <TableHead className="text-xs uppercase tracking-wide text-muted-foreground">Date</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {aiRecords
                    .filter((r) => aiTypeFilter === "all" || r.type === aiTypeFilter)
                    .length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={7} className="py-10 text-center text-muted-foreground">
                        No AI usage records found.
                      </TableCell>
                    </TableRow>
                  ) : (
                    aiRecords
                      .filter((r) => aiTypeFilter === "all" || r.type === aiTypeFilter)
                      .map((r) => {
                        const user = r.userId ? users[r.userId] : null;
                        return (
                          <TableRow key={r.id} className="hover:bg-muted/50">
                            <TableCell>
                              {user ? (
                                <Link href={`/dashboard/users/${r.userId}`} className="hover:underline">
                                  <p className="text-sm font-medium">{user.name || "—"}</p>
                                  <p className="text-xs text-muted-foreground">{user.email}</p>
                                </Link>
                              ) : r.userId ? (
                                <p className="text-xs font-mono text-muted-foreground">{r.userId.slice(0, 14)}…</p>
                              ) : (
                                <Badge variant="secondary" className="text-xs">System</Badge>
                              )}
                            </TableCell>
                            <TableCell>
                              <Badge variant="outline" className="text-xs">{TYPE_LABELS[r.type] ?? r.type}</Badge>
                            </TableCell>
                            <TableCell className="text-xs text-muted-foreground">{r.model}</TableCell>
                            <TableCell className="text-right text-xs">{r.inputTokens.toLocaleString()}</TableCell>
                            <TableCell className="text-right text-xs">{r.outputTokens.toLocaleString()}</TableCell>
                            <TableCell className="text-right text-xs font-mono">
                              {r.costUsd != null ? `$${r.costUsd.toFixed(5)}` : "—"}
                            </TableCell>
                            <TableCell className="text-xs text-muted-foreground">
                              {r.timestamp ? format(r.timestamp, "MMM d, HH:mm") : "—"}
                            </TableCell>
                          </TableRow>
                        );
                      })
                  )}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
