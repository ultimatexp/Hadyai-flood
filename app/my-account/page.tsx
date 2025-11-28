"use client";

import { useState, useEffect } from "react";
import { onAuthStateChanged } from "firebase/auth";
import { auth } from "@/lib/firebase";
import { useRouter } from "next/navigation";
import { getUserPets, getUserNotifications, getUserChats, markNotificationRead } from "@/app/actions/account";
import { getEnrolledCases } from "@/app/actions/family";
import { Loader2, User, PawPrint, Mail, MessageCircle, MapPin, Calendar, Bell, ChevronRight, LogOut } from "lucide-react";
import { ThaiButton } from "@/components/ui/thai-button";
import Link from "next/link";
import { format } from "date-fns";
import { th } from "date-fns/locale";

export default function MyAccountPage() {
    const router = useRouter();
    const [user, setUser] = useState<any>(null);
    const [loading, setLoading] = useState(true);
    const [activeTab, setActiveTab] = useState<'family' | 'pets' | 'mail' | 'chat'>('family');

    // Data states
    const [familyCases, setFamilyCases] = useState<any[]>([]);
    const [myPets, setMyPets] = useState<any[]>([]);
    const [notifications, setNotifications] = useState<any[]>([]);
    const [chats, setChats] = useState<any[]>([]);

    useEffect(() => {
        const unsubscribe = onAuthStateChanged(auth, async (currentUser) => {
            if (!currentUser) {
                router.push("/login?redirect=/my-account");
            } else {
                setUser(currentUser);
                await fetchAllData(currentUser.uid);
            }
            setLoading(false);
        });
        return () => unsubscribe();
    }, []);

    const fetchAllData = async (userId: string) => {
        // Parallel fetch
        const [familyRes, petsRes, notifRes, chatsRes] = await Promise.all([
            getEnrolledCases(userId),
            getUserPets(userId),
            getUserNotifications(userId),
            getUserChats(userId)
        ]);

        if (familyRes.success) setFamilyCases(familyRes.data || []);
        if (petsRes.success) setMyPets(petsRes.data || []);
        if (notifRes.success) setNotifications(notifRes.data || []);
        if (chatsRes.success) setChats(chatsRes.data || []);
    };

    const handleLogout = async () => {
        await auth.signOut();
        router.push("/");
    };

    if (loading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-50">
                <Loader2 className="w-8 h-8 animate-spin text-orange-500" />
            </div>
        );
    }

    if (!user) return null;

    return (
        <div className="min-h-screen bg-gray-50 pb-20">
            {/* Header */}
            <div className="bg-white shadow-sm p-6 mb-6">
                <div className="max-w-4xl mx-auto flex items-center justify-between">
                    <div className="flex items-center gap-4">
                        <div className="w-16 h-16 bg-orange-100 rounded-full flex items-center justify-center text-orange-600 text-2xl font-bold">
                            {user.email?.[0]?.toUpperCase() || "U"}
                        </div>
                        <div>
                            <h1 className="text-2xl font-bold text-gray-900">บัญชีของฉัน</h1>
                            <p className="text-gray-500">{user.email}</p>
                        </div>
                    </div>
                    <button
                        onClick={handleLogout}
                        className="text-red-500 hover:bg-red-50 p-2 rounded-lg transition-colors flex items-center gap-2"
                    >
                        <LogOut className="w-5 h-5" />
                        <span className="hidden md:inline">ออกจากระบบ</span>
                    </button>
                </div>
            </div>

            <div className="max-w-4xl mx-auto px-4">
                {/* Tabs */}
                <div className="flex overflow-x-auto gap-2 mb-6 pb-2 scrollbar-hide">
                    <TabButton
                        active={activeTab === 'family'}
                        onClick={() => setActiveTab('family')}
                        icon={User}
                        label="ครอบครัวที่ดูแล"
                        count={familyCases.length}
                    />
                    <TabButton
                        active={activeTab === 'pets'}
                        onClick={() => setActiveTab('pets')}
                        icon={PawPrint}
                        label="สัตว์เลี้ยงของฉัน"
                        count={myPets.length}
                    />
                    <TabButton
                        active={activeTab === 'mail'}
                        onClick={() => setActiveTab('mail')}
                        icon={Mail}
                        label="กล่องข้อความ"
                        count={notifications.filter(n => !n.is_read).length}
                        badge
                    />
                    <TabButton
                        active={activeTab === 'chat'}
                        onClick={() => setActiveTab('chat')}
                        icon={MessageCircle}
                        label="การสนทนา"
                        count={chats.length}
                    />
                </div>

                {/* Content */}
                <div className="space-y-4">
                    {activeTab === 'family' && (
                        <FamilySection cases={familyCases} />
                    )}
                    {activeTab === 'pets' && (
                        <PetsSection pets={myPets} />
                    )}
                    {activeTab === 'mail' && (
                        <MailboxSection notifications={notifications} onRead={fetchAllData} userId={user.uid} />
                    )}
                    {activeTab === 'chat' && (
                        <ChatSection chats={chats} />
                    )}
                </div>
            </div>
        </div>
    );
}

function TabButton({ active, onClick, icon: Icon, label, count, badge }: any) {
    return (
        <button
            onClick={onClick}
            className={`flex items-center gap-2 px-4 py-3 rounded-xl font-bold whitespace-nowrap transition-all ${active
                ? "bg-orange-500 text-white shadow-lg shadow-orange-200"
                : "bg-white text-gray-600 hover:bg-gray-50 border border-gray-100"
                }`}
        >
            <Icon className="w-5 h-5" />
            {label}
            {count > 0 && (
                <span className={`ml-1 text-xs px-2 py-0.5 rounded-full ${active ? "bg-white/20 text-white" : badge ? "bg-red-500 text-white" : "bg-gray-100 text-gray-600"
                    }`}>
                    {count}
                </span>
            )}
        </button>
    );
}

function FamilySection({ cases }: { cases: any[] }) {
    if (cases.length === 0) {
        return <EmptyState icon={User} message="ยังไม่มีครอบครัวที่ดูแล" subMessage="คุณสามารถเข้าร่วมดูแลครอบครัวได้ผ่านลิงก์คำเชิญ" />;
    }

    return (
        <div className="grid gap-4 md:grid-cols-2">
            {cases.map((c) => (
                <Link href={`/case/${c.id}/family?token=${c.family_token}`} key={c.id}>
                    <div className="bg-white p-5 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-all">
                        <div className="flex justify-between items-start mb-3">
                            <h3 className="font-bold text-lg text-gray-900">{c.reporter_name}</h3>
                            <span className={`px-2 py-1 rounded-lg text-xs font-bold ${c.status === 'RESOLVED' ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'
                                }`}>
                                {c.status}
                            </span>
                        </div>
                        <p className="text-sm text-gray-500 mb-4 flex items-center gap-1">
                            <Calendar className="w-4 h-4" />
                            เข้าร่วมเมื่อ {format(new Date(c.created_at), "d MMM yyyy", { locale: th })}
                        </p>
                        <div className="text-orange-500 text-sm font-bold flex items-center gap-1">
                            ดูรายละเอียด <ChevronRight className="w-4 h-4" />
                        </div>
                    </div>
                </Link>
            ))}
        </div>
    );
}

function PetsSection({ pets }: { pets: any[] }) {
    if (pets.length === 0) {
        return (
            <div className="text-center py-10">
                <EmptyState icon={PawPrint} message="ยังไม่มีรายการสัตว์เลี้ยง" subMessage="คุณยังไม่ได้แจ้งสัตว์หาย" />
                <Link href="/find-pet">
                    <ThaiButton className="mt-4 bg-orange-500">แจ้งสัตว์หาย</ThaiButton>
                </Link>
            </div>
        );
    }

    return (
        <div className="grid gap-4 md:grid-cols-2">
            {pets.map((pet) => (
                <Link href={`/pets/status/${pet.id}`} key={pet.id}>
                    <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden hover:shadow-md transition-all flex">
                        <div className="w-32 h-32 bg-gray-100 relative shrink-0">
                            <img src={pet.image_url} alt={pet.pet_name} className="w-full h-full object-cover" />
                        </div>
                        <div className="p-4 flex-1">
                            <h3 className="font-bold text-lg text-gray-900 mb-1">{pet.pet_name}</h3>
                            <p className="text-sm text-gray-500 mb-2">{pet.breed} • {pet.color}</p>
                            <span className={`px-2 py-1 rounded-lg text-xs font-bold ${pet.status === 'REUNITED' ? 'bg-green-100 text-green-700' :
                                pet.status === 'FOUND' ? 'bg-yellow-100 text-yellow-700' : 'bg-red-100 text-red-700'
                                }`}>
                                {pet.status === 'REUNITED' ? 'พบแล้ว' : pet.status === 'FOUND' ? 'พบเบาะแส' : 'กำลังตามหา'}
                            </span>
                        </div>
                    </div>
                </Link>
            ))}
        </div>
    );
}

function MailboxSection({ notifications, onRead, userId }: any) {
    const router = useRouter();

    if (notifications.length === 0) {
        return <EmptyState icon={Bell} message="ไม่มีการแจ้งเตือน" subMessage="คุณจะได้รับการแจ้งเตือนเมื่อมีความคืบหน้า" />;
    }

    const handleRead = async (n: any) => {
        if (!n.is_read) {
            await markNotificationRead(n.id);
            onRead(userId);
        }

        // Navigate based on type
        if (n.type === 'PET_MATCH') {
            router.push(`/pets/status/${n.data.found_pet_id}`); // Or lost_pet_id depending on context, assuming found_pet_id is the one to check
        }
    };

    return (
        <div className="space-y-3">
            {notifications.map((n: any) => (
                <div
                    key={n.id}
                    onClick={() => handleRead(n)}
                    className={`bg-white p-4 rounded-xl border cursor-pointer transition-all ${n.is_read ? "border-gray-100 opacity-70" : "border-orange-200 shadow-sm bg-orange-50/30"
                        }`}
                >
                    <div className="flex gap-3">
                        <div className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${n.type === 'PET_MATCH' ? 'bg-green-100 text-green-600' : 'bg-blue-100 text-blue-600'
                            }`}>
                            {n.type === 'PET_MATCH' ? <PawPrint className="w-5 h-5" /> : <Bell className="w-5 h-5" />}
                        </div>
                        <div className="flex-1">
                            <div className="flex justify-between items-start mb-1">
                                <h4 className={`font-bold ${n.is_read ? "text-gray-700" : "text-gray-900"}`}>{n.title}</h4>
                                <span className="text-xs text-gray-400 whitespace-nowrap">
                                    {format(new Date(n.created_at), "d MMM HH:mm", { locale: th })}
                                </span>
                            </div>
                            <p className="text-sm text-gray-600">{n.message}</p>
                        </div>
                        {!n.is_read && (
                            <div className="w-2 h-2 bg-red-500 rounded-full mt-2" />
                        )}
                    </div>
                </div>
            ))}
        </div>
    );
}

function ChatSection({ chats }: { chats: any[] }) {
    if (chats.length === 0) {
        return <EmptyState icon={MessageCircle} message="ยังไม่มีการสนทนา" subMessage="การสนทนาจะปรากฏเมื่อคุณเริ่มคุยกับอาสาหรือเจ้าของสัตว์เลี้ยง" />;
    }

    return (
        <div className="space-y-3">
            {chats.map((chat) => (
                <Link href={chat.link} key={`${chat.type}-${chat.id}`}>
                    <div className="bg-white p-4 rounded-xl shadow-sm border border-gray-100 hover:shadow-md transition-all flex items-center gap-4">
                        <div className="w-12 h-12 bg-gray-100 rounded-full overflow-hidden shrink-0">
                            {chat.image ? (
                                <img src={chat.image} alt="" className="w-full h-full object-cover" />
                            ) : (
                                <div className="w-full h-full flex items-center justify-center bg-blue-100 text-blue-600">
                                    <MessageCircle className="w-6 h-6" />
                                </div>
                            )}
                        </div>
                        <div className="flex-1">
                            <h4 className="font-bold text-gray-900">{chat.title}</h4>
                            <p className="text-sm text-gray-500">{chat.subtitle}</p>
                        </div>
                        <ChevronRight className="w-5 h-5 text-gray-300" />
                    </div>
                </Link>
            ))}
        </div>
    );
}

function EmptyState({ icon: Icon, message, subMessage }: any) {
    return (
        <div className="flex flex-col items-center justify-center py-12 text-center bg-white rounded-xl border border-dashed border-gray-200">
            <div className="w-16 h-16 bg-gray-50 rounded-full flex items-center justify-center mb-4">
                <Icon className="w-8 h-8 text-gray-300" />
            </div>
            <h3 className="text-lg font-bold text-gray-900 mb-1">{message}</h3>
            <p className="text-sm text-gray-500">{subMessage}</p>
        </div>
    );
}
