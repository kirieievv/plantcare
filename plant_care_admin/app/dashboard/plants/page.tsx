"use client";

import { useEffect, useState, useMemo } from "react";
import { fetchPlants, fetchUsers, type AdminPlant, type AdminUser } from "@/lib/firestore";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import {
  useReactTable,
  getCoreRowModel,
  getSortedRowModel,
  getFilteredRowModel,
  flexRender,
  createColumnHelper,
  type SortingState,
} from "@tanstack/react-table";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { format } from "date-fns";
import { ArrowUpDown, Search } from "lucide-react";
import Link from "next/link";

type PlantRow = AdminPlant & { userName?: string; userEmail?: string };

const col = createColumnHelper<PlantRow>();

function healthBadge(status?: string) {
  if (status === "ok") return <Badge className="bg-green-100 text-green-700 text-xs">OK</Badge>;
  if (status === "issue") return <Badge variant="destructive" className="text-xs">Issue</Badge>;
  return <Badge variant="outline" className="text-xs">—</Badge>;
}

function notifBadge(state?: string, muted?: boolean) {
  if (muted) return <Badge variant="secondary" className="text-xs">Muted</Badge>;
  if (state === "overdue") return <Badge variant="destructive" className="text-xs">Overdue</Badge>;
  if (state === "due") return <Badge className="bg-yellow-100 text-yellow-700 text-xs">Due</Badge>;
  return <Badge className="bg-green-100 text-green-700 text-xs">OK</Badge>;
}

export default function PlantsPage() {
  const [plants, setPlants] = useState<PlantRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [globalFilter, setGlobalFilter] = useState("");
  const [sorting, setSorting] = useState<SortingState>([]);

  useEffect(() => {
    Promise.all([fetchPlants(200), fetchUsers()]).then(([ps, us]) => {
      const userMap: Record<string, AdminUser> = {};
      us.forEach((u) => { userMap[u.uid] = u; });
      setPlants(
        ps.map((p) => ({
          ...p,
          userName: userMap[p.userId]?.name || "",
          userEmail: userMap[p.userId]?.email || "",
        }))
      );
    }).catch((e) => setError(e.message)).finally(() => setLoading(false));
  }, []);

  const columns = useMemo(
    () => [
      col.accessor("name", {
        header: "Plant",
        cell: (info) => (
          <div>
            <p className="font-medium">{info.getValue()}</p>
            <p className="text-xs text-muted-foreground">{info.row.original.species}</p>
          </div>
        ),
      }),
      col.accessor("userName", {
        header: "Owner",
        cell: (info) => (
          <Link
            href={`/dashboard/users/${info.row.original.userId}`}
            className="hover:underline text-sm"
          >
            <p>{info.getValue() || "—"}</p>
            <p className="text-xs text-muted-foreground">{info.row.original.userEmail}</p>
          </Link>
        ),
      }),
      col.accessor("healthStatus", {
        header: "Health",
        cell: (info) => healthBadge(info.getValue()),
      }),
      col.accessor("notificationState", {
        header: "Reminders",
        cell: (info) => notifBadge(info.getValue(), info.row.original.muted),
      }),
      col.accessor("nextDueAt", {
        header: ({ column }) => (
          <button className="flex items-center gap-1 hover:text-foreground" onClick={() => column.toggleSorting()}>
            Next watering <ArrowUpDown className="h-3 w-3" />
          </button>
        ),
        cell: (info) => {
          const d = info.getValue();
          if (!d) return "—";
          const overdue = d < new Date();
          return (
            <span className={overdue ? "text-destructive font-medium" : ""}>
              {format(d, "MMM d, HH:mm")}
            </span>
          );
        },
        sortingFn: "datetime",
      }),
      col.accessor("lastWateredAt", {
        header: "Last watered",
        cell: (info) => {
          const d = info.getValue();
          return d ? format(d, "MMM d, yyyy") : "—";
        },
        sortingFn: "datetime",
      }),
      col.accessor("createdAt", {
        header: "Added",
        cell: (info) => {
          const d = info.getValue();
          return d ? format(d, "MMM d, yyyy") : "—";
        },
        sortingFn: "datetime",
      }),
    ],
    []
  );

  const table = useReactTable({
    data: plants,
    columns,
    state: { globalFilter, sorting },
    onGlobalFilterChange: setGlobalFilter,
    onSortingChange: setSorting,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
  });

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Plants</h1>
        {!loading && (
          <span className="text-sm text-muted-foreground">{plants.length} loaded</span>
        )}
      </div>

      <Card>
        <CardHeader className="pb-3">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Search by name, species or owner…"
              value={globalFilter}
              onChange={(e) => setGlobalFilter(e.target.value)}
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
                {table.getHeaderGroups().map((hg) => (
                  <TableRow key={hg.id}>
                    {hg.headers.map((h) => (
                      <TableHead key={h.id} className="text-xs uppercase tracking-wide text-muted-foreground">
                        {h.isPlaceholder ? null : flexRender(h.column.columnDef.header, h.getContext())}
                      </TableHead>
                    ))}
                  </TableRow>
                ))}
              </TableHeader>
              <TableBody>
                {table.getRowModel().rows.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={columns.length} className="py-10 text-center text-muted-foreground">
                      No plants found.
                    </TableCell>
                  </TableRow>
                ) : (
                  table.getRowModel().rows.map((row) => (
                    <TableRow key={row.id} className="hover:bg-muted/50">
                      {row.getVisibleCells().map((cell) => (
                        <TableCell key={cell.id} className="py-3 text-sm">
                          {flexRender(cell.column.columnDef.cell, cell.getContext())}
                        </TableCell>
                      ))}
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
