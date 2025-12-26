"use client";

import { useState } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogDescription } from "@/components/ui/dialog";
import { ThaiButton } from "@/components/ui/thai-button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { analyzeHeroSource, createHero } from "@/app/actions/hero";
import { Loader2, Plus, Sparkles, Upload } from "lucide-react";
import Image from "next/image";

export function AddHeroDialog() {
    const [open, setOpen] = useState(false);
    const [loading, setLoading] = useState(false);
    const [analyzing, setAnalyzing] = useState(false);

    // Form State
    const [name, setName] = useState("");
    const [rank, setRank] = useState("");
    const [biography, setBiography] = useState("");
    const [imageUrl, setImageUrl] = useState("");
    const [socialLink, setSocialLink] = useState("");

    // Analysis State
    const [previewImage, setPreviewImage] = useState<string | null>(null);
    const [analysisFile, setAnalysisFile] = useState<File | null>(null);
    const [analysisText, setAnalysisText] = useState("");

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            setAnalysisFile(file);
            const reader = new FileReader();
            reader.onload = (e) => setPreviewImage(e.target?.result as string);
            reader.readAsDataURL(file);
        }
    };

    const handleAnalyze = async () => {
        if (!analysisFile && !analysisText) return;

        setAnalyzing(true);
        const formData = new FormData();
        if (analysisFile) formData.append("image", analysisFile);
        if (analysisText) formData.append("text", analysisText);

        const result = await analyzeHeroSource(formData);
        setAnalyzing(false);

        if (result.success && result.data) {
            const { name, rank, biography, social_link } = result.data;
            if (name) setName(name);
            if (rank) setRank(rank);
            if (biography) setBiography(biography);
            if (social_link) setSocialLink(social_link);
            // Determine if we can use the uploaded image as the hero image (in a real app we'd upload it)
            // For now, prompt user to provide a URL or keep the field empty
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);

        const res = await createHero({
            name,
            rank,
            biography,
            image_url: imageUrl,
            social_link: socialLink,
        });

        setLoading(false);
        if (res.success) {
            setOpen(false);
            // Reset form
            setName("");
            setRank("");
            setBiography("");
            setImageUrl("");
            setSocialLink("");
            setPreviewImage(null);
            setAnalysisFile(null);
            setAnalysisText("");
        }
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            <DialogTrigger asChild>
                <ThaiButton variant="primary" className="gap-2 shadow-amber-500/50">
                    <Plus size={20} />
                    Add Hero (เพิ่มฮีโร่)
                </ThaiButton>
            </DialogTrigger>
            <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-[600px] bg-zinc-950 border-amber-500/30 text-zinc-100">
                <DialogHeader>
                    <DialogTitle className="text-2xl font-serif text-amber-500">Add New Hero</DialogTitle>
                    <DialogDescription className="text-zinc-400">
                        Honor a Thai soldier by adding their story. You can use AI to extract info from social media posts.
                    </DialogDescription>
                </DialogHeader>

                <div className="space-y-6 py-4">
                    {/* AI Extraction Section */}
                    <div className="bg-zinc-900/50 p-4 rounded-lg border border-zinc-800 space-y-4">
                        <h3 className="text-sm font-semibold flex items-center text-indigo-400">
                            <Sparkles size={16} className="mr-2" />
                            AI Auto-Fill (Optional)
                        </h3>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <Label>Upload Screenshot</Label>
                                <div className="border-2 border-dashed border-zinc-700 rounded-md p-4 flex flex-col items-center justify-center cursor-pointer hover:border-zinc-500 transition-colors relative h-32">
                                    <input
                                        type="file"
                                        accept="image/*"
                                        className="absolute inset-0 opacity-0 cursor-pointer"
                                        onChange={handleFileChange}
                                    />
                                    {previewImage ? (
                                        <Image src={previewImage} alt="Preview" fill className="object-contain p-2" />
                                    ) : (
                                        <div className="text-center text-zinc-500 text-sm">
                                            <Upload size={24} className="mx-auto mb-2" />
                                            <span>Click to upload</span>
                                        </div>
                                    )}
                                </div>
                            </div>

                            <div className="space-y-2">
                                <Label>Or Paste Text / URL</Label>
                                <Textarea
                                    placeholder="Paste the story or social post text here..."
                                    className="h-32 bg-zinc-800 border-zinc-700 text-sm"
                                    value={analysisText}
                                    onChange={(e) => setAnalysisText(e.target.value)}
                                />
                            </div>
                        </div>

                        <ThaiButton
                            type="button"
                            onClick={handleAnalyze}
                            disabled={analyzing || (!analysisFile && !analysisText)}
                            className="w-full bg-indigo-600 hover:bg-indigo-700 text-white"
                        >
                            {analyzing ? <><Loader2 className="animate-spin mr-2" /> Analyzing...</> : <><Sparkles className="mr-2" /> Extract Info</>}
                        </ThaiButton>
                    </div>

                    <div className="h-px bg-zinc-800" />

                    {/* Manual Entry Form */}
                    <form onSubmit={handleSubmit} className="space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                            <div className="space-y-2">
                                <Label>Name (ชื่อ)</Label>
                                <Input required value={name} onChange={e => setName(e.target.value)} className="bg-zinc-900 border-zinc-700" placeholder="e.g. Sgt. Maj. Somchai" />
                            </div>
                            <div className="space-y-2">
                                <Label>Rank (ยศ - Optional)</Label>
                                <Input value={rank} onChange={e => setRank(e.target.value)} className="bg-zinc-900 border-zinc-700" placeholder="e.g. General" />
                            </div>
                        </div>

                        <div className="space-y-2">
                            <Label>Biography (ชีวประวัติ)</Label>
                            <Textarea required value={biography} onChange={e => setBiography(e.target.value)} className="bg-zinc-900 border-zinc-700 min-h-[100px]" placeholder="Tell their story..." />
                        </div>

                        <div className="space-y-2">
                            <Label>Image URL (รูปภาพ)</Label>
                            <Input value={imageUrl} onChange={e => setImageUrl(e.target.value)} className="bg-zinc-900 border-zinc-700" placeholder="https://..." />
                        </div>

                        <div className="space-y-2">
                            <Label>Social Link (Updated From)</Label>
                            <Input value={socialLink} onChange={e => setSocialLink(e.target.value)} className="bg-zinc-900 border-zinc-700" placeholder="https://facebook.com/..." />
                        </div>

                        <div className="pt-4 flex justify-end gap-2">
                            <ThaiButton type="button" variant="outline" onClick={() => setOpen(false)}>Cancel</ThaiButton>
                            <ThaiButton type="submit" variant="primary" disabled={loading}>
                                {loading ? "Saving..." : "Save Hero"}
                            </ThaiButton>
                        </div>
                    </form>
                </div>
            </DialogContent>
        </Dialog>
    );
}
