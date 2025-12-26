"use client";

import React, { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { generateFamilyToken } from "@/app/actions/family";
import { Loader2, Link as LinkIcon, Copy, Check } from "lucide-react";
import { ThaiButton } from "@/components/ui/thai-button";

export default function AdminCasesPage() {
    const [cases, setCases] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [generatingId, setGeneratingId] = useState<string | null>(null);
    const [copiedId, setCopiedId] = useState<string | null>(null);

    useEffect(() => {
        fetchCases();
    }, []);

    const fetchCases = async () => {
        setLoading(true);
        const { data, error } = await supabase
            .from("sos_cases")
            .select("*")
            .order("created_at", { ascending: false })
            .limit(50);

        if (data) setCases(data);
        setLoading(false);
    };

    const handleGenerateLink = async (caseId: string) => {
        setGeneratingId(caseId);
        const result = await generateFamilyToken(caseId);

        if (result.success && result.token) {
            // Update local state
            setCases(prev => prev.map(c => c.id === caseId ? { ...c, family_token: result.token } : c));

            // Copy to clipboard
            const url = `${window.location.origin}/case/${caseId}/family?token=${result.token}`;
            navigator.clipboard.writeText(url);
            setCopiedId(caseId);
            setTimeout(() => setCopiedId(null), 2000);
        } else {
            alert("Failed to generate token");
        }
        setGeneratingId(null);
    };

    const copyLink = (caseId: string, token: string) => {
        const url = `${window.location.origin}/case/${caseId}/family?token=${token}`;
        navigator.clipboard.writeText(url);
        setCopiedId(caseId);
        setTimeout(() => setCopiedId(null), 2000);
    };

    return (
        <div>
            <h1 className="text-2xl font-bold mb-6">จัดการเคส (Admin)</h1>

            <div className="bg-white rounded-lg shadow overflow-hidden">
                <div className="overflow-x-auto">
                    <table className="w-full text-sm text-left">
                        <thead className="bg-gray-50 text-gray-700 uppercase">
                            <tr>
                                <th className="px-6 py-3">Case ID</th>
                                <th className="px-6 py-3">ชื่อผู้แจ้ง</th>
                                <th className="px-6 py-3">สถานะ</th>
                                <th className="px-6 py-3">Family Link</th>
                            </tr>
                        </thead>
                        <tbody>
                            {loading ? (
                                <tr>
                                    <td colSpan={4} className="px-6 py-8 text-center">
                                        <Loader2 className="w-6 h-6 animate-spin mx-auto text-primary" />
                                    </td>
                                </tr>
                            ) : (
                                cases.map((c) => (
                                    <tr key={c.id} className="border-b hover:bg-gray-50">
                                        <td className="px-6 py-4 font-mono text-xs text-gray-500">
                                            {c.id.substring(0, 8)}...
                                        </td>
                                        <td className="px-6 py-4 font-medium">
                                            {c.reporter_name}
                                            <div className="text-xs text-gray-500 truncate max-w-[200px]">
                                                {c.address_text}
                                            </div>
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`px-2 py-1 rounded-full text-xs font-bold
                                                ${c.status === 'RESOLVED' ? 'bg-green-100 text-green-700' :
                                                    c.status === 'IN_PROGRESS' ? 'bg-blue-100 text-blue-700' :
                                                        'bg-red-100 text-red-700'}`}>
                                                {c.status}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4">
                                            {c.family_token ? (
                                                <div className="flex items-center gap-2">
                                                    <button
                                                        onClick={() => copyLink(c.id, c.family_token)}
                                                        className="flex items-center gap-1 text-blue-600 hover:text-blue-800 bg-blue-50 px-3 py-1.5 rounded-md transition-colors"
                                                    >
                                                        {copiedId === c.id ? (
                                                            <>
                                                                <Check className="w-4 h-4" />
                                                                <span>Copied</span>
                                                            </>
                                                        ) : (
                                                            <>
                                                                <Copy className="w-4 h-4" />
                                                                <span>Copy Link</span>
                                                            </>
                                                        )}
                                                    </button>
                                                </div>
                                            ) : (
                                                <ThaiButton
                                                    size="sm"
                                                    variant="outline"
                                                    onClick={() => handleGenerateLink(c.id)}
                                                    disabled={generatingId === c.id}
                                                >
                                                    {generatingId === c.id ? (
                                                        <Loader2 className="w-4 h-4 animate-spin" />
                                                    ) : (
                                                        <>
                                                            <LinkIcon className="w-4 h-4 mr-1" />
                                                            Generate Link
                                                        </>
                                                    )}
                                                </ThaiButton>
                                            )}
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}
