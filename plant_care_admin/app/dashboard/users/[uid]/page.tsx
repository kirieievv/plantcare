"use client";

import { use, useEffect, useState } from "react";
import { fetchUserById, fetchPlantsByUser, type AdminUser, type AdminPlant } from "@/lib/firestore";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { ArrowLeft, Leaf, MapPin, Clock, Calendar } from "lucide-react";
import { format } from "date-fns";
import Link from "next/link";

function fmtDate(d?: Date) {
  if (!d) return "—";
  return format(d, "MMM d, yyyy HH:mm");
}

function healthBadge(status?: string) {
  if (status === "ok") return <Badge className="bg-green-100 text-green-700">OK</Badge>;
  if (status === "issue") return <Badge variant="destructive">Issue</Badge>;
  return <Badge variant="outline">—</Badge>;
}

function notifBadge(state?: string, muted?: boolean) {
  if (muted) return <Badge variant="secondary">Muted</Badge>;
  if (state === "overdue") return <Badge variant="destructive">Overdue</Badge>;
  if (state === "due") return <Badge className="bg-yellow-100 text-yellow-700">Due</Badge>;
  return <Badge className="bg-green-100 text-green-700">OK</Badge>;
}

export default function UserDetailPage({ params }: { params: Promise<{ uid: string }> }) {
  const { uid } = use(params);
  const [user, setUser] = useState<AdminUser | null>(null);
  const [plants, setPlants] = useState<AdminPlant[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    Promise.all([fetchUserById(uid), fetchPlantsByUser(uid)])
      .then(([u, p]) => {
        setUser(u);
        setPlants(p);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [uid]);

  if (loading) {
    return (
      <div className="flex h-full items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-green-600 border-t-transparent" />
      </div>
    );
  }

  if (error) return <p className="text-sm text-destructive">{error}</p>;
  if (!user) return <p className="text-sm text-muted-foreground">User not found.</p>;

  const initials = user.name
    .split(" ")
    .map((w) => w[0])
    .join("")
    .toUpperCase()
    .slice(0, 2) || user.email[0].toUpperCase();

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-3">
        <Link href="/dashboard/users">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
        <h1 className="text-2xl font-bold">User Details</h1>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-start gap-4">
              <Avatar className="h-14 w-14">
                <AvatarFallback className="bg-green-100 text-green-700 text-lg font-bold">
                  {initials}
                </AvatarFallback>
              </Avatar>
              <div className="space-y-1">
                <p className="text-xl font-semibold">{user.name || "—"}</p>
                <p className="text-sm text-muted-foreground">{user.email}</p>
                {user.bio && <p className="text-sm">{user.bio}</p>}
                <div className="flex flex-wrap gap-3 pt-1 text-xs text-muted-foreground">
                  {user.location && (
                    <span className="flex items-center gap-1">
                      <MapPin className="h-3 w-3" /> {user.location}
                    </span>
                  )}
                  {user.timezone && (
                    <span className="flex items-center gap-1">
                      <Clock className="h-3 w-3" /> {user.timezone}
                    </span>
                  )}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-sm font-medium text-muted-foreground">Activity</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            <div className="flex justify-between">
              <span className="text-muted-foreground flex items-center gap-1">
                <Calendar className="h-3 w-3" /> Registered
              </span>
              <span>{fmtDate(user.createdAt)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground flex items-center gap-1">
                <Clock className="h-3 w-3" /> Last login
              </span>
              <span>{fmtDate(user.lastLogin)}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground flex items-center gap-1">
                <Leaf className="h-3 w-3" /> Plants
              </span>
              <span className="font-semibold">{plants.length}</span>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Plants ({plants.length})</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {plants.length === 0 ? (
            <p className="p-4 text-sm text-muted-foreground">No plants yet.</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Name</TableHead>
                  <TableHead>Species</TableHead>
                  <TableHead>Health</TableHead>
                  <TableHead>Watering</TableHead>
                  <TableHead>Next due</TableHead>
                  <TableHead>Added</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {plants.map((p) => (
                  <TableRow key={p.id}>
                    <TableCell className="font-medium">{p.name}</TableCell>
                    <TableCell className="text-muted-foreground">{p.species}</TableCell>
                    <TableCell>{healthBadge(p.healthStatus)}</TableCell>
                    <TableCell>{notifBadge(p.notificationState, p.muted)}</TableCell>
                    <TableCell className="text-xs">
                      {p.nextDueAt ? format(p.nextDueAt, "MMM d, HH:mm") : "—"}
                    </TableCell>
                    <TableCell className="text-xs text-muted-foreground">
                      {p.createdAt ? format(p.createdAt, "MMM d, yyyy") : "—"}
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
