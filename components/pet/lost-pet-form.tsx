"use client";

import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { ThaiButton } from "@/components/ui/thai-button";
import { Input } from "@/components/ui/input";
import { compressImage } from "@/lib/image-utils";
import { Textarea } from "@/components/ui/textarea";
import { Label } from "@/components/ui/label";
import { Loader2, Upload, MapPin, Check, ChevronRight, ChevronLeft, X, Plus } from "lucide-react";
import { auth } from "@/lib/firebase";
import { onAuthStateChanged, User } from "firebase/auth";
import dynamic from "next/dynamic";
import { usePathname, useRouter, useSearchParams } from "next/navigation";

// Dynamically import MapPicker
const MapPicker = dynamic(() => import("@/components/map/map-picker"), {
    ssr: false,
    loading: () => <div className="h-[300px] w-full bg-gray-100 animate-pulse rounded-xl flex items-center justify-center text-gray-400">กำลังโหลดแผนที่...</div>
});

interface LostPetFormProps {
    open?: boolean;
    onOpenChange?: (open: boolean) => void;
}

export function LostPetForm({ open: externalOpen, onOpenChange }: LostPetFormProps) {
    // Form component for reporting lost pets
    const router = useRouter();
    const pathname = usePathname();
    const searchParams = useSearchParams();
    const [internalOpen, setInternalOpen] = useState(false);
    const isControlled = externalOpen !== undefined;
    const open = isControlled ? externalOpen : internalOpen;

    const setOpen = (value: boolean) => {
        if (isControlled) {
            onOpenChange?.(value);
        } else {
            setInternalOpen(value);
        }
    };
    const [step, setStep] = useState(1);
    const [loading, setLoading] = useState(false);
    const [user, setUser] = useState<User | null>(null);
    const [error, setError] = useState<string | null>(null);

    // Form State
    const [petName, setPetName] = useState("");
    const [petType, setPetType] = useState<"dog" | "cat">("dog");
    const [breed, setBreed] = useState("");
    const [color, setColor] = useState("");
    const [marks, setMarks] = useState("");
    const [ownerName, setOwnerName] = useState("");
    const [contactInfo, setContactInfo] = useState("");
    const [reward, setReward] = useState("");
    const [description, setDescription] = useState("");
    const [images, setImages] = useState<File[]>([]);
    const [imagePreviews, setImagePreviews] = useState<string[]>([]);
    const [location, setLocation] = useState<{ lat: number; lng: number } | null>(null);
    const [lastSeenDate, setLastSeenDate] = useState("");
    const [sex, setSex] = useState<'male' | 'female' | 'unknown'>('unknown');
    const [petAnalysis, setPetAnalysis] = useState<any>(null);
    const [analyzing, setAnalyzing] = useState(false);

    /** Pet photo analysis only (no loading UI — caller manages `analyzing`). */
    const runPetImageAnalysis = async (file: File) => {
        const formData = new FormData();
        formData.append("image", file);

        const response = await fetch("/api/analyze-pet", {
            method: "POST",
            body: formData,
        });

        const data = await response.json();
        if (!data.success) return;

        setPetAnalysis(data.data);

        if (data.data.species === "dog" || data.data.species === "cat") setPetType(data.data.species);
        if (data.data.color_main) setColor(data.data.color_main);
        if (data.data.unique_marks) setMarks(data.data.unique_marks);
        if (data.data.description) setDescription(data.data.description);

        setImages((prev) => [...prev, file]);
        const reader = new FileReader();
        reader.onloadend = () => {
            setImagePreviews((prev) => [...prev, reader.result as string]);
        };
        reader.readAsDataURL(file);
    };

    /** Social screenshot / post text + visuals; returns fields filled count, or null if API unusable. */
    const applySocialPostImport = (info: Record<string, unknown>, imageToUpload: File): number => {
        let filledCount = 0;
        if (info.pet_name) {
            setPetName(String(info.pet_name));
            filledCount++;
        }
        if (info.species === "dog" || info.species === "cat") {
            setPetType(info.species);
            filledCount++;
        }
        if (info.breed) {
            setBreed(String(info.breed));
            filledCount++;
        }
        if (info.color) {
            setColor(String(info.color));
            filledCount++;
        }
        if (info.marks) {
            setMarks(String(info.marks));
            filledCount++;
        }
        if (info.owner_name) {
            setOwnerName(String(info.owner_name));
            filledCount++;
        }
        if (info.contact_info) {
            setContactInfo(String(info.contact_info));
            filledCount++;
        }
        if (info.reward) {
            setReward(String(info.reward));
            filledCount++;
        }
        if (info.sex === "male" || info.sex === "female" || info.sex === "unknown") {
            setSex(info.sex);
            filledCount++;
        }
        if (info.description) {
            setDescription(String(info.description));
            filledCount++;
        }
        if (info.last_seen_date) {
            setLastSeenDate(String(info.last_seen_date));
            filledCount++;
        }

        setImages((prev) => [imageToUpload, ...prev]);
        const reader = new FileReader();
        reader.onloadend = () => {
            setImagePreviews((prev) => [reader.result as string, ...prev]);
        };
        reader.readAsDataURL(imageToUpload);

        return filledCount;
    };

    /** One entry point: post screenshot or direct pet photo — try social/post parser first, then pet vision. */
    const handleAiAssistFromImage = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        e.target.value = "";
        if (!file) return;

        setAnalyzing(true);
        let imageToUpload = file;
        try {
            try {
                imageToUpload = await compressImage(file);
            } catch (err) {
                console.error("Compression failed", err);
            }

            let usedSocial = false;
            try {
                const formData = new FormData();
                formData.append("image", imageToUpload);
                const response = await fetch("/api/analyze-social-post", {
                    method: "POST",
                    body: formData,
                });
                const data = await response.json();
                if (data.success && data.data) {
                    const filled = applySocialPostImport(data.data, imageToUpload);
                    if (filled > 0) {
                        alert(
                            `ดึงข้อมูลเรียบร้อย! (พบข้อมูล ${filled} รายการ)\nกรุณาตรวจสอบความถูกต้องและเติมข้อมูลที่ขาดหายไป`
                        );
                    } else {
                        alert("วิเคราะห์รูปภาพแล้ว แต่ไม่พบข้อมูลที่ชัดเจน กรุณากรอกข้อมูลด้วยตนเอง");
                    }
                    usedSocial = true;
                }
            } catch (err) {
                console.error("Error analyzing with social-post route:", err);
            }

            if (!usedSocial) {
                await runPetImageAnalysis(imageToUpload);
            }
        } catch (error) {
            console.error("Error analyzing image:", error);
            alert("ไม่สามารถวิเคราะห์ข้อมูลได้ หรือไม่พบข้อมูลสัตว์เลี้ยงในภาพ");
        } finally {
            setAnalyzing(false);
        }
    };

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
            setUser(currentUser);
        });
        return () => unsubscribe();
    }, []);

    useEffect(() => {
        if (open && !user && !loading) {
            // Check if we just opened it and user is not logged in
            // We need a small delay or check to ensure user state is loaded? 
            // Actually user state might be null initially.
            // Better to handle this in the trigger or ensure user is loaded.
            // But for now, let's rely on the existing check in handleOpenDialog for uncontrolled,
            // and add a check here for controlled.

            // However, user might be null because it's loading.
            // We should probably check this only if we are sure auth is initialized.
            // For simplicity, let's assume if open is true and we are controlled, we check.
        }
    }, [open, user]);
    const handleImageSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const files = Array.from(e.target.files || []);
        if (files.length > 0) {
            const compressedFiles = await Promise.all(
                files.map(async (file) => {
                    try {
                        return await compressImage(file);
                    } catch (err) {
                        console.error("Compression failed", err);
                        return file;
                    }
                })
            );

            setImages(prev => [...prev, ...compressedFiles]);

            const newPreviews: string[] = [];
            let loadedCount = 0;

            compressedFiles.forEach(file => {
                const reader = new FileReader();
                reader.onloadend = () => {
                    newPreviews.push(reader.result as string);
                    loadedCount++;
                    if (loadedCount === compressedFiles.length) {
                        setImagePreviews(prev => [...prev, ...newPreviews]);
                    }
                };
                reader.readAsDataURL(file);
            });
        }
    };

    const removeImage = (index: number) => {
        setImages(prev => prev.filter((_, i) => i !== index));
        setImagePreviews(prev => prev.filter((_, i) => i !== index));
    };

    const handleSubmit = async () => {
        if (!user) {
            setError("กรุณาเข้าสู่ระบบก่อนแจ้งสัตว์เลี้ยงหาย");
            return;
        }
        if (images.length === 0) {
            setError("กรุณาอัพโหลดรูปภาพอย่างน้อย 1 รูป");
            return;
        }

        setLoading(true);
        setError(null);

        try {
            const formData = new FormData();
            images.forEach(file => formData.append('images', file));
            formData.append('pet_name', petName);
            formData.append('pet_type', petType);
            formData.append('breed', breed);
            formData.append('color', color);
            formData.append('marks', marks);
            formData.append('owner_name', ownerName);
            formData.append('contact_info', contactInfo);
            formData.append('reward', reward);
            formData.append('sex', sex);
            formData.append('description', description);
            formData.append('user_id', user.uid);

            if (location) {
                formData.append('lat', location.lat.toString());
                formData.append('lng', location.lng.toString());
            }
            if (lastSeenDate) {
                formData.append('last_seen_at', new Date(lastSeenDate).toISOString());
            }

            // Append analysis data
            if (petAnalysis) {
                Object.entries(petAnalysis).forEach(([key, value]) => {
                    if (value !== null && value !== undefined) {
                        if (typeof value === 'object') {
                            formData.append(key, JSON.stringify(value));
                        } else {
                            formData.append(key, String(value));
                        }
                    }
                });
            }

            const response = await fetch('/api/pet/lost', {
                method: 'POST',
                body: formData,
            });

            const data = await response.json();

            if (data.success) {
                setOpen(false);
                // Reset form
                setStep(1);
                setPetName("");
                setImages([]);
                setPetName("");
                setImages([]);
                setImagePreviews([]);
                setLastSeenDate("");
                // Show success toast/alert (handled by parent or simple alert for now)
                alert("บันทึกข้อมูลสำเร็จ! ระบบจะแจ้งเตือนเมื่อพบสัตว์เลี้ยงที่คล้ายกัน");
            } else {
                setError(data.error || "เกิดข้อผิดพลาด");
            }
        } catch (err: any) {
            setError(err.message || "เกิดข้อผิดพลาดในการเชื่อมต่อ");
        } finally {
            setLoading(false);
        }
    };

    const nextStep = () => setStep(prev => prev + 1);
    const prevStep = () => setStep(prev => prev - 1);

    const handleOpenDialog = () => {
        if (!user) {
            alert('กรุณาเข้าสู่ระบบก่อนแจ้งสัตว์หาย');
            const qs = searchParams?.toString();
            const nextPath = `${pathname}${qs ? `?${qs}` : ""}`;
            router.push(`/login?next=${encodeURIComponent(nextPath)}`);
            return;
        }
        setOpen(true);
    };

    return (
        <Dialog open={open} onOpenChange={setOpen}>
            {/* Only show trigger button if not controlled */}
            {!isControlled && (
                <button
                    onClick={handleOpenDialog}
                    className="bg-orange-500 hover:bg-orange-600 text-white p-2 rounded-full shadow-lg hover:shadow-xl transition-all flex items-center gap-2 px-4"
                >
                    <Plus className="w-5 h-5" />
                    <span className="font-bold">เพิ่ม</span>
                </button>
            )}
            <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
                <DialogHeader>
                    <DialogTitle className="text-2xl font-bold text-center">
                        แจ้งสัตว์เลี้ยงหาย (ขั้นตอนที่ {step}/4)
                    </DialogTitle>
                </DialogHeader>

                <div className="py-4">
                    {/* Step 1: Pet Details */}
                    {step === 1 && (
                        <div className="space-y-4 animate-in fade-in slide-in-from-right-4">

                            {/* Single AI assist upload: direct pet photo or social screenshot */}
                            <div className="bg-blue-50 p-4 rounded-xl border border-blue-100 mb-4">
                                <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                                    <div className="min-w-0">
                                        <h3 className="font-bold text-blue-800">ให้ AI ช่วยจากรูปภาพ</h3>
                                        <p className="text-xs text-blue-600 mt-1">
                                            อัพโหลดรูปสัตว์โดยตรง หรือแคปหน้าจอโพสต์ Facebook/IG — ระบบจะดึงสี ตำหนิ และรายละเอียดให้
                                        </p>
                                    </div>
                                    <label className="cursor-pointer shrink-0 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-full flex items-center gap-2 transition-colors self-start sm:self-auto">
                                        {analyzing ? <Loader2 className="w-4 h-4 animate-spin" /> : <Upload className="w-4 h-4" />}
                                        <span className="text-sm font-bold whitespace-nowrap">
                                            {analyzing ? "กำลังวิเคราะห์..." : "อัพโหลดรูป (AI)"}
                                        </span>
                                        <input
                                            type="file"
                                            accept="image/*"
                                            className="hidden"
                                            onChange={handleAiAssistFromImage}
                                            disabled={analyzing}
                                        />
                                    </label>
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <Label>ชื่อน้อง</Label>
                                    <Input value={petName} onChange={e => setPetName(e.target.value)} placeholder="ชื่อสัตว์เลี้ยง" className="text-gray-900 bg-white border-gray-600 focus:border-orange-500" />
                                </div>
                                <div>
                                    <Label>ประเภท</Label>
                                    <select
                                        value={petType}
                                        onChange={e => setPetType(e.target.value as 'dog' | 'cat')}
                                        className="w-full px-3 py-2 border rounded-md text-gray-900 bg-white border-gray-600 focus:border-orange-500"
                                    >
                                        <option value="dog">สุนัข</option>
                                        <option value="cat">แมว</option>
                                    </select>
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <Label>สายพันธุ์</Label>
                                    <Input value={breed} onChange={e => setBreed(e.target.value)} placeholder="เช่น โกลเด้น, วิเชียรมาศ" className="text-gray-900 bg-white border-gray-600 focus:border-orange-500" />
                                </div>
                                <div>
                                    <Label>เพศ</Label>
                                    <select
                                        value={sex}
                                        onChange={e => setSex(e.target.value as 'male' | 'female' | 'unknown')}
                                        className="w-full px-3 py-2 border rounded-md text-gray-900 bg-white border-gray-600 focus:border-orange-500"
                                    >
                                        <option value="unknown">ไม่มีข้อมูล</option>
                                        <option value="male">ผู้</option>
                                        <option value="female">เมีย</option>
                                    </select>
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <Label>สี</Label>
                                    <Input value={color} onChange={e => setColor(e.target.value)} placeholder="เช่น น้ำตาล, ขาว-ดำ" className="text-gray-900 bg-white border-gray-600 focus:border-orange-500" />
                                </div>
                            </div>
                            <div>
                                <Label>ตำหนิที่สังเกตได้ชัด</Label>
                                <Input value={marks} onChange={e => setMarks(e.target.value)} placeholder="เช่น หางกุด, มีปานแดงที่หู" className="text-gray-900 bg-white border-gray-600 focus:border-orange-500" />
                            </div>
                            <div>
                                <Label>รายละเอียดเพิ่มเติม</Label>
                                <Textarea value={description} onChange={e => setDescription(e.target.value)} placeholder="ข้อมูลอื่นๆ ที่เป็นประโยชน์" className="text-gray-900 bg-white border-gray-600 focus:border-orange-500" />
                            </div>
                        </div>
                    )}

                    {/* Step 2: Photos */}
                    {step === 2 && (
                        <div className="space-y-4 animate-in fade-in slide-in-from-right-4">
                            <div className="border-2 border-dashed border-gray-300 rounded-xl p-8 text-center hover:border-blue-500 transition-colors bg-gray-50">
                                <input
                                    type="file"
                                    accept="image/*"
                                    multiple
                                    onChange={handleImageSelect}
                                    className="hidden"
                                    id="lost-pet-images"
                                />
                                <label htmlFor="lost-pet-images" className="cursor-pointer flex flex-col items-center">
                                    <Upload className="w-12 h-12 text-gray-400 mb-2" />
                                    <span className="text-gray-600 font-medium">คลิกเพื่อเพิ่มรูปภาพ</span>
                                    <span className="text-xs text-gray-400">เลือกรูปที่เห็นชัดเจน (หลายรูปได้)</span>
                                </label>
                            </div>

                            {imagePreviews.length > 0 && (
                                <div className="grid grid-cols-3 gap-4">
                                    {imagePreviews.map((preview, index) => (
                                        <div key={index} className="relative aspect-square rounded-lg overflow-hidden border">
                                            <img src={preview} alt={`Preview ${index} `} className="w-full h-full object-cover" />
                                            <button
                                                onClick={() => removeImage(index)}
                                                className="absolute top-1 right-1 bg-black/50 hover:bg-red-500 text-white p-1 rounded-full"
                                            >
                                                <X className="w-4 h-4" />
                                            </button>
                                        </div>
                                    ))}
                                </div>
                            )}
                        </div>
                    )}

                    {/* Step 3: Location */}
                    {step === 3 && (
                        <div className="space-y-4 animate-in fade-in slide-in-from-right-4">
                            <Label>ตำแหน่งที่หายล่าสุด</Label>
                            <MapPicker
                                lat={location?.lat}
                                lng={location?.lng}
                                onLocationSelect={(lat, lng) => setLocation({ lat, lng })}
                            />
                            <div>
                                <Label>วันและเวลาที่หาย</Label>
                                <Input
                                    type="datetime-local"
                                    value={lastSeenDate}
                                    onChange={e => setLastSeenDate(e.target.value)}
                                    className="text-gray-900 bg-white border-gray-600 focus:border-orange-500"
                                />
                            </div>
                        </div>
                    )}

                    {/* Step 4: Owner Details */}
                    {step === 4 && (
                        <div className="space-y-4 animate-in fade-in slide-in-from-right-4">
                            <div>
                                <Label>ชื่อเจ้าของ</Label>
                                <Input value={ownerName} onChange={e => setOwnerName(e.target.value)} placeholder="ชื่อ-นามสกุล" className="text-gray-900 bg-white border-gray-600 focus:border-orange-500" />
                            </div>
                            <div>
                                <Label>ช่องทางติดต่อ (Contact)</Label>
                                <Input value={contactInfo} onChange={e => setContactInfo(e.target.value)} placeholder="เบอร์โทร, Line ID" className="text-gray-900 bg-white border-gray-600 focus:border-orange-500" />
                            </div>
                            <div>
                                <Label>สินน้ำใจ (Reward)</Label>
                                <Input value={reward} onChange={e => setReward(e.target.value)} placeholder="ระบุจำนวนเงิน หรือ ของรางวัล (ถ้ามี)" className="text-gray-900 bg-white border-gray-600 focus:border-orange-500" />
                            </div>
                        </div>
                    )}

                    {error && (
                        <div className="mt-4 p-3 bg-red-50 text-red-600 rounded-lg text-sm">
                            {error}
                        </div>
                    )}
                </div>

                <div className="flex justify-between mt-6">
                    {step > 1 ? (
                        <ThaiButton variant="outline" onClick={prevStep}>
                            <ChevronLeft className="w-4 h-4 mr-2" /> ย้อนกลับ
                        </ThaiButton>
                    ) : (
                        <div></div>
                    )}

                    {step < 4 ? (
                        <ThaiButton onClick={nextStep}>
                            ถัดไป <ChevronRight className="w-4 h-4 ml-2" />
                        </ThaiButton>
                    ) : (
                        <ThaiButton onClick={handleSubmit} disabled={loading} className="bg-red-600 hover:bg-red-700 text-white">
                            {loading ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : <Check className="w-4 h-4 mr-2" />}
                            ยืนยันการแจ้งหาย
                        </ThaiButton>
                    )}
                </div>
            </DialogContent>
        </Dialog>
    );
}
