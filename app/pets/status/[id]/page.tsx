"use client";

import React, { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { getPetDetails, updatePetStatus, addPetImages, updatePetDetails } from "@/app/actions/pet";
import { supabase } from "@/lib/supabase";
import { Loader2, ShieldCheck, ShieldAlert, ShieldQuestion, Clock, MapPin, Phone, User, PawPrint, CheckCircle, ArrowLeft, ChevronLeft, ChevronRight, Pencil, ImagePlus } from "lucide-react";
import { format } from "date-fns";
import { th } from "date-fns/locale";
import { auth } from "@/lib/firebase";
import { onAuthStateChanged } from "firebase/auth";
import { ThaiButton } from "@/components/ui/thai-button";
import Link from "next/link";
import PetComments from "@/components/pet/pet-comments";
import { differenceInDays, differenceInHours, differenceInMinutes, addDays } from "date-fns";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";

export default function PetStatusPage() {
    const params = useParams();
    const id = params?.id as string;
    const router = useRouter();

    const [petData, setPetData] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [currentUser, setCurrentUser] = useState<any>(null);
    const [updating, setUpdating] = useState(false);
    const [editMode, setEditMode] = useState(false);
    const [uploadingPhoto, setUploadingPhoto] = useState(false);
    const photoInputRef = React.useRef<HTMLInputElement>(null);
    const [saving, setSaving] = useState(false);

    // Edit form states
    const [editPetName, setEditPetName] = useState('');
    const [editBreed, setEditBreed] = useState('');
    const [editColor, setEditColor] = useState('');
    const [editMarks, setEditMarks] = useState('');
    const [editDescription, setEditDescription] = useState('');
    const [editSex, setEditSex] = useState('');
    const [editContactInfo, setEditContactInfo] = useState('');
    const [editReward, setEditReward] = useState('');

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (user) => {
            setCurrentUser(user);
        });
        return () => unsubscribe();
    }, []);

    useEffect(() => {
        fetchData();
    }, [id]);

    const fetchData = async () => {
        if (!id) return;
        const result = await getPetDetails(id);
        if (result.success) {
            setPetData(result.data);
        } else {
            setError(result.error || "Failed to load pet data");
        }
        setLoading(false);
    };

    const handleConfirmFound = async () => {
        if (!confirm("ยืนยันว่าคุณพบสัตว์เลี้ยงแล้ว? สถานะจะถูกเปลี่ยนเป็น 'พบแล้ว'")) return;

        setUpdating(true);
        const result = await updatePetStatus(id, "REUNITED");
        if (result.success) {
            setPetData(result.data);
            alert("ยินดีด้วย! สถานะสัตว์เลี้ยงถูกอัปเดตเรียบร้อยแล้ว");
        } else {
            alert("เกิดข้อผิดพลาด: " + result.error);
        }
        setUpdating(false);
    };

    const handleAddPhoto = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const files = e.target.files;
        if (!files || files.length === 0) return;

        setUploadingPhoto(true);
        const newImageUrls: string[] = [];

        try {
            for (const file of Array.from(files)) {
                const fileExt = file.name.split('.').pop();
                const fileName = `pets/${id}/${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`;

                const { error: uploadError } = await supabase.storage
                    .from('sos-photos')
                    .upload(fileName, file);

                if (uploadError) {
                    console.error('Upload error:', uploadError);
                    continue;
                }

                const { data: { publicUrl } } = supabase.storage
                    .from('sos-photos')
                    .getPublicUrl(fileName);

                newImageUrls.push(publicUrl);
            }

            if (newImageUrls.length > 0) {
                const result = await addPetImages(id, newImageUrls);
                if (result.success) {
                    setPetData(result.data);
                    alert(`เพิ่มรูปภาพสำเร็จ ${newImageUrls.length} รูป`);
                } else {
                    alert('เกิดข้อผิดพลาด: ' + result.error);
                }
            }
        } catch (error: any) {
            console.error('Error adding photos:', error);
            alert('เกิดข้อผิดพลาดในการอัพโหลดรูปภาพ');
        } finally {
            setUploadingPhoto(false);
            if (photoInputRef.current) photoInputRef.current.value = '';
        }
    };

    const handleOpenEdit = () => {
        // Populate form with current values
        setEditPetName(petData.pet_name || '');
        setEditBreed(petData.breed || '');
        setEditColor(petData.color || '');
        setEditMarks(petData.marks || '');
        setEditDescription(petData.description || '');
        setEditSex(petData.sex || 'unknown');
        setEditContactInfo(petData.contact_info || '');
        setEditReward(petData.reward || '');
        setEditMode(true);
    };

    const handleSaveEdit = async () => {
        setSaving(true);
        try {
            const result = await updatePetDetails(id, {
                pet_name: editPetName,
                breed: editBreed,
                color: editColor,
                marks: editMarks,
                description: editDescription,
                sex: editSex,
                contact_info: editContactInfo,
                reward: editReward,
            });

            if (result.success) {
                setPetData(result.data);
                setEditMode(false);
                alert('บันทึกข้อมูลสำเร็จ');
            } else {
                alert('เกิดข้อผิดพลาด: ' + result.error);
            }
        } catch (error: any) {
            console.error('Error saving:', error);
            alert('เกิดข้อผิดพลาดในการบันทึก');
        } finally {
            setSaving(false);
        }
    };

    if (loading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-50">
                <Loader2 className="w-8 h-8 animate-spin text-orange-500" />
            </div>
        );
    }

    if (error || !petData) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-50 p-4">
                <div className="bg-white p-6 rounded-xl shadow-lg max-w-md w-full text-center">
                    <ShieldAlert className="w-12 h-12 text-red-500 mx-auto mb-4" />
                    <h1 className="text-xl font-bold text-gray-900 mb-2">ไม่สามารถเข้าถึงข้อมูลได้</h1>
                    <p className="text-gray-600">{error || "ไม่พบข้อมูลสัตว์เลี้ยง"}</p>
                    <Link href="/find-pet">
                        <ThaiButton className="mt-4 bg-orange-500 hover:bg-orange-600">กลับหน้าหลัก</ThaiButton>
                    </Link>
                </div>
            </div>
        );
    }

    const isOwner = currentUser && petData.user_id === currentUser.uid;

    return (
        <div className="min-h-screen bg-gray-50 pb-12">
            {/* Header */}
            <header className="bg-white shadow-sm sticky top-0 z-10">
                <div className="container mx-auto px-4 py-4">
                    <div className="flex items-center gap-3">
                        <Link href="/find-pet" className="mr-2">
                            <ArrowLeft className="w-6 h-6 text-gray-500" />
                        </Link>
                        <div className="w-10 h-10 bg-orange-100 rounded-full flex items-center justify-center text-orange-600">
                            <PawPrint className="w-6 h-6" />
                        </div>
                        <div>
                            <h1 className="font-bold text-lg text-gray-900 leading-tight">
                                {petData.pet_name || "ไม่ระบุชื่อ"}
                            </h1>
                            <div className="flex items-center text-xs text-gray-500 gap-1">
                                <span className="bg-orange-100 text-orange-800 px-2 py-0.5 rounded-full text-[10px] font-bold">
                                    {petData.pet_type === 'dog' ? 'สุนัข' : petData.pet_type === 'cat' ? 'แมว' : 'สัตว์เลี้ยง'}
                                </span>
                                <span>• {petData.breed || "ไม่ระบุสายพันธุ์"}</span>
                            </div>
                        </div>
                        <button
                            onClick={handleOpenEdit}
                            className="ml-auto p-2 text-gray-500 hover:text-orange-500 hover:bg-orange-50 rounded-full transition-colors"
                            title="แก้ไขข้อมูล"
                        >
                            <Pencil className="w-5 h-5" />
                        </button>
                    </div>
                </div>
            </header>

            <main className="container mx-auto px-4 py-6 max-w-lg space-y-6">
                {/* Pet Image Gallery */}
                <PetImageGallery
                    images={petData.images?.length > 0 ? petData.images : [petData.image_url].filter(Boolean)}
                    petName={petData.pet_name}
                    color={petData.color}
                    marks={petData.marks}
                />

                {/* Expiration Countdown */}
                <CountdownTimer createdAt={petData.created_at} />

                {/* Status Card */}
                <StatusCard status={petData.status} />

                {/* Owner Actions */}
                {isOwner && petData.status !== 'REUNITED' && (
                    <div className="bg-white rounded-xl border shadow-sm p-5">
                        <h2 className="font-bold text-lg mb-3 text-gray-900">สำหรับเจ้าของ</h2>
                        <p className="text-sm text-gray-600 mb-4">หากคุณพบสัตว์เลี้ยงของคุณแล้ว กรุณากดยืนยันเพื่อปิดเคส</p>
                        <button
                            onClick={handleConfirmFound}
                            disabled={updating}
                            className="w-full bg-green-600 hover:bg-green-700 text-white font-bold py-3 rounded-xl shadow-lg shadow-green-200 flex items-center justify-center gap-2 transition-all disabled:opacity-50"
                        >
                            {updating ? (
                                <Loader2 className="w-5 h-5 animate-spin" />
                            ) : (
                                <CheckCircle className="w-5 h-5" />
                            )}
                            ยืนยันว่าพบแล้ว (ปิดเคส)
                        </button>
                    </div>
                )}

                {/* Add Photo Section - Available to everyone */}
                {petData.status !== 'REUNITED' && (
                    <div className="bg-white rounded-xl border shadow-sm p-5">
                        <h2 className="font-bold text-lg mb-3 text-gray-900">เพิ่มรูปภาพ</h2>
                        <p className="text-sm text-gray-600 mb-4">ช่วยเพิ่มรูปภาพน้องเพื่อให้ค้นหาได้ง่ายขึ้น</p>
                        <input
                            type="file"
                            accept="image/*"
                            multiple
                            ref={photoInputRef}
                            onChange={handleAddPhoto}
                            className="hidden"
                        />
                        <button
                            onClick={() => photoInputRef.current?.click()}
                            disabled={uploadingPhoto}
                            className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 rounded-xl shadow-lg shadow-blue-200 flex items-center justify-center gap-2 transition-all disabled:opacity-50"
                        >
                            {uploadingPhoto ? (
                                <Loader2 className="w-5 h-5 animate-spin" />
                            ) : (
                                <ImagePlus className="w-5 h-5" />
                            )}
                            เพิ่มรูปภาพ
                        </button>
                    </div>
                )}

                {/* Timeline */}
                <Timeline petData={petData} />

                {/* Info Note */}
                <div className="bg-blue-50 border border-blue-100 rounded-xl p-4 text-sm text-blue-800">
                    <p className="flex gap-2">
                        <ShieldQuestion className="w-5 h-5 shrink-0" />
                        <span>
                            ข้อมูลในหน้านี้เป็นข้อมูลล่าสุดที่ระบบได้รับ หากมีเบาะแสเพิ่มเติม กรุณาติดต่อเจ้าของโดยตรง
                        </span>
                    </p>
                </div>

                {/* Chat Section */}
                <div className="space-y-3">
                    <h2 className="font-bold text-lg text-gray-900">สอบถาม/แจ้งเบาะแส</h2>
                    {currentUser ? (
                        <PetComments
                            petId={id}
                            userId={currentUser.uid}
                            role={isOwner ? 'owner' : 'finder'}
                        />
                    ) : (
                        <div className="bg-white p-6 rounded-xl border shadow-sm text-center">
                            <p className="text-gray-600 mb-4">กรุณาเข้าสู่ระบบเพื่อส่งข้อความถึงเจ้าของ</p>
                            <Link href="/login">
                                <ThaiButton>เข้าสู่ระบบ</ThaiButton>
                            </Link>
                        </div>
                    )}
                </div>

                {/* Contact Info */}
                <div className="bg-white rounded-xl border shadow-sm p-5 space-y-3">
                    <h2 className="font-bold text-lg text-gray-900 flex items-center gap-2">
                        <User className="w-5 h-5 text-blue-600" />
                        {petData.status === 'FOUND' ? 'ข้อมูลติดต่อผู้แจ้งเบาะแส' : 'ข้อมูลติดต่อเจ้าของ'}
                    </h2>
                    <div className="flex items-center gap-4">
                        <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-bold text-xl">
                            {petData.owner_name?.[0] || "U"}
                        </div>
                        <div>
                            <p className="font-bold text-lg">{petData.owner_name || "ไม่ระบุชื่อ"}</p>
                            {petData.contact_info && (
                                <a href={`tel:${petData.contact_info}`} className="text-blue-600 flex items-center gap-1 hover:underline">
                                    <Phone className="w-4 h-4" />
                                    {petData.contact_info}
                                </a>
                            )}
                        </div>
                    </div>
                </div>

                {/* Description */}
                <div className="bg-white rounded-xl border shadow-sm p-5">
                    <h2 className="font-bold text-lg mb-2 text-gray-900">รายละเอียดเพิ่มเติม</h2>
                    <p className="text-gray-700 whitespace-pre-wrap">{petData.description || "ไม่มีรายละเอียด"}</p>

                    {petData.last_seen_at && (
                        <div className="mt-4 pt-4 border-t border-gray-100 text-sm text-gray-500 flex items-center gap-2">
                            <Clock className="w-4 h-4" />
                            <span>หายเมื่อ: {format(new Date(petData.last_seen_at), "d MMM yyyy HH:mm", { locale: th })}</span>
                        </div>
                    )}
                </div>

            </main>

            {/* Edit Pet Modal */}
            <Dialog open={editMode} onOpenChange={setEditMode}>
                <DialogContent className="max-w-md max-h-[90vh] overflow-y-auto">
                    <DialogHeader>
                        <DialogTitle className="text-xl font-bold">แก้ไขข้อมูลสัตว์เลี้ยง</DialogTitle>
                    </DialogHeader>
                    <div className="space-y-4 py-4">
                        <div>
                            <Label>ชื่อน้อง</Label>
                            <Input
                                value={editPetName}
                                onChange={e => setEditPetName(e.target.value)}
                                placeholder="ชื่อสัตว์เลี้ยง"
                                className="text-gray-900"
                            />
                        </div>
                        <div>
                            <Label>สายพันธุ์</Label>
                            <Input
                                value={editBreed}
                                onChange={e => setEditBreed(e.target.value)}
                                placeholder="เช่น โกลเด้น, วิเชียรมาศ"
                                className="text-gray-900"
                            />
                        </div>
                        <div className="grid grid-cols-2 gap-4">
                            <div>
                                <Label>สี</Label>
                                <Input
                                    value={editColor}
                                    onChange={e => setEditColor(e.target.value)}
                                    placeholder="เช่น น้ำตาล"
                                    className="text-gray-900"
                                />
                            </div>
                            <div>
                                <Label>เพศ</Label>
                                <select
                                    value={editSex}
                                    onChange={e => setEditSex(e.target.value)}
                                    className="w-full px-3 py-2 border rounded-md text-gray-900"
                                >
                                    <option value="unknown">ไม่มีข้อมูล</option>
                                    <option value="male">ผู้</option>
                                    <option value="female">เมีย</option>
                                </select>
                            </div>
                        </div>
                        <div>
                            <Label>ตำหนิ</Label>
                            <Input
                                value={editMarks}
                                onChange={e => setEditMarks(e.target.value)}
                                placeholder="เช่น หางกุด, มีปานแดง"
                                className="text-gray-900"
                            />
                        </div>
                        <div>
                            <Label>รายละเอียด</Label>
                            <Textarea
                                value={editDescription}
                                onChange={e => setEditDescription(e.target.value)}
                                placeholder="ข้อมูลเพิ่มเติม"
                                className="text-gray-900"
                                rows={3}
                            />
                        </div>
                        <div>
                            <Label>ช่องทางติดต่อ</Label>
                            <Input
                                value={editContactInfo}
                                onChange={e => setEditContactInfo(e.target.value)}
                                placeholder="เบอร์โทร, Line ID"
                                className="text-gray-900"
                            />
                        </div>
                        <div>
                            <Label>สินน้ำใจ (Reward)</Label>
                            <Input
                                value={editReward}
                                onChange={e => setEditReward(e.target.value)}
                                placeholder="ถ้ามี"
                                className="text-gray-900"
                            />
                        </div>
                        <div className="flex gap-3 pt-4">
                            <button
                                onClick={() => setEditMode(false)}
                                className="flex-1 py-3 rounded-xl border border-gray-300 text-gray-700 font-bold hover:bg-gray-50 transition-colors"
                            >
                                ยกเลิก
                            </button>
                            <button
                                onClick={handleSaveEdit}
                                disabled={saving}
                                className="flex-1 py-3 rounded-xl bg-orange-500 hover:bg-orange-600 text-white font-bold transition-colors disabled:opacity-50 flex items-center justify-center gap-2"
                            >
                                {saving && <Loader2 className="w-4 h-4 animate-spin" />}
                                บันทึก
                            </button>
                        </div>
                    </div>
                </DialogContent>
            </Dialog>
        </div>
    );
}

function StatusCard({ status }: { status: string }) {
    let color = "bg-gray-100 text-gray-700";
    let Icon = ShieldQuestion;
    let label = "ไม่ทราบสถานะ";
    let desc = "กำลังรอการตรวจสอบ";

    if (status === "REUNITED") {
        color = "bg-green-100 text-green-700 border-green-200";
        Icon = ShieldCheck;
        label = "พบแล้ว / ปลอดภัย";
        desc = "สัตว์เลี้ยงได้กลับคืนสู่เจ้าของแล้ว";
    } else if (status === "LOST") {
        color = "bg-red-100 text-red-700 border-red-200";
        Icon = ShieldAlert;
        label = "กำลังตามหา";
        desc = "ต้องการความช่วยเหลือในการตามหา";
    } else if (status === "FOUND") {
        color = "bg-yellow-100 text-yellow-700 border-yellow-200";
        Icon = Clock;
        label = "พบเบาะแส";
        desc = "มีผู้พบเห็นและแจ้งเข้ามาในระบบ";
    }

    return (
        <div className={`rounded-xl border p-5 ${color}`}>
            <div className="flex items-start justify-between mb-2">
                <h2 className="font-bold text-lg">สถานะปัจจุบัน</h2>
                <Icon className="w-6 h-6" />
            </div>
            <div className="text-2xl font-bold mb-1">{label}</div>
            <p className="opacity-90">{desc}</p>
        </div>
    );
}

function Timeline({ petData }: { petData: any }) {
    // Construct timeline events
    const events = [
        {
            id: "created",
            message: "ประกาศตามหาสัตว์เลี้ยง",
            created_at: petData.created_at,
            type: "start"
        }
    ];

    if (petData.status === 'REUNITED') {
        events.push({
            id: "reunited",
            message: "เจ้าของยืนยันว่าพบสัตว์เลี้ยงแล้ว",
            created_at: new Date().toISOString(), // In a real app, this should be from a separate events table or updated_at
            type: "end"
        });
    }

    // Sort by date desc
    events.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

    return (
        <div className="bg-white rounded-xl border shadow-sm p-5">
            <h2 className="font-bold text-lg mb-4 text-gray-900">ไทม์ไลน์เหตุการณ์</h2>
            <div className="space-y-6">
                {events.map((event) => (
                    <div key={event.id} className="flex gap-4">
                        <div className="flex flex-col items-center">
                            <div className="text-xs font-bold text-gray-500 w-12 text-right">
                                {format(new Date(event.created_at), "HH:mm")}
                            </div>
                        </div>
                        <div className="flex-1 pb-2 border-l-2 border-gray-100 pl-4 relative">
                            <div className={`absolute -left-[5px] top-1.5 w-2.5 h-2.5 rounded-full border-2 border-white ${event.type === 'end' ? 'bg-green-500' : 'bg-gray-300'
                                }`} />
                            <p className="text-gray-900 text-sm">{event.message}</p>
                            <p className="text-xs text-gray-400 mt-1">
                                {format(new Date(event.created_at), "d MMM yyyy", { locale: th })}
                            </p>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
}

function PetImageGallery({ images, petName, color, marks }: { images: string[], petName: string, color?: string, marks?: string }) {
    const [currentIndex, setCurrentIndex] = useState(0);

    const nextImage = () => {
        setCurrentIndex((prev) => (prev + 1) % images.length);
    };

    const prevImage = () => {
        setCurrentIndex((prev) => (prev - 1 + images.length) % images.length);
    };

    if (!images || images.length === 0) return null;

    return (
        <div className="aspect-video w-full bg-gray-200 rounded-xl overflow-hidden shadow-sm relative group">
            <img
                src={images[currentIndex]}
                alt={`${petName} - ${currentIndex + 1}`}
                className="w-full h-full object-cover transition-all duration-300"
            />

            {/* Overlay Info */}
            <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/70 to-transparent p-4 pointer-events-none">
                <p className="text-white font-bold text-lg">{petName}</p>
                {(color || marks) && (
                    <p className="text-white/80 text-sm">{color} • {marks || "ไม่มีตำหนิ"}</p>
                )}
            </div>

            {/* Navigation Buttons */}
            {images.length > 1 && (
                <>
                    <button
                        onClick={(e) => { e.preventDefault(); prevImage(); }}
                        className="absolute left-2 top-1/2 -translate-y-1/2 bg-black/30 hover:bg-black/50 text-white p-1.5 rounded-full backdrop-blur-sm transition-all opacity-0 group-hover:opacity-100"
                    >
                        <ChevronLeft className="w-6 h-6" />
                    </button>
                    <button
                        onClick={(e) => { e.preventDefault(); nextImage(); }}
                        className="absolute right-2 top-1/2 -translate-y-1/2 bg-black/30 hover:bg-black/50 text-white p-1.5 rounded-full backdrop-blur-sm transition-all opacity-0 group-hover:opacity-100"
                    >
                        <ChevronRight className="w-6 h-6" />
                    </button>

                    {/* Dots Indicator */}
                    <div className="absolute top-4 right-4 flex justify-center gap-1.5 pointer-events-none">
                        {images.map((_, idx) => (
                            <div
                                key={idx}
                                className={`w-1.5 h-1.5 rounded-full transition-all shadow-sm ${idx === currentIndex ? 'bg-white w-3' : 'bg-white/50'}`}
                            />
                        ))}
                    </div>
                </>
            )}
        </div>
    );
}

function CountdownTimer({ createdAt }: { createdAt: string }) {
    const [timeLeft, setTimeLeft] = useState<{ days: number; hours: number; minutes: number } | null>(null);

    useEffect(() => {
        const calculateTimeLeft = () => {
            const created = new Date(createdAt);
            const expirationDate = addDays(created, 180);
            const now = new Date();

            if (now >= expirationDate) {
                setTimeLeft(null); // Expired
                return;
            }

            const days = differenceInDays(expirationDate, now);
            const hours = differenceInHours(expirationDate, now) % 24;
            const minutes = differenceInMinutes(expirationDate, now) % 60;

            setTimeLeft({ days, hours, minutes });
        };

        calculateTimeLeft();
        const timer = setInterval(calculateTimeLeft, 60000); // Update every minute

        return () => clearInterval(timer);
    }, [createdAt]);

    if (!timeLeft) {
        return (
            <div className="bg-red-50 border border-red-100 rounded-xl p-4 flex items-center gap-3 text-red-700">
                <Clock className="w-5 h-5 shrink-0" />
                <span className="font-bold text-sm">โพสต์นี้หมดอายุแล้วและจะถูกลบออกจากระบบเร็วๆ นี้</span>
            </div>
        );
    }

    // Only show if less than 30 days remaining to avoid clutter, or always show? 
    // User asked for countdown, so let's show it.
    // Maybe style it differently based on urgency.
    const isUrgent = timeLeft.days < 7;

    return (
        <div className={`rounded-xl border p-4 flex items-center justify-between ${isUrgent ? 'bg-orange-50 border-orange-100 text-orange-800' : 'bg-gray-50 border-gray-200 text-gray-600'}`}>
            <div className="flex items-center gap-2">
                <Clock className="w-5 h-5" />
                <span className="text-sm font-medium">โพสต์จะถูกลบอัตโนมัติในอีก</span>
            </div>
            <div className="font-mono font-bold text-lg">
                {timeLeft.days} วัน {timeLeft.hours} ชม.
            </div>
        </div>
    );
}
