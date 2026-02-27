"use client";

import React, { createContext, useContext, useState, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { CheckCircle2, AlertCircle, AlertTriangle, Info, X } from "lucide-react";

type ToastType = "success" | "error" | "warning" | "info";

interface Toast {
    id: string;
    message: string;
    type: ToastType;
    duration?: number;
}

interface ToastContextValue {
    toast: (message: string, type?: ToastType, duration?: number) => void;
    toastSuccess: (message: string) => void;
    toastError: (message: string) => void;
    toastWarning: (message: string) => void;
    toastInfo: (message: string) => void;
}

const ToastContext = createContext<ToastContextValue | null>(null);

export function useToast(): ToastContextValue {
    const ctx = useContext(ToastContext);
    if (!ctx) throw new Error("useToast must be used within <ToastProvider>");
    return ctx;
}

const ICONS: Record<ToastType, React.ReactNode> = {
    success: <CheckCircle2 className="w-5 h-5 text-green-500 flex-shrink-0" />,
    error: <AlertCircle className="w-5 h-5 text-red-500 flex-shrink-0" />,
    warning: <AlertTriangle className="w-5 h-5 text-amber-500 flex-shrink-0" />,
    info: <Info className="w-5 h-5 text-blue-500 flex-shrink-0" />,
};

const BG: Record<ToastType, string> = {
    success: "bg-green-50 border-green-200 dark:bg-green-950/80 dark:border-green-800",
    error: "bg-red-50 border-red-200 dark:bg-red-950/80 dark:border-red-800",
    warning: "bg-amber-50 border-amber-200 dark:bg-amber-950/80 dark:border-amber-800",
    info: "bg-blue-50 border-blue-200 dark:bg-blue-950/80 dark:border-blue-800",
};

const TEXT: Record<ToastType, string> = {
    success: "text-green-900 dark:text-green-100",
    error: "text-red-900 dark:text-red-100",
    warning: "text-amber-900 dark:text-amber-100",
    info: "text-blue-900 dark:text-blue-100",
};

export function ToastProvider({ children }: { children: React.ReactNode }) {
    const [toasts, setToasts] = useState<Toast[]>([]);

    const removeToast = useCallback((id: string) => {
        setToasts((prev) => prev.filter((t) => t.id !== id));
    }, []);

    const addToast = useCallback(
        (message: string, type: ToastType = "info", duration: number = 4000) => {
            const id = `${Date.now()}-${Math.random().toString(36).slice(2)}`;
            setToasts((prev) => [...prev, { id, message, type, duration }]);
            if (duration > 0) {
                setTimeout(() => removeToast(id), duration);
            }
        },
        [removeToast]
    );

    const value: ToastContextValue = {
        toast: addToast,
        toastSuccess: useCallback((m: string) => addToast(m, "success"), [addToast]),
        toastError: useCallback((m: string) => addToast(m, "error", 6000), [addToast]),
        toastWarning: useCallback((m: string) => addToast(m, "warning", 5000), [addToast]),
        toastInfo: useCallback((m: string) => addToast(m, "info"), [addToast]),
    };

    return (
        <ToastContext.Provider value={value}>
            {children}

            {/* Toast Container */}
            <div className="fixed top-4 right-4 left-4 sm:left-auto sm:w-96 z-[9999] flex flex-col gap-2 pointer-events-none">
                <AnimatePresence mode="popLayout">
                    {toasts.map((t) => (
                        <motion.div
                            key={t.id}
                            layout
                            initial={{ opacity: 0, y: -20, scale: 0.95 }}
                            animate={{ opacity: 1, y: 0, scale: 1 }}
                            exit={{ opacity: 0, y: -10, scale: 0.95 }}
                            transition={{ type: "spring", stiffness: 400, damping: 30 }}
                            className={`pointer-events-auto rounded-xl border px-4 py-3 shadow-lg backdrop-blur-sm flex items-start gap-3 ${BG[t.type]}`}
                        >
                            {ICONS[t.type]}
                            <p className={`text-sm font-medium flex-1 leading-relaxed whitespace-pre-line ${TEXT[t.type]}`}>
                                {t.message}
                            </p>
                            <button
                                onClick={() => removeToast(t.id)}
                                className="flex-shrink-0 p-0.5 rounded-full hover:bg-black/10 dark:hover:bg-white/10 transition-colors"
                            >
                                <X className="w-4 h-4 opacity-50" />
                            </button>
                        </motion.div>
                    ))}
                </AnimatePresence>
            </div>
        </ToastContext.Provider>
    );
}
