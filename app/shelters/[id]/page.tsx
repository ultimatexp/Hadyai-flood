"use client";

import { useState, useEffect } from "react";
import { useParams } from "next/navigation";
import { getShelter, getShelterComments, addShelterComment, toggleShelterLike, getShelterLikeStatus, deleteShelterComment } from "@/app/actions/shelter";
import { ArrowLeft, MapPin, Dog, Cat, Gift, Phone, Share2, Navigation, Edit, Heart, Send, User, Image as ImageIcon, Trash2 } from "lucide-react";
import Link from "next/link";
import { ThaiButton } from "@/components/ui/thai-button";
import dynamic from "next/dynamic";
import { onAuthStateChanged } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { supabase } from "@/lib/supabase";

const MapContainer = dynamic(() => import("react-leaflet").then(mod => mod.MapContainer), { ssr: false });
const TileLayer = dynamic(() => import("react-leaflet").then(mod => mod.TileLayer), { ssr: false });
const Marker = dynamic(() => import("react-leaflet").then(mod => mod.Marker), { ssr: false });
const Popup = dynamic(() => import("react-leaflet").then(mod => mod.Popup), { ssr: false });

export default function ShelterDetailPage() {
    const params = useParams();
    const id = params.id as string;
    const [shelter, setShelter] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [user, setUser] = useState<any>(null);

    // Interaction State
    const [comments, setComments] = useState<any[]>([]);
    const [newComment, setNewComment] = useState("");
    const [likeCount, setLikeCount] = useState(0);
    const [isLiked, setIsLiked] = useState(false);
    const [commentLoading, setCommentLoading] = useState(false);
    const [commentImage, setCommentImage] = useState<File | null>(null);
    const [commentImagePreview, setCommentImagePreview] = useState<string | null>(null);

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, (currentUser) => {
            setUser(currentUser);
        });
        return () => unsubscribe();
    }, []);

    useEffect(() => {
        const fetchShelter = async () => {
            const result = await getShelter(id);
            if (result.success && result.data) {
                setShelter(result.data);
            }
            setLoading(false);
        };
        fetchShelter();
    }, [id]);

    useEffect(() => {
        const fetchInteractions = async () => {
            if (user) {
                const likeStatus = await getShelterLikeStatus(id, user.uid);
                if (likeStatus.success) {
                    setLikeCount(likeStatus.count);
                    setIsLiked(likeStatus.liked);
                }
            } else {
                const likeStatus = await getShelterLikeStatus(id);
                if (likeStatus.success) {
                    setLikeCount(likeStatus.count);
                }
            }

            const commentsResult = await getShelterComments(id);
            if (commentsResult.success && commentsResult.data) {
                setComments(commentsResult.data);
            }
        };
        fetchInteractions();
    }, [id, user]);

    const handleLike = async () => {
        if (!user) {
            alert("กรุณาเข้าสู่ระบบเพื่อถูกใจ");
            return;
        }

        // Optimistic update
        const newLiked = !isLiked;
        setIsLiked(newLiked);
        setLikeCount(prev => newLiked ? prev + 1 : prev - 1);

        const result = await toggleShelterLike(id, user.uid);
        if (!result.success) {
            // Revert on error
            setIsLiked(!newLiked);
            setLikeCount(prev => !newLiked ? prev + 1 : prev - 1);
        }
    };

    const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            setCommentImage(file);
            const reader = new FileReader();
            reader.onloadend = () => {
                setCommentImagePreview(reader.result as string);
            };
            reader.readAsDataURL(file);
        }
    };

    const removeImage = () => {
        setCommentImage(null);
        setCommentImagePreview(null);
    };

    const handleDeleteComment = async (commentId: string) => {
        if (!confirm("คุณต้องการลบความคิดเห็นนี้ใช่หรือไม่?")) return;

        const result = await deleteShelterComment(commentId, user.uid);
        if (result.success) {
            // Refresh comments
            const commentsResult = await getShelterComments(id);
            if (commentsResult.success && commentsResult.data) {
                setComments(commentsResult.data);
            }
        } else {
            alert("เกิดข้อผิดพลาดในการลบความคิดเห็น");
        }
    };

    const handleComment = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!user || (!newComment.trim() && !commentImage)) return;

        setCommentLoading(true);
        try {
            let imageUrl = undefined;

            if (commentImage) {
                const fileExt = commentImage.name.split('.').pop();
                const fileName = `comments/${Date.now()}_${Math.random().toString(36).substring(7)}.${fileExt}`;

                const { error: uploadError } = await supabase.storage
                    .from('sos-photos')
                    .upload(fileName, commentImage);

                if (uploadError) throw uploadError;

                const { data: { publicUrl } } = supabase.storage
                    .from('sos-photos')
                    .getPublicUrl(fileName);

                imageUrl = publicUrl;
            }

            const result = await addShelterComment(id, user.uid, newComment, imageUrl);

            if (result.success) {
                setNewComment("");
                setCommentImage(null);
                setCommentImagePreview(null);
                // Refresh comments
                const commentsResult = await getShelterComments(id);
                if (commentsResult.success && commentsResult.data) {
                    setComments(commentsResult.data);
                }
            } else {
                alert("เกิดข้อผิดพลาดในการส่งความคิดเห็น");
            }
        } catch (error) {
            console.error(error);
            alert("เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ");
        } finally {
            setCommentLoading(false);
        }
    };

    const handleShare = () => {
        navigator.clipboard.writeText(window.location.href);
        alert("คัดลอกลิงก์เรียบร้อยแล้ว");
    };

    if (loading) return <div className="min-h-screen flex items-center justify-center"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500"></div></div>;
    if (!shelter) return <div className="min-h-screen flex items-center justify-center">ไม่พบข้อมูลศูนย์พักพิง</div>;

    return (
        <div className="min-h-screen bg-gray-50 pb-20">
            {/* Header Image */}
            <div className="relative h-[300px] md:h-[400px] bg-gray-200">
                {shelter.images && shelter.images[0] ? (
                    <img src={shelter.images[0]} alt={shelter.name} className="w-full h-full object-cover" />
                ) : (
                    <div className="w-full h-full flex items-center justify-center bg-gray-300 text-gray-500">ไม่มีรูปภาพ</div>
                )}
                <div className="absolute top-0 left-0 right-0 p-4 bg-gradient-to-b from-black/50 to-transparent">
                    <div className="max-w-5xl mx-auto flex justify-between items-center">
                        <Link href="/shelters">
                            <button className="bg-white/20 backdrop-blur hover:bg-white/30 text-white p-2 rounded-full transition-colors">
                                <ArrowLeft className="w-6 h-6" />
                            </button>
                        </Link>

                        {user && (
                            <Link href={`/shelters/${id}/edit`}>
                                <button className="bg-white/20 backdrop-blur hover:bg-white/30 text-white p-2 rounded-full transition-colors flex items-center gap-2 px-4">
                                    <Edit className="w-4 h-4" />
                                    <span className="text-sm font-bold">แก้ไขข้อมูล</span>
                                </button>
                            </Link>
                        )}
                    </div>
                </div>
            </div>

            <div className="max-w-5xl mx-auto px-4 -mt-10 relative z-10">
                <div className="bg-white rounded-2xl shadow-lg p-6 md:p-8 mb-6">
                    <div className="flex flex-col md:flex-row justify-between items-start gap-4 mb-6">
                        <div>
                            <h1 className="text-3xl font-bold text-gray-900 mb-2">{shelter.name}</h1>
                            <div className="flex items-center gap-2 text-gray-500">
                                <MapPin className="w-4 h-4" />
                                <span>{shelter.lat.toFixed(4)}, {shelter.lng.toFixed(4)}</span>
                            </div>
                        </div>
                        <div className="flex gap-2">
                            <button
                                onClick={handleLike}
                                className={`p-2 border rounded-full transition-all flex items-center gap-2 px-4 ${isLiked ? 'bg-pink-50 border-pink-200 text-pink-500' : 'hover:bg-gray-50 text-gray-600'
                                    }`}
                            >
                                <Heart className={`w-5 h-5 ${isLiked ? 'fill-current' : ''}`} />
                                <span className="font-bold">{likeCount}</span>
                            </button>
                            <button
                                onClick={handleShare}
                                className="p-2 border rounded-full hover:bg-gray-50 text-gray-600"
                            >
                                <Share2 className="w-5 h-5" />
                            </button>
                            <a
                                href={`https://www.google.com/maps/dir/?api=1&destination=${shelter.lat},${shelter.lng}`}
                                target="_blank"
                                rel="noopener noreferrer"
                            >
                                <ThaiButton className="bg-blue-600 hover:bg-blue-700">
                                    <Navigation className="w-4 h-4 mr-2" />
                                    นำทาง
                                </ThaiButton>
                            </a>
                        </div>
                    </div>

                    <div className="grid md:grid-cols-3 gap-8">
                        {/* Main Content */}
                        <div className="md:col-span-2 space-y-8">
                            <section>
                                <h2 className="text-xl font-bold text-gray-900 mb-3">เกี่ยวกับศูนย์พักพิง</h2>
                                <p className="text-gray-600 leading-relaxed whitespace-pre-wrap">
                                    {shelter.description || "ไม่มีรายละเอียดเพิ่มเติม"}
                                </p>
                            </section>

                            <section>
                                <h2 className="text-xl font-bold text-gray-900 mb-3">จำนวนสัตว์เลี้ยงที่ดูแล</h2>
                                <div className="grid grid-cols-2 gap-4">
                                    <div className="bg-orange-50 p-4 rounded-xl flex items-center gap-3">
                                        <div className="bg-orange-100 p-2 rounded-full text-orange-600">
                                            <Dog className="w-6 h-6" />
                                        </div>
                                        <div>
                                            <p className="text-sm text-gray-500">สุนัข</p>
                                            <p className="text-xl font-bold text-gray-900">{shelter.pet_count_dog || 0} ตัว</p>
                                        </div>
                                    </div>
                                    <div className="bg-blue-50 p-4 rounded-xl flex items-center gap-3">
                                        <div className="bg-blue-100 p-2 rounded-full text-blue-600">
                                            <Cat className="w-6 h-6" />
                                        </div>
                                        <div>
                                            <p className="text-sm text-gray-500">แมว</p>
                                            <p className="text-xl font-bold text-gray-900">{shelter.pet_count_cat || 0} ตัว</p>
                                        </div>
                                    </div>
                                </div>
                            </section>

                            {shelter.images && shelter.images.length > 1 && (
                                <section>
                                    <h2 className="text-xl font-bold text-gray-900 mb-3">รูปภาพเพิ่มเติม</h2>
                                    <div className="grid grid-cols-2 md:grid-cols-3 gap-2">
                                        {shelter.images.slice(1).map((img: string, idx: number) => (
                                            <div key={idx} className="aspect-square rounded-lg overflow-hidden bg-gray-100">
                                                <img src={img} alt={`Gallery ${idx}`} className="w-full h-full object-cover hover:scale-105 transition-transform" />
                                            </div>
                                        ))}
                                    </div>
                                </section>
                            )}

                            {/* Comments Section */}
                            <section className="pt-8 border-t border-gray-100">
                                <h2 className="text-xl font-bold text-gray-900 mb-6">ความคิดเห็น ({comments.length})</h2>

                                {user ? (
                                    <form onSubmit={handleComment} className="mb-8">
                                        <div className="flex gap-3">
                                            <div className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center flex-shrink-0">
                                                <User className="w-6 h-6 text-gray-500" />
                                            </div>
                                            <div className="flex-1 space-y-3">
                                                <div className="relative">
                                                    <input
                                                        type="text"
                                                        value={newComment}
                                                        onChange={(e) => setNewComment(e.target.value)}
                                                        placeholder="เขียนความคิดเห็น..."
                                                        className="w-full pl-4 pr-12 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-orange-500 outline-none transition-all"
                                                    />
                                                    <div className="absolute right-2 top-1/2 -translate-y-1/2 flex items-center gap-1">
                                                        <input
                                                            type="file"
                                                            accept="image/*"
                                                            id="comment-image"
                                                            className="hidden"
                                                            onChange={handleImageSelect}
                                                        />
                                                        <label
                                                            htmlFor="comment-image"
                                                            className="p-2 text-gray-400 hover:text-orange-500 hover:bg-orange-50 rounded-lg cursor-pointer transition-colors"
                                                        >
                                                            <ImageIcon className="w-5 h-5" />
                                                        </label>
                                                        <button
                                                            type="submit"
                                                            disabled={(!newComment.trim() && !commentImage) || commentLoading}
                                                            className="p-2 text-orange-500 hover:bg-orange-50 rounded-lg disabled:opacity-50 transition-colors"
                                                        >
                                                            <Send className="w-5 h-5" />
                                                        </button>
                                                    </div>
                                                </div>

                                                {commentImagePreview && (
                                                    <div className="relative inline-block">
                                                        <img
                                                            src={commentImagePreview}
                                                            alt="Preview"
                                                            className="h-24 w-auto rounded-lg border border-gray-200"
                                                        />
                                                        <button
                                                            type="button"
                                                            onClick={removeImage}
                                                            className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1 hover:bg-red-600 transition-colors"
                                                        >
                                                            <div className="w-3 h-3 flex items-center justify-center">×</div>
                                                        </button>
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                    </form>
                                ) : (
                                    <div className="bg-gray-50 p-4 rounded-xl text-center text-gray-500 mb-8">
                                        กรุณาเข้าสู่ระบบเพื่อแสดงความคิดเห็น
                                    </div>
                                )}

                                <div className="space-y-6">
                                    {comments.map((comment) => (
                                        <div key={comment.id} className="flex gap-3 group">
                                            <div className="w-10 h-10 rounded-full bg-gray-100 flex items-center justify-center flex-shrink-0">
                                                <User className="w-5 h-5 text-gray-400" />
                                            </div>
                                            <div className="flex-1">
                                                <div className="bg-gray-50 p-3 rounded-2xl rounded-tl-none relative group">
                                                    <div className="flex justify-between items-start">
                                                        <p className="text-xs text-gray-500 mb-1">
                                                            {new Date(comment.created_at).toLocaleString('th-TH')}
                                                        </p>
                                                        {user && user.uid === comment.user_id && (
                                                            <button
                                                                onClick={() => handleDeleteComment(comment.id)}
                                                                className="text-gray-400 hover:text-red-500 p-1 opacity-0 group-hover:opacity-100 transition-opacity"
                                                                title="ลบความคิดเห็น"
                                                            >
                                                                <Trash2 className="w-4 h-4" />
                                                            </button>
                                                        )}
                                                    </div>
                                                    <p className="text-gray-800 whitespace-pre-wrap">{comment.content}</p>
                                                    {comment.image_url && (
                                                        <div className="mt-2">
                                                            <img
                                                                src={comment.image_url}
                                                                alt="Comment attachment"
                                                                className="max-h-48 rounded-lg border border-gray-200"
                                                            />
                                                        </div>
                                                    )}
                                                </div>
                                            </div>
                                        </div>
                                    ))}
                                    {comments.length === 0 && (
                                        <p className="text-center text-gray-400 py-4">ยังไม่มีความคิดเห็น เป็นคนแรกที่แสดงความคิดเห็น!</p>
                                    )}
                                </div>
                            </section>
                        </div>

                        {/* Sidebar */}
                        <div className="space-y-6">
                            <div className="bg-gray-50 rounded-xl p-5 border border-gray-100">
                                <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
                                    <Gift className="w-5 h-5 text-green-600" />
                                    ต้องการรับบริจาค
                                </h3>
                                <div className="space-y-4">
                                    <div>
                                        <p className="text-sm font-medium text-gray-700 mb-1">สิ่งของที่ต้องการ:</p>
                                        <p className="text-sm text-gray-600 bg-white p-3 rounded-lg border border-gray-200">
                                            {shelter.needed_items || "-"}
                                        </p>
                                    </div>
                                    <div>
                                        <p className="text-sm font-medium text-gray-700 mb-1">ที่อยู่จัดส่ง:</p>
                                        <p className="text-sm text-gray-600 bg-white p-3 rounded-lg border border-gray-200">
                                            {shelter.donation_address || "-"}
                                        </p>
                                    </div>
                                </div>
                            </div>

                            <div className="bg-gray-50 rounded-xl p-5 border border-gray-100">
                                <h3 className="font-bold text-gray-900 mb-4 flex items-center gap-2">
                                    <Phone className="w-5 h-5 text-blue-600" />
                                    ข้อมูลติดต่อ
                                </h3>
                                <p className="text-sm text-gray-600 bg-white p-3 rounded-lg border border-gray-200">
                                    {shelter.contact_info || "-"}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
