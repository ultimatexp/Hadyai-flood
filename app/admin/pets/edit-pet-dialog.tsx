"use client";

import { useEffect, useState } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { ThaiButton } from "@/components/ui/thai-button";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Loader2 } from "lucide-react";
import { supabase } from "@/lib/supabase";

interface EditPetDialogProps {
    open: boolean;
    onOpenChange: (open: boolean) => void;
    pet: any;
    onSuccess: (updatedPet: any) => void;
}

export function EditPetDialog({ open, onOpenChange, pet, onSuccess }: EditPetDialogProps) {
    const [formData, setFormData] = useState<any>({});
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        if (pet) {
            setFormData({
                status: pet.status || 'LOST',
                species: pet.species || '',
                sex: pet.sex || 'unknown',
                description: pet.description || '',
                contact_info: pet.contact_info || '',
                color_main: pet.color_main || '',
            });
        }
    }, [pet]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);

        try {
            const { data, error } = await supabase
                .from('pets')
                .update(formData)
                .eq('id', pet.id)
                .select()
                .single();

            if (error) throw error;

            onSuccess(data);
            onOpenChange(false);
        } catch (error: any) {
            alert("Error updating pet: " + error.message);
        } finally {
            setLoading(false);
        }
    };

    if (!pet) return null;

    return (
        <Dialog open={open} onOpenChange={onOpenChange}>
            <DialogContent className="max-w-md">
                <DialogHeader>
                    <DialogTitle>Edit Pet Details</DialogTitle>
                </DialogHeader>

                <form onSubmit={handleSubmit} className="space-y-4">
                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <Label>Status</Label>
                            <select
                                value={formData.status}
                                onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                                className="w-full px-3 py-2 border border-input rounded-md bg-background text-sm"
                            >
                                <option value="LOST">Lost</option>
                                <option value="FOUND">Found</option>
                            </select>
                        </div>

                        <div className="space-y-2">
                            <Label>Sex</Label>
                            <select
                                value={formData.sex}
                                onChange={(e) => setFormData({ ...formData, sex: e.target.value })}
                                className="w-full px-3 py-2 border border-input rounded-md bg-background text-sm"
                            >
                                <option value="unknown">Unknown</option>
                                <option value="male">Male</option>
                                <option value="female">Female</option>
                            </select>
                        </div>
                    </div>

                    <div className="space-y-2">
                        <Label>Species</Label>
                        <Input
                            value={formData.species}
                            onChange={(e) => setFormData({ ...formData, species: e.target.value })}
                            placeholder="e.g. Dog, Cat"
                        />
                    </div>

                    <div className="space-y-2">
                        <Label>Color (Main)</Label>
                        <Input
                            value={formData.color_main}
                            onChange={(e) => setFormData({ ...formData, color_main: e.target.value })}
                            placeholder="e.g. Brown, White"
                        />
                    </div>

                    <div className="space-y-2">
                        <Label>Description</Label>
                        <Textarea
                            value={formData.description}
                            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                            rows={3}
                            placeholder="Pet description..."
                        />
                    </div>

                    <div className="space-y-2">
                        <Label>Contact Info</Label>
                        <Input
                            value={formData.contact_info}
                            onChange={(e) => setFormData({ ...formData, contact_info: e.target.value })}
                            placeholder="Phone, Line ID, etc."
                        />
                    </div>

                    <div className="flex justify-end gap-2 pt-4">
                        <ThaiButton type="button" variant="outline" onClick={() => onOpenChange(false)}>
                            Cancel
                        </ThaiButton>
                        <ThaiButton type="submit" disabled={loading}>
                            {loading ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Save Changes'}
                        </ThaiButton>
                    </div>
                </form>
            </DialogContent>
        </Dialog>
    );
}
