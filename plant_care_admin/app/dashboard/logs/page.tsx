"use client";

import { useEffect, useState } from "react";
import { fetchMailLogs, fetchFcmTokens, fetchUsers, type MailLog, type FcmToken, type AdminUser } from "@/lib/firestore";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { format } from "date-fns";
import { Search, Mail, CheckCircle2, XCircle, Clock, Smartphone, Users } from "lucide-react";
import Link from "next/link";

function deliveryBadge(state?: string) {
  if (!state) return <Badge variant="secondary" className="text-xs gap-1"><Clock className="h-3 w-3" />Pending</Badge>;
  if (state === "SUCCESS") return <Badge className="bg-green-100 text-green-700 text-xs gap-1"><CheckCircle2 className="h-3 w-3" />Sent</Badge>;
  if (state === "ERROR") return <Badge variant="destructive" className="text-xs gap-1"><XCircle className="h-3 w-3" />Error</Badge>;
  return <Badge variant="outline" className="text-xs">{state}</Badge>;
}

function StatCard({ icon: Icon, value, label, color }: { icon: React.ElementType; value: number; label: string; color: string }) {
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
  const [loading, setLoading] = useState(true);
  const [emailSearch, setEmailSearch] = useState("");
  const [pushSearch, setPushSearch] = useState("");
  const [emailFilter, setEmailFilter] = useState<"all" | "sent" | "error" | "pending">("all");

  useEffect(() => {
    Promise.all([fetchMailLogs(200), fetchFcmTokens(), fetchUsers()])
      .then(([l, t, u]) => {
        setLogs(l);
        setTokens(t);
        const map: Record<string, AdminUser> = {};
        u.forEach((user) => { map[user.uid] = user; });
        setUsers(map);
      })
      .finally(() => setLoading(false));
  }, []);

  const errorCount = logs.filter((l) => l.delivery?.state === "ERROR").length;
  const sentCount = logs.filter((l) => l.delivery?.state === "SUCCESS").length;
  const pendingCount = logs.filter((l) => !l.delivery?.state).length;

  const usersWithTokens = new Set(tokens.map((t) => t.userId)).size;

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
      </Tabs>
    </div>
  );
}
