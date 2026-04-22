"use client";

import React, { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { Loader2, Shield, CheckCircle, XCircle, Trash2, AlertTriangle } from "lucide-react";

interface Report {
    id: string;
    reporter_id: string;
    reported_user_id: string | null;
    entity_id: string;
    entity_type: string;
    reason: string;
    details: string | null;
    status: string;
    created_at: string;
}

export default function AdminModerationPage() {
    const [reports, setReports] = useState<Report[]>([]);
    const [loading, setLoading] = useState(true);
    const [actionLoading, setActionLoading] = useState<string | null>(null);
    const [statusFilter, setStatusFilter] = useState<string>("pending");

    useEffect(() => {
        fetchReports();
    }, []);

    const fetchReports = async () => {
        setLoading(true);
        const { data, error } = await supabase
            .from("reports")
            .select("*")
            .order("created_at", { ascending: false })
            .limit(100);

        if (data) setReports(data);
        if (error) console.error("Error fetching reports:", error);
        setLoading(false);
    };

    const updateReportStatus = async (reportId: string, newStatus: string) => {
        setActionLoading(reportId);
        const { error } = await supabase
            .from("reports")
            .update({ status: newStatus })
            .eq("id", reportId);

        if (error) {
            alert("Failed to update report: " + error.message);
        } else {
            setReports((prev) =>
                prev.map((r) => (r.id === reportId ? { ...r, status: newStatus } : r))
            );
        }
        setActionLoading(null);
    };

    const deleteReportedContent = async (report: Report) => {
        if (!confirm("Are you sure you want to delete the reported content and resolve this report?")) return;

        setActionLoading(report.id);

        try {
            if (report.entity_type === "pet" && report.entity_id) {
                await supabase.from("pets").delete().eq("id", report.entity_id);
            }
            if (report.entity_type === "feed_post" && report.entity_id) {
                await supabase.from("feed_posts").delete().eq("id", report.entity_id);
            }

            await supabase
                .from("reports")
                .update({ status: "resolved" })
                .eq("id", report.id);

            setReports((prev) =>
                prev.map((r) => (r.id === report.id ? { ...r, status: "resolved" } : r))
            );
        } catch (e) {
            alert("Failed to delete content: " + e);
        }

        setActionLoading(null);
    };

    const filteredReports = reports.filter((r) => {
        if (statusFilter === "all") return true;
        return r.status === statusFilter;
    });

    const getStatusBadge = (status: string) => {
        switch (status) {
            case "pending":
                return (
                    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                        <AlertTriangle className="w-3 h-3" />
                        Pending
                    </span>
                );
            case "resolved":
                return (
                    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        <CheckCircle className="w-3 h-3" />
                        Resolved
                    </span>
                );
            case "dismissed":
                return (
                    <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-600">
                        <XCircle className="w-3 h-3" />
                        Dismissed
                    </span>
                );
            default:
                return <span className="text-xs text-gray-500">{status}</span>;
        }
    };

    const formatDate = (dateStr: string) => {
        const d = new Date(dateStr);
        return d.toLocaleDateString("th-TH", {
            year: "numeric",
            month: "short",
            day: "numeric",
            hour: "2-digit",
            minute: "2-digit",
        });
    };

    return (
        <div>
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
                <div className="flex items-center gap-3">
                    <Shield className="w-7 h-7 text-red-500" />
                    <h1 className="text-2xl font-bold text-gray-800">
                        Content Moderation
                    </h1>
                </div>

                <div className="flex gap-2">
                    {["pending", "resolved", "dismissed", "all"].map((status) => (
                        <button
                            key={status}
                            onClick={() => setStatusFilter(status)}
                            className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                                statusFilter === status
                                    ? "bg-blue-600 text-white"
                                    : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                            }`}
                        >
                            {status.charAt(0).toUpperCase() + status.slice(1)}
                        </button>
                    ))}
                </div>
            </div>

            {loading ? (
                <div className="flex justify-center py-20">
                    <Loader2 className="w-8 h-8 animate-spin text-blue-500" />
                </div>
            ) : filteredReports.length === 0 ? (
                <div className="text-center py-20 text-gray-500">
                    <Shield className="w-16 h-16 mx-auto mb-4 text-gray-300" />
                    <p className="text-lg font-medium">No {statusFilter} reports</p>
                    <p className="text-sm mt-1">All clear for now.</p>
                </div>
            ) : (
                <div className="space-y-4">
                    {filteredReports.map((report) => (
                        <div
                            key={report.id}
                            className="bg-white rounded-xl border border-gray-200 p-5 shadow-sm"
                        >
                            <div className="flex flex-col md:flex-row md:items-start justify-between gap-4">
                                <div className="flex-1">
                                    <div className="flex items-center gap-3 mb-2">
                                        {getStatusBadge(report.status)}
                                        <span className="text-xs text-gray-400">
                                            {formatDate(report.created_at)}
                                        </span>
                                        <span className="text-xs bg-blue-50 text-blue-600 px-2 py-0.5 rounded">
                                            {report.entity_type}
                                        </span>
                                    </div>

                                    <p className="font-semibold text-gray-800 mb-1">
                                        Reason: {report.reason}
                                    </p>

                                    {report.details && (
                                        <p className="text-sm text-gray-600 mb-2">
                                            Details: {report.details}
                                        </p>
                                    )}

                                    <div className="flex flex-wrap gap-x-6 gap-y-1 text-xs text-gray-400 mt-2">
                                        <span>Reporter: {report.reporter_id?.slice(0, 8)}...</span>
                                        {report.reported_user_id && (
                                            <span>
                                                Reported User: {report.reported_user_id.slice(0, 8)}...
                                            </span>
                                        )}
                                        <span>Entity: {report.entity_id?.slice(0, 8)}...</span>
                                    </div>
                                </div>

                                {report.status === "pending" && (
                                    <div className="flex gap-2 shrink-0">
                                        <button
                                            onClick={() => updateReportStatus(report.id, "dismissed")}
                                            disabled={actionLoading === report.id}
                                            className="flex items-center gap-1 px-3 py-2 rounded-lg text-sm font-medium bg-gray-100 text-gray-600 hover:bg-gray-200 disabled:opacity-50"
                                        >
                                            <XCircle className="w-4 h-4" />
                                            Dismiss
                                        </button>

                                        <button
                                            onClick={() => deleteReportedContent(report)}
                                            disabled={actionLoading === report.id}
                                            className="flex items-center gap-1 px-3 py-2 rounded-lg text-sm font-medium bg-red-100 text-red-700 hover:bg-red-200 disabled:opacity-50"
                                        >
                                            {actionLoading === report.id ? (
                                                <Loader2 className="w-4 h-4 animate-spin" />
                                            ) : (
                                                <Trash2 className="w-4 h-4" />
                                            )}
                                            Remove Content
                                        </button>

                                        <button
                                            onClick={() => updateReportStatus(report.id, "resolved")}
                                            disabled={actionLoading === report.id}
                                            className="flex items-center gap-1 px-3 py-2 rounded-lg text-sm font-medium bg-green-100 text-green-700 hover:bg-green-200 disabled:opacity-50"
                                        >
                                            <CheckCircle className="w-4 h-4" />
                                            Resolve
                                        </button>
                                    </div>
                                )}
                            </div>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}
