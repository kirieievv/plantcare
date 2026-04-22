"use client";

import { useEffect, useState } from "react";
import { fetchMailLogs, type MailLog } from "@/lib/firestore";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { format } from "date-fns";
import { Search, Mail, CheckCircle2, XCircle, Clock } from "lucide-react";

function deliveryBadge(state?: string) {
  if (!state) return <Badge variant="secondary" className="text-xs gap-1"><Clock className="h-3 w-3" />Pending</Badge>;
  if (state === "SUCCESS") return <Badge className="bg-green-100 text-green-700 text-xs gap-1"><CheckCircle2 className="h-3 w-3" />Sent</Badge>;
  if (state === "ERROR") return <Badge variant="destructive" className="text-xs gap-1"><XCircle className="h-3 w-3" />Error</Badge>;
  return <Badge variant="outline" className="text-xs">{state}</Badge>;
}

export default function LogsPage() {
  const [logs, setLogs] = useState<MailLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [search, setSearch] = useState("");

  useEffect(() => {
    fetchMailLogs(100)
      .then(setLogs)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  const filtered = logs.filter((l) => {
    const q = search.toLowerCase();
    return (
      l.to.toLowerCase().includes(q) ||
      (l.subject || "").toLowerCase().includes(q) ||
      (l.delivery?.state || "").toLowerCase().includes(q)
    );
  });

  const errorCount = logs.filter((l) => l.delivery?.state === "ERROR").length;
  const sentCount = logs.filter((l) => l.delivery?.state === "SUCCESS").length;

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Logs</h1>
        {!loading && (
          <div className="flex gap-3 text-sm text-muted-foreground">
            <span className="flex items-center gap-1 text-green-600">
              <CheckCircle2 className="h-4 w-4" /> {sentCount} sent
            </span>
            <span className="flex items-center gap-1 text-destructive">
              <XCircle className="h-4 w-4" /> {errorCount} errors
            </span>
          </div>
        )}
      </div>

      <div className="grid grid-cols-3 gap-4">
        <Card>
          <CardContent className="pt-4 pb-4 flex items-center gap-3">
            <div className="h-10 w-10 rounded-lg bg-blue-100 flex items-center justify-center">
              <Mail className="h-5 w-5 text-blue-600" />
            </div>
            <div>
              <p className="text-2xl font-bold">{logs.length}</p>
              <p className="text-xs text-muted-foreground">Total emails</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-4 flex items-center gap-3">
            <div className="h-10 w-10 rounded-lg bg-green-100 flex items-center justify-center">
              <CheckCircle2 className="h-5 w-5 text-green-600" />
            </div>
            <div>
              <p className="text-2xl font-bold">{sentCount}</p>
              <p className="text-xs text-muted-foreground">Delivered</p>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-4 flex items-center gap-3">
            <div className="h-10 w-10 rounded-lg bg-red-100 flex items-center justify-center">
              <XCircle className="h-5 w-5 text-red-600" />
            </div>
            <div>
              <p className="text-2xl font-bold">{errorCount}</p>
              <p className="text-xs text-muted-foreground">Failed</p>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="pb-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Search by recipient or subject…"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="pl-9"
            />
          </div>
        </CardHeader>
        <CardContent className="p-0">
          {loading ? (
            <div className="flex items-center justify-center py-16">
              <div className="h-6 w-6 animate-spin rounded-full border-4 border-green-600 border-t-transparent" />
            </div>
          ) : error ? (
            <p className="p-4 text-sm text-destructive">{error}</p>
          ) : (
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
                {filtered.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={5} className="py-10 text-center text-muted-foreground">
                      No logs found.
                    </TableCell>
                  </TableRow>
                ) : (
                  filtered.map((log) => (
                    <TableRow key={log.id} className="hover:bg-muted/50">
                      <TableCell className="text-sm">{log.to}</TableCell>
                      <TableCell className="text-sm max-w-xs truncate">{log.subject || "—"}</TableCell>
                      <TableCell>{deliveryBadge(log.delivery?.state)}</TableCell>
                      <TableCell className="text-sm text-muted-foreground">
                        {log.delivery?.attempts ?? "—"}
                      </TableCell>
                      <TableCell className="text-xs text-muted-foreground">
                        {log.createdAt ? format(log.createdAt, "MMM d, HH:mm") : "—"}
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
