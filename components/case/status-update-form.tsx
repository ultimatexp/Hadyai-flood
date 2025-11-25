"use client";

import { ThaiButton } from "@/components/ui/thai-button";
import { supabase } from "@/lib/supabase";
import { CheckCircle2, XCircle, Truck, MapPin, AlertCircle } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";

interface StatusUpdateFormProps {
    caseData: any;
    token: string;
}

export default function StatusUpdateForm({ caseData, token }: StatusUpdateFormProps) {
    const router = useRouter();
    const [loading, setLoading] = useState(false);

    const updateStatus = async (status: string) => {
        if (!confirm(`ยืนยันเปลี่ยนสถานะเป็น "${status}"?`)) return;

        setLoading(true);
        const { error } = await supabase
            .from("sos_cases")
            .update({ status })
            .eq("id", caseData.id)
            .eq("edit_token", token); // Double check token

        if (error) {
            alert("เกิดข้อผิดพลาด: " + error.message);
        } else {
            alert("อัปเดตสถานะเรียบร้อย");
            router.refresh();
            router.push(`/case/${caseData.id}`);
        }
        setLoading(false);
    };

    const actions = [
        { label: "กำลังเดินทาง", status: "ACKNOWLEDGED", icon: Truck, color: "bg-purple-600 hover:bg-purple-700" },
        { label: "ถึงที่เกิดเหตุ", status: "IN_PROGRESS", icon: MapPin, color: "bg-blue-600 hover:bg-blue-700" },
        { label: "ช่วยเหลือเสร็จสิ้น", status: "RESOLVED", icon: CheckCircle2, color: "bg-green-600 hover:bg-green-700" },
        { label: "ยกเลิก / ข้อมูลผิด", status: "CLOSED", icon: XCircle, color: "bg-gray-600 hover:bg-gray-700" },
    ];

    return (
        <div className="space-y-6 p-4">
            <div className="text-center space-y-2">
                <h2 className="text-2xl font-bold">อัปเดตสถานะเคส</h2>
                <p className="text-muted-foreground">สำหรับผู้แจ้งเหตุหรืออาสาที่มีลิงก์นี้</p>
            </div>

            <div className="bg-card border rounded-xl p-4 space-y-2">
                <h3 className="font-semibold">ข้อมูลเคส</h3>
                <p>ผู้แจ้ง: {caseData.reporter_name}</p>
                <p>สถานะปัจจุบัน: <span className="font-bold">{caseData.status}</span></p>
            </div>

            <div className="grid gap-4">
                {actions.map((action) => (
                    <ThaiButton
                        key={action.status}
                        className={`w-full justify-start h-16 text-lg ${action.color}`}
                        onClick={() => updateStatus(action.status)}
                        isLoading={loading}
                    >
                        <action.icon className="mr-3 w-6 h-6" />
                        {action.label}
                    </ThaiButton>
                ))}
            </div>
        </div>
    );
}
