"use client";

import * as React from "react";
import { createPortal } from "react-dom";
import { X } from "lucide-react";
import { cn } from "@/lib/utils";

const DialogContext = React.createContext<{
    open: boolean;
    setOpen: (open: boolean) => void;
}>({
    open: false,
    setOpen: () => { },
});

export const Dialog = ({ children }: { children: React.ReactNode }) => {
    const [open, setOpen] = React.useState(false);
    return (
        <DialogContext.Provider value={{ open, setOpen }}>
            {children}
        </DialogContext.Provider>
    );
};

export const DialogTrigger = ({
    children,
    asChild,
}: {
    children: React.ReactNode;
    asChild?: boolean;
}) => {
    const { setOpen } = React.useContext(DialogContext);

    if (asChild && React.isValidElement(children)) {
        return React.cloneElement(children as React.ReactElement<any>, {
            onClick: (e: React.MouseEvent) => {
                children.props.onClick?.(e);
                setOpen(true);
            },
        });
    }

    return (
        <button onClick={() => setOpen(true)}>{children}</button>
    );
};

export const DialogContent = ({
    children,
    className,
}: {
    children: React.ReactNode;
    className?: string;
}) => {
    const { open, setOpen } = React.useContext(DialogContext);
    const [mounted, setMounted] = React.useState(false);

    React.useEffect(() => {
        setMounted(true);
        return () => setMounted(false);
    }, []);

    if (!open || !mounted) return null;

    return createPortal(
        <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4">
            {/* Overlay */}
            <div
                className="fixed inset-0 bg-black/50 backdrop-blur-sm animate-in fade-in duration-200"
                onClick={() => setOpen(false)}
            />

            {/* Content */}
            <div className={cn(
                "relative z-[10000] w-full bg-background p-6 shadow-lg rounded-xl animate-in zoom-in-95 duration-200 max-h-[85vh] overflow-y-auto",
                className
            )}>
                <button
                    className="absolute right-4 top-4 rounded-sm opacity-70 ring-offset-background transition-opacity hover:opacity-100 focus:outline-none disabled:pointer-events-none data-[state=open]:bg-accent data-[state=open]:text-muted-foreground"
                    onClick={() => setOpen(false)}
                >
                    <X className="h-4 w-4" />
                    <span className="sr-only">Close</span>
                </button>
                {children}
            </div>
        </div>,
        document.body
    );
};

export const DialogHeader = ({
    className,
    ...props
}: React.HTMLAttributes<HTMLDivElement>) => (
    <div
        className={cn(
            "flex flex-col space-y-1.5 text-center sm:text-left",
            className
        )}
        {...props}
    />
);

export const DialogTitle = ({
    className,
    ...props
}: React.HTMLAttributes<HTMLHeadingElement>) => (
    <h2
        className={cn(
            "text-lg font-semibold leading-none tracking-tight",
            className
        )}
        {...props}
    />
);

export const DialogDescription = ({
    className,
    ...props
}: React.HTMLAttributes<HTMLParagraphElement>) => (
    <p
        className={cn("text-sm text-muted-foreground", className)}
        {...props}
    />
);
