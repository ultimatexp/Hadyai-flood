import { useState, useEffect, useRef } from "react";
import { addComment, getComments } from "@/app/actions/chat";
import { ThaiButton } from "@/components/ui/thai-button";
import { Send, User, Image as ImageIcon, X } from "lucide-react";
import { formatDistanceToNow } from "date-fns";
import { th } from "date-fns/locale";
import { supabase } from "@/lib/supabase";
import Image from "next/image";

interface Comment {
    id: string;
    message: string;
    sender_role: 'volunteer' | 'member';
    created_at: string;
    user_id: string;
    image_url?: string;
    users?: {
        name: string;
    };
}

interface CaseCommentsProps {
    caseId: string;
    userId: string;
    role: 'volunteer' | 'member';
}

export default function CaseComments({ caseId, userId, role }: CaseCommentsProps) {
    const [comments, setComments] = useState<Comment[]>([]);
    const [newMessage, setNewMessage] = useState("");
    const [loading, setLoading] = useState(false);
    const [selectedImage, setSelectedImage] = useState<File | null>(null);
    const [imagePreview, setImagePreview] = useState<string | null>(null);
    const messagesEndRef = useRef<HTMLDivElement>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);

    const fetchComments = async () => {
        const result = await getComments(caseId);
        if (result.success && result.data) {
            setComments(result.data as any);
        }
    };

    useEffect(() => {
        fetchComments();

        // Subscribe to realtime changes
        const channel = supabase
            .channel(`comments-${caseId}`)
            .on(
                'postgres_changes',
                {
                    event: 'INSERT',
                    schema: 'public',
                    table: 'case_comments',
                    filter: `case_id=eq.${caseId}`
                },
                (payload) => {
                    fetchComments();
                }
            )
            .subscribe();

        return () => {
            supabase.removeChannel(channel);
        };
    }, [caseId]);

    useEffect(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    }, [comments]);

    const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            if (file.size > 5 * 1024 * 1024) { // 5MB limit
                alert("ขนาดไฟล์ต้องไม่เกิน 5MB");
                return;
            }
            setSelectedImage(file);
            const reader = new FileReader();
            reader.onloadend = () => {
                setImagePreview(reader.result as string);
            };
            reader.readAsDataURL(file);
        }
    };

    const clearImage = () => {
        setSelectedImage(null);
        setImagePreview(null);
        if (fileInputRef.current) fileInputRef.current.value = "";
    };

    const handleSend = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!newMessage.trim() && !selectedImage) return;

        setLoading(true);
        const message = newMessage.trim();
        let imageUrl = undefined;

        try {
            // Upload image if selected
            if (selectedImage) {
                const fileExt = selectedImage.name.split('.').pop();
                const fileName = `chat/${caseId}/${Date.now()}.${fileExt}`;

                const { error: uploadError } = await supabase.storage
                    .from('sos-photos')
                    .upload(fileName, selectedImage);

                if (uploadError) throw uploadError;

                const { data: { publicUrl } } = supabase.storage
                    .from('sos-photos')
                    .getPublicUrl(fileName);

                imageUrl = publicUrl;
            }

            // Optimistic clear
            setNewMessage("");
            clearImage();

            const result = await addComment(caseId, userId, message, role, imageUrl);
            if (!result.success) {
                alert("ส่งข้อความไม่สำเร็จ");
                setNewMessage(message); // Restore if failed
            }
        } catch (error) {
            console.error("Error sending message:", error);
            alert("เกิดข้อผิดพลาดในการส่งข้อความ");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="bg-white rounded-xl border shadow-sm overflow-hidden flex flex-col h-[500px]">
            <div className="p-3 border-b bg-gray-50 font-medium text-gray-700 flex items-center gap-2">
                <div className="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                แชทกับ{role === 'volunteer' ? 'ญาติผู้ป่วย' : 'อาสา/เจ้าหน้าที่'}
            </div>

            <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-gray-50/50">
                {comments.length === 0 && (
                    <div className="text-center text-gray-400 text-sm py-10">
                        ยังไม่มีข้อความ เริ่มต้นสนทนาได้เลย
                    </div>
                )}
                {comments.map((comment) => {
                    const isMe = comment.sender_role === role;
                    return (
                        <div key={comment.id} className={`flex ${isMe ? 'justify-end' : 'justify-start'}`}>
                            <div className={`max-w-[80%] ${isMe ? 'bg-blue-600 text-white' : 'bg-white border text-gray-800'} rounded-2xl px-4 py-2 shadow-sm`}>
                                {!isMe && (
                                    <p className="text-xs text-gray-400 mb-1">
                                        {comment.sender_role === 'volunteer' ? 'อาสา' : 'ญาติ'} • {comment.users?.name || 'ไม่ระบุชื่อ'}
                                    </p>
                                )}

                                {comment.image_url && (
                                    <div className="mb-2 rounded-lg overflow-hidden relative w-full h-48 bg-black/10">
                                        <Image
                                            src={comment.image_url}
                                            alt="Attached image"
                                            fill
                                            className="object-cover"
                                        />
                                    </div>
                                )}

                                {comment.message && <p className="text-sm">{comment.message}</p>}

                                <p className={`text-[10px] mt-1 ${isMe ? 'text-blue-200' : 'text-gray-400'} text-right`}>
                                    {formatDistanceToNow(new Date(comment.created_at), { locale: th })}
                                </p>
                            </div>
                        </div>
                    );
                })}
                <div ref={messagesEndRef} />
            </div>

            {/* Image Preview */}
            {imagePreview && (
                <div className="px-4 py-2 bg-gray-50 border-t flex items-center gap-2">
                    <div className="relative w-16 h-16 rounded-lg overflow-hidden border">
                        <Image src={imagePreview} alt="Preview" fill className="object-cover" />
                    </div>
                    <div className="flex-1 text-xs text-gray-500 truncate">
                        {selectedImage?.name}
                    </div>
                    <button onClick={clearImage} className="p-1 hover:bg-gray-200 rounded-full">
                        <X className="w-4 h-4 text-gray-500" />
                    </button>
                </div>
            )}

            <form onSubmit={handleSend} className="p-3 bg-white border-t flex gap-2 items-end">
                <input
                    type="file"
                    ref={fileInputRef}
                    accept="image/*"
                    className="hidden"
                    onChange={handleImageSelect}
                />
                <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    className="p-2 text-gray-500 hover:bg-gray-100 rounded-full transition-colors"
                    disabled={loading}
                >
                    <ImageIcon className="w-5 h-5" />
                </button>

                <input
                    type="text"
                    value={newMessage}
                    onChange={(e) => setNewMessage(e.target.value)}
                    placeholder="พิมพ์ข้อความ..."
                    className="flex-1 px-4 py-2 rounded-full border border-gray-200 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500 text-sm"
                    disabled={loading}
                />
                <button
                    type="submit"
                    disabled={loading || (!newMessage.trim() && !selectedImage)}
                    className="p-2 bg-blue-600 text-white rounded-full hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                    <Send className="w-5 h-5" />
                </button>
            </form>
        </div>
    );
}
