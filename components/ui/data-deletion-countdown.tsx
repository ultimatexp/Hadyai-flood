"use client";

import { useState, useEffect } from "react";

export function DataDeletionCountdown() {
    const [timeLeft, setTimeLeft] = useState<{
        days: number;
        hours: number;
        minutes: number;
        seconds: number;
    }>({ days: 0, hours: 0, minutes: 0, seconds: 0 });

    useEffect(() => {
        const calculateTimeLeft = () => {
            const targetDate = new Date("2026-01-01T00:00:00+07:00");
            const now = new Date();
            const difference = targetDate.getTime() - now.getTime();

            if (difference > 0) {
                return {
                    days: Math.floor(difference / (1000 * 60 * 60 * 24)),
                    hours: Math.floor((difference / (1000 * 60 * 60)) % 24),
                    minutes: Math.floor((difference / 1000 / 60) % 60),
                    seconds: Math.floor((difference / 1000) % 60),
                };
            }

            return { days: 0, hours: 0, minutes: 0, seconds: 0 };
        };

        setTimeLeft(calculateTimeLeft());

        const timer = setInterval(() => {
            setTimeLeft(calculateTimeLeft());
        }, 1000);

        return () => clearInterval(timer);
    }, []);

    return (
        <div className="text-sm text-muted-foreground pt-8 font-medium bg-white/50 dark:bg-black/50 p-4 rounded-lg backdrop-blur-sm inline-block">
            <p className="mb-2">เพื่อความปลอดภัยของข้อมูลส่วนตัว</p>
            <p className="mb-3">ข้อมูลทั้งหมดจะถูกลบใน</p>
            <div className="flex gap-3 justify-center items-center font-mono text-lg font-bold">
                <div className="flex flex-col items-center bg-primary/10 rounded-lg px-3 py-2 min-w-[60px]">
                    <span className="text-2xl text-primary">{timeLeft.days}</span>
                    <span className="text-xs text-muted-foreground">วัน</span>
                </div>
                <span className="text-xl">:</span>
                <div className="flex flex-col items-center bg-primary/10 rounded-lg px-3 py-2 min-w-[60px]">
                    <span className="text-2xl text-primary">{timeLeft.hours}</span>
                    <span className="text-xs text-muted-foreground">ชม.</span>
                </div>
                <span className="text-xl">:</span>
                <div className="flex flex-col items-center bg-primary/10 rounded-lg px-3 py-2 min-w-[60px]">
                    <span className="text-2xl text-primary">{timeLeft.minutes}</span>
                    <span className="text-xs text-muted-foreground">นาที</span>
                </div>
                <span className="text-xl">:</span>
                <div className="flex flex-col items-center bg-primary/10 rounded-lg px-3 py-2 min-w-[60px]">
                    <span className="text-2xl text-primary">{timeLeft.seconds}</span>
                    <span className="text-xs text-muted-foreground">วิ.</span>
                </div>
            </div>
        </div>
    );
}
