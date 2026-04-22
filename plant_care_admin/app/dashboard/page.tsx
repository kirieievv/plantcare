"use client";

import { useEffect, useState } from "react";
import { fetchStats, fetchNewUsersLast30Days, type StatsOverview } from "@/lib/firestore";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import {
  Users,
  Leaf,
  UserPlus,
  Activity,
  AlertTriangle,
  BellOff,
  TrendingUp,
} from "lucide-react";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { format, parseISO } from "date-fns";

function StatCard({
  title,
  value,
  icon: Icon,
  description,
  highlight,
}: {
  title: string;
  value: number | string;
  icon: React.ElementType;
  description?: string;
  highlight?: boolean;
}) {
  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between pb-2">
        <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
        <Icon className={`h-4 w-4 ${highlight ? "text-green-600" : "text-muted-foreground"}`} />
      </CardHeader>
      <CardContent>
        <p className="text-3xl font-bold">{value}</p>
        {description && <p className="mt-1 text-xs text-muted-foreground">{description}</p>}
      </CardContent>
    </Card>
  );
}

export default function DashboardPage() {
  const [stats, setStats] = useState<StatsOverview | null>(null);
  const [chartData, setChartData] = useState<{ date: string; count: number }[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    Promise.all([fetchStats(), fetchNewUsersLast30Days()])
      .then(([s, chart]) => {
        setStats(s);
        setChartData(chart);
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return (
      <div className="flex h-full items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-green-600 border-t-transparent" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="rounded-md bg-destructive/10 p-4 text-sm text-destructive">
        Error loading stats: {error}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Overview</h1>
        <p className="text-sm text-muted-foreground">
          {format(new Date(), "EEEE, MMMM d, yyyy")}
        </p>
      </div>

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard title="Total Users" value={stats?.totalUsers ?? 0} icon={Users} highlight />
        <StatCard title="Total Plants" value={stats?.totalPlants ?? 0} icon={Leaf} highlight />
        <StatCard
          title="New Users Today"
          value={stats?.newUsersToday ?? 0}
          icon={UserPlus}
          description={`${stats?.newUsersThisWeek ?? 0} this week`}
        />
        <StatCard
          title="Active Today"
          value={stats?.activeToday ?? 0}
          icon={Activity}
          description={`${stats?.activeThisWeek ?? 0} this week`}
        />
        <StatCard
          title="Plants with Issues"
          value={stats?.plantsWithIssues ?? 0}
          icon={AlertTriangle}
        />
        <StatCard
          title="Muted Plants"
          value={stats?.mutedPlants ?? 0}
          icon={BellOff}
          description="No reminders"
        />
        <StatCard
          title="Avg Plants / User"
          value={
            stats && stats.totalUsers > 0
              ? (stats.totalPlants / stats.totalUsers).toFixed(1)
              : "—"
          }
          icon={TrendingUp}
        />
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">New Users — Last 30 Days</CardTitle>
          <CardDescription>Daily registrations</CardDescription>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={240}>
            <AreaChart data={chartData}>
              <defs>
                <linearGradient id="colorUsers" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#16a34a" stopOpacity={0.2} />
                  <stop offset="95%" stopColor="#16a34a" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
              <XAxis
                dataKey="date"
                tick={{ fontSize: 11 }}
                tickFormatter={(v) => format(parseISO(v), "MMM d")}
                interval={6}
              />
              <YAxis tick={{ fontSize: 11 }} allowDecimals={false} />
              <Tooltip
                labelFormatter={(v) => format(parseISO(v as string), "MMM d, yyyy")}
                formatter={(v) => [v, "New users"]}
              />
              <Area
                type="monotone"
                dataKey="count"
                stroke="#16a34a"
                strokeWidth={2}
                fill="url(#colorUsers)"
              />
            </AreaChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>
    </div>
  );
}
