"use client";

import React, { useEffect, useState } from "react";
import { supabase } from "@/lib/supabase";
import { Loader2, Trash2, Search, Filter, Pencil } from "lucide-react";
import { ThaiButton } from "@/components/ui/thai-button";
import { EditPetDialog } from "./edit-pet-dialog";

export default function AdminPetsPage() {
    const [pets, setPets] = useState<any[]>([]);
    const [loading, setLoading] = useState(true);
    const [deletingId, setDeletingId] = useState<string | null>(null);
    const [searchTerm, setSearchTerm] = useState("");
    const [statusFilter, setStatusFilter] = useState<string>("all");
    const [editingPet, setEditingPet] = useState<any>(null);

    useEffect(() => {
        fetchPets();
    }, []);

    const fetchPets = async () => {
        setLoading(true);
        const { data, error } = await supabase
            .from("pets")
            .select("*")
            .order("created_at", { ascending: false })
            .limit(100); // Limit to 100 for now

        if (data) setPets(data);
        if (error) console.error("Error fetching pets:", error);
        setLoading(false);
    };

    const handleUpdateSuccess = (updatedPet: any) => {
        setPets(prev => prev.map(p => p.id === updatedPet.id ? updatedPet : p));
    };

    const handleDelete = async (id: string) => {
        if (!confirm("Are you sure you want to delete this pet? This action cannot be undone.")) return;

        setDeletingId(id);
        const { error } = await supabase
            .from("pets")
            .delete()
            .eq("id", id);

        if (error) {
            alert("Failed to delete pet: " + error.message);
        } else {
            setPets(prev => prev.filter(p => p.id !== id));
        }
        setDeletingId(null);
    };

    const filteredPets = pets.filter(pet => {
        const matchesSearch =
            (pet.description?.toLowerCase() || "").includes(searchTerm.toLowerCase()) ||
            (pet.contact_info?.toLowerCase() || "").includes(searchTerm.toLowerCase()) ||
            (pet.species?.toLowerCase() || "").includes(searchTerm.toLowerCase());

        const matchesStatus = statusFilter === "all" || pet.status === statusFilter;

        return matchesSearch && matchesStatus;
    });

    return (
        <div>
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
                <h1 className="text-2xl font-bold text-gray-800">จัดการข้อมูลสัตว์เลี้ยง (Pets)</h1>

                <div className="flex gap-2">
                    <div className="relative">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                        <input
                            type="text"
                            placeholder="ค้นหา..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="pl-9 pr-4 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 w-full md:w-64"
                        />
                    </div>
                    <select
                        value={statusFilter}
                        onChange={(e) => setStatusFilter(e.target.value)}
                        className="px-4 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 bg-white"
                    >
                        <option value="all">สถานะทั้งหมด</option>
                        <option value="FOUND">เจอแล้ว (Found)</option>
                        <option value="LOST">หาย (Lost)</option>
                    </select>
                </div>
            </div>

            <div className="bg-white rounded-lg shadow overflow-hidden">
                <div className="overflow-x-auto">
                    <table className="w-full text-sm text-left">
                        <thead className="bg-gray-50 text-gray-700 uppercase">
                            <tr>
                                <th className="px-6 py-3">Image</th>
                                <th className="px-6 py-3">Status</th>
                                <th className="px-6 py-3">Info</th>
                                <th className="px-6 py-3">Contact</th>
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
                                            <p>Loading pets...</p>
                                        </div>
                                    </td>
                                </tr>
                            ) : filteredPets.length === 0 ? (
                                <tr>
                                    <td colSpan={6} className="px-6 py-12 text-center text-gray-500">
                                        No pets found matching your criteria.
                                    </td>
                                </tr>
                            ) : (
                                filteredPets.map((pet) => (
                                    <tr key={pet.id} className="hover:bg-gray-50 transition-colors">
                                        <td className="px-6 py-4">
                                            <div className="w-16 h-16 rounded-lg overflow-hidden bg-gray-100 border border-gray-200">
                                                {pet.image_url ? (
                                                    <img src={pet.image_url} alt="Pet" className="w-full h-full object-cover" />
                                                ) : (
                                                    <div className="w-full h-full flex items-center justify-center text-gray-400 text-xs">No Img</div>
                                                )}
                                            </div>
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`px-2.5 py-1 rounded-full text-xs font-bold inline-block
                                                ${pet.status === 'FOUND'
                                                    ? 'bg-green-100 text-green-700 border border-green-200'
                                                    : 'bg-red-100 text-red-700 border border-red-200'}`}>
                                                {pet.status === 'FOUND' ? 'เจอแล้ว' : 'หาย'}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4">
                                            <div className="max-w-[200px]">
                                                <div className="font-medium text-gray-900 mb-1 truncate">
                                                    {pet.species || 'Unknown'} {pet.sex ? `(${pet.sex})` : ''}
                                                </div>
                                                <div className="text-xs text-gray-500 line-clamp-2">
                                                    {pet.description || "No description"}
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4">
                                            <div className="text-sm text-gray-600 max-w-[150px] truncate" title={pet.contact_info}>
                                                {pet.contact_info || "-"}
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 text-gray-500 text-xs whitespace-nowrap">
                                            {new Date(pet.created_at).toLocaleDateString('th-TH', {
                                                year: 'numeric',
                                                month: 'short',
                                                day: 'numeric',
                                                hour: '2-digit',
                                                minute: '2-digit'
                                            })}
                                        </td>
                                        <td className="px-6 py-4 text-right">
                                            <div className="flex justify-end gap-2">
                                                <ThaiButton
                                                    size="sm"
                                                    variant="outline"
                                                    onClick={() => setEditingPet(pet)}
                                                    className="bg-blue-50 text-blue-600 hover:bg-blue-100 border-blue-200 shadow-none"
                                                >
                                                    <Pencil className="w-4 h-4" />
                                                </ThaiButton>
                                                <ThaiButton
                                                    size="sm"
                                                    variant="danger"
                                                    onClick={() => handleDelete(pet.id)}
                                                    disabled={deletingId === pet.id}
                                                    className="bg-red-50 text-red-600 hover:bg-red-100 border-red-200 shadow-none"
                                                >
                                                    {deletingId === pet.id ? (
                                                        <Loader2 className="w-4 h-4 animate-spin" />
                                                    ) : (
                                                        <Trash2 className="w-4 h-4" />
                                                    )}
                                                </ThaiButton>
                                            </div>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>

            <div className="mt-4 text-center text-xs text-gray-400">
                Showing {filteredPets.length} of {pets.length} total entries
            </div>

            <EditPetDialog
                open={!!editingPet}
                onOpenChange={(open) => !open && setEditingPet(null)}
                pet={editingPet}
                onSuccess={handleUpdateSuccess}
            />
        </div>
    );
}
