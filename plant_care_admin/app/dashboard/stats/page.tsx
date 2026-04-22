"use client";

import { useEffect, useState } from "react";
import { fetchStats, fetchNewUsersLast30Days, type StatsOverview } from "@/lib/firestore";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import {
  BarChart,
  Bar,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  Legend,
} from "recharts";
import { format, parseISO } from "date-fns";

export default function StatsPage() {
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

  if (error) return <p className="text-sm text-destructive">{error}</p>;

  const plantHealthData = [
    { name: "Healthy", value: (stats?.totalPlants ?? 0) - (stats?.plantsWithIssues ?? 0) - (stats?.mutedPlants ?? 0), color: "#16a34a" },
    { name: "Issues", value: stats?.plantsWithIssues ?? 0, color: "#dc2626" },
    { name: "Muted", value: stats?.mutedPlants ?? 0, color: "#9ca3af" },
  ].filter((d) => d.value > 0);

  const activityData = [
    { label: "Today", users: stats?.activeToday ?? 0, newUsers: stats?.newUsersToday ?? 0 },
    { label: "This week", users: stats?.activeThisWeek ?? 0, newUsers: stats?.newUsersThisWeek ?? 0 },
  ];

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Stats</h1>

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">New Users — Last 30 Days</CardTitle>
            <CardDescription>Daily registrations</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={220}>
              <AreaChart data={chartData}>
                <defs>
                  <linearGradient id="grad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#16a34a" stopOpacity={0.2} />
                    <stop offset="95%" stopColor="#16a34a" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                <XAxis
                  dataKey="date"
                  tick={{ fontSize: 10 }}
                  tickFormatter={(v) => format(parseISO(v), "MMM d")}
                  interval={9}
                />
                <YAxis tick={{ fontSize: 10 }} allowDecimals={false} />
                <Tooltip
                  labelFormatter={(v) => format(parseISO(v as string), "MMM d, yyyy")}
                  formatter={(v) => [v, "New users"]}
                />
                <Area type="monotone" dataKey="count" stroke="#16a34a" strokeWidth={2} fill="url(#grad)" />
              </AreaChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Plant Health Distribution</CardTitle>
            <CardDescription>Current health status across all plants</CardDescription>
          </CardHeader>
          <CardContent className="flex items-center justify-center">
            {plantHealthData.length === 0 ? (
              <p className="text-sm text-muted-foreground py-10">No plant data.</p>
            ) : (
              <ResponsiveContainer width="100%" height={220}>
                <PieChart>
                  <Pie
                    data={plantHealthData}
                    cx="50%"
                    cy="50%"
                    innerRadius={55}
                    outerRadius={85}
                    paddingAngle={3}
                    dataKey="value"
                    label={({ name, percent }) => `${name} ${((percent ?? 0) * 100).toFixed(0)}%`}
                    labelLine={false}
                  >
                    {plantHealthData.map((entry, index) => (
                      <Cell key={index} fill={entry.color} />
                    ))}
                  </Pie>
                  <Legend />
                  <Tooltip formatter={(v) => [v, "Plants"]} />
                </PieChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">User Activity</CardTitle>
            <CardDescription>Active users vs new registrations</CardDescription>
          </CardHeader>
          <CardContent>
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={activityData}>
                <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
                <XAxis dataKey="label" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 11 }} allowDecimals={false} />
                <Tooltip />
                <Legend />
                <Bar dataKey="users" name="Active users" fill="#16a34a" radius={[4, 4, 0, 0]} />
                <Bar dataKey="newUsers" name="New users" fill="#86efac" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="text-base">Summary</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            {[
              ["Total users", stats?.totalUsers],
              ["Total plants", stats?.totalPlants],
              ["Avg plants / user", stats && stats.totalUsers > 0 ? (stats.totalPlants / stats.totalUsers).toFixed(1) : "—"],
              ["New users today", stats?.newUsersToday],
              ["New users this week", stats?.newUsersThisWeek],
              ["Active today", stats?.activeToday],
              ["Active this week", stats?.activeThisWeek],
              ["Plants with issues", stats?.plantsWithIssues],
              ["Muted plants", stats?.mutedPlants],
            ].map(([label, value]) => (
              <div key={label as string} className="flex justify-between border-b pb-2 last:border-0">
                <span className="text-muted-foreground">{label}</span>
                <span className="font-semibold">{value ?? 0}</span>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
