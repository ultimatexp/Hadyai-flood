"use client";

import { cn } from "@/lib/utils";
import { Camera, X } from "lucide-react";
import Image from "next/image";
import React, { useRef } from "react";

interface PhotoUploaderProps {
    files: File[];
    onFilesChange: (files: File[]) => void;
}

export const PhotoUploader: React.FC<PhotoUploaderProps> = ({ files, onFilesChange }) => {
    const inputRef = useRef<HTMLInputElement>(null);

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files) {
            const newFiles = Array.from(e.target.files);
            onFilesChange([...files, ...newFiles]);
        }
    };

    const removeFile = (index: number) => {
        const newFiles = [...files];
        newFiles.splice(index, 1);
        onFilesChange(newFiles);
    };

    return (
        <div className="space-y-4">
            <div className="grid grid-cols-3 gap-4">
                {files.map((file, index) => (
                    <div key={index} className="relative aspect-square rounded-xl overflow-hidden border border-border bg-muted">
                        <Image
                            src={URL.createObjectURL(file)}
                            alt="Preview"
                            fill
                            className="object-cover"
                        />
                        <button
                            type="button"
                            onClick={() => removeFile(index)}
                            className="absolute top-1 right-1 p-1 bg-black/50 rounded-full text-white hover:bg-red-500 transition-colors"
                        >
                            <X className="w-4 h-4" />
                        </button>
                    </div>
                ))}

                <button
                    type="button"
                    onClick={() => inputRef.current?.click()}
                    className="aspect-square rounded-xl border-2 border-dashed border-border flex flex-col items-center justify-center text-muted-foreground hover:border-primary hover:text-primary hover:bg-primary/5 transition-all"
                >
                    <Camera className="w-8 h-8 mb-2" />
                    <span className="text-xs">เพิ่มรูป</span>
                </button>
            </div>

            <input
                ref={inputRef}
                type="file"
                accept="image/*"
                multiple
                className="hidden"
                onChange={handleFileChange}
            />
        </div>
    );
};
