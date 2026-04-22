"use client";

import React, { useEffect, useMemo, useState } from "react";
import { supabase } from "@/lib/supabase";
import { Loader2, Search, Trash2 } from "lucide-react";
import { ThaiButton } from "@/components/ui/thai-button";

type FeedPost = {
    id: string;
    post_type: string | null;
    title: string | null;
    body: string | null;
    image_url: string | null;
    entity_type: string | null;
    entity_id: string | null;
    user_id: string | null;
    created_at: string;
};

export default function AdminFeedsPage() {
    const [posts, setPosts] = useState<FeedPost[]>([]);
    const [loading, setLoading] = useState(true);
    const [deletingId, setDeletingId] = useState<string | null>(null);
    const [searchTerm, setSearchTerm] = useState("");
    const [typeFilter, setTypeFilter] = useState<string>("all");

    useEffect(() => {
        fetchFeedPosts();
    }, []);

    const fetchFeedPosts = async () => {
        setLoading(true);
        const { data, error } = await supabase
            .from("feed_posts")
            .select("*")
            .order("created_at", { ascending: false })
            .limit(100);

        if (data) setPosts(data as FeedPost[]);
        if (error) console.error("Error fetching feed posts:", error);
        setLoading(false);
    };

    const handleDelete = async (id: string) => {
        if (!confirm("Delete this feed post? This action cannot be undone.")) return;

        setDeletingId(id);
        const { error } = await supabase.from("feed_posts").delete().eq("id", id);

        if (error) {
            alert("Failed to delete post: " + error.message);
        } else {
            setPosts((prev) => prev.filter((post) => post.id !== id));
        }
        setDeletingId(null);
    };

    const filteredPosts = useMemo(() => {
        const q = searchTerm.toLowerCase();
        return posts.filter((post) => {
            const matchesSearch =
                (post.title?.toLowerCase() || "").includes(q) ||
                (post.body?.toLowerCase() || "").includes(q) ||
                (post.entity_type?.toLowerCase() || "").includes(q);

            const matchesType = typeFilter === "all" || post.post_type === typeFilter;
            return matchesSearch && matchesType;
        });
    }, [posts, searchTerm, typeFilter]);

    const postTypes = useMemo(() => {
        const unique = new Set(posts.map((p) => p.post_type).filter(Boolean));
        return Array.from(unique) as string[];
    }, [posts]);

    return (
        <div>
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
                <h1 className="text-2xl font-bold text-gray-800">Manage Feed Posts</h1>

                <div className="flex gap-2">
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                        <input
                            type="text"
                            placeholder="Search title/body/entity..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="pl-9 pr-4 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 w-full md:w-72"
                        />
                    </div>
                    <select
                        value={typeFilter}
                        onChange={(e) => setTypeFilter(e.target.value)}
                        className="px-4 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
                    >
                        <option value="all">All types</option>
                        {postTypes.map((type) => (
                            <option key={type} value={type}>
                                {type}
                            </option>
                        ))}
                    </select>
                </div>
            </div>

            <div className="bg-white rounded-lg shadow overflow-hidden">
                <div className="overflow-x-auto">
                    <table className="w-full text-sm text-left">
                        <thead className="bg-gray-50 text-gray-700 uppercase">
                            <tr>
                                <th className="px-6 py-3">Type</th>
                                <th className="px-6 py-3">Content</th>
                                <th className="px-6 py-3">Entity</th>
                                <th className="px-6 py-3">Author</th>
                                <th className="px-6 py-3">Date</th>
                                <th className="px-6 py-3 text-right">Actions</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-gray-100">
                            {loading ? (
                                <tr>
                                    <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                                        <div className="flex flex-col items-center gap-2">
                                            <Loader2 className="w-8 h-8 animate-spin text-blue-500" />
                                            <p>Loading feed posts...</p>
                                        </div>
                                    </td>
                                </tr>
                            ) : filteredPosts.length === 0 ? (
                                <tr>
                                    <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                                        No posts found matching your criteria.
                                    </td>
                                </tr>
                            ) : (
                                filteredPosts.map((post) => (
                                    <tr key={post.id} className="hover:bg-gray-50 transition-colors">
                                        <td className="px-6 py-4">
                                            <span className="px-2.5 py-1 rounded-full text-xs font-bold inline-block bg-blue-50 text-blue-700 border border-blue-200">
                                                {post.post_type || "unknown"}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4">
                                            <div className="max-w-[320px]">
                                                <div className="font-medium text-gray-900 mb-1 line-clamp-1">
                                                    {post.title || "(No title)"}
                                                </div>
                                                <div className="text-xs text-gray-500 line-clamp-2">
                                                    {post.body || "No body"}
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 text-xs text-gray-600">
                                            <div>{post.entity_type || "-"}</div>
                                            <div className="font-mono text-gray-400">
                                                {post.entity_id ? `${post.entity_id.slice(0, 8)}...` : "-"}
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 text-xs text-gray-600 font-mono">
                                            {post.user_id ? `${post.user_id.slice(0, 8)}...` : "-"}
                                        </td>
                                        <td className="px-6 py-4 text-gray-500 text-xs whitespace-nowrap">
                                            {new Date(post.created_at).toLocaleDateString("th-TH", {
                                                year: "numeric",
                                                month: "short",
                                                day: "numeric",
                                                hour: "2-digit",
                                                minute: "2-digit",
                                            })}
                                        </td>
                                        <td className="px-6 py-4 text-right">
                                            <ThaiButton
                                                size="sm"
                                                variant="danger"
                                                onClick={() => handleDelete(post.id)}
                                                disabled={deletingId === post.id}
                                                className="bg-red-50 text-red-600 hover:bg-red-100 border-red-200 shadow-none"
                                            >
                                                {deletingId === post.id ? (
                                                    <Loader2 className="w-4 h-4 animate-spin" />
                                                ) : (
                                                    <Trash2 className="w-4 h-4" />
                                                )}
                                            </ThaiButton>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            <div className="mt-4 text-center text-xs text-gray-400">
                Showing {filteredPosts.length} of {posts.length} total entries
            </div>
        </div>
    );
}
