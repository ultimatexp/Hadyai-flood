"use client";

import { useState, useRef } from "react";
import { detectFaceAndGetDescriptor } from "@/lib/face-api";
import { Search, Upload, Loader2, User } from "lucide-react";
import { ThaiButton } from "@/components/ui/thai-button";
import Image from "next/image";

interface SearchResult {
    photo_id: string;
    image_url: string;
    case_id: string;
    similarity: number;
    uploaded_at?: string;
    uploaded_by?: string;
}

export default function FindPage() {
    const [selectedImage, setSelectedImage] = useState<File | null>(null);
    const [imagePreview, setImagePreview] = useState<string | null>(null);
    const [searching, setSearching] = useState(false);
    const [results, setResults] = useState<SearchResult[]>([]);
    const [error, setError] = useState<string | null>(null);
    const imageRef = useRef<HTMLImageElement>(null);

    const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            if (file.size > 10 * 1024 * 1024) {
                setError("ขนาดไฟล์ต้องไม่เกิน 10MB");
                return;
            }
            setSelectedImage(file);
            setError(null);
            setResults([]);

            const reader = new FileReader();
            reader.onloadend = () => {
                setImagePreview(reader.result as string);
            };
            reader.readAsDataURL(file);
        }
    };

    const handleSearch = async (e: React.FormEvent) => {
        e.preventDefault();

        if (!selectedImage || !imageRef.current) {
            setError("กรุณาเลือกรูปภาพ");
            return;
        }

        setSearching(true);
        setError(null);

        try {
            // Extract face embedding from uploaded image
            const descriptor = await detectFaceAndGetDescriptor(imageRef.current);

            if (!descriptor) {
                setError("ไม่พบใบหน้าในรูปภาพ กรุณาอัพโหลดรูปที่เห็นใบหน้าชัดเจน");
                setSearching(false);
                return;
            }

            // Search for similar faces
            const response = await fetch('/api/search-face', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    embedding: Array.from(descriptor),
                    threshold: 0.6, // 60% similarity threshold
                }),
            });

            const data = await response.json();

            if (!data.success) {
                setError(data.error || "เกิดข้อผิดพลาดในการค้นหา");
                setSearching(false);
                return;
            }

            setResults(data.results || []);
        } catch (err: any) {
            setError(err.message || "เกิดข้อผิดพลาดในการค้นหา");
        } finally {
            setSearching(false);
        }
    };

    return (
        <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white py-8 px-4">
            <div className="max-w-4xl mx-auto">
                <div className="text-center mb-8">
                    <h1 className="text-3xl font-bold text-gray-900 mb-2">ค้นหาผู้ได้รับผลกระทบ</h1>
                    <p className="text-gray-600">อัพโหลดรูปภาพเพื่อค้นหาผู้ได้รับผลกระทบในระบบ</p>
                </div>

                <form onSubmit={handleSearch} className="bg-white rounded-xl shadow-lg p-6 mb-8">
                    <div className="space-y-6">
                        {/* Image Upload */}
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-2">
                                อัพโหลดรูปภาพ
                            </label>
                            <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-blue-500 transition-colors">
                                <input
                                    type="file"
                                    accept="image/*"
                                    onChange={handleImageSelect}
                                    className="hidden"
                                    id="image-upload"
                                />
                                <label htmlFor="image-upload" className="cursor-pointer">
                                    <Upload className="w-12 h-12 mx-auto mb-2 text-gray-400" />
                                    <span className="text-gray-600">คลิกเพื่อเลือกรูปภาพ</span>
                                </label>
                            </div>
                        </div>

                        {/* Image Preview */}
                        {imagePreview && (
                            <div className="relative w-full max-w-md mx-auto">
                                <img
                                    ref={imageRef}
                                    src={imagePreview}
                                    alt="Preview"
                                    className="w-full rounded-lg shadow-md"
                                    crossOrigin="anonymous"
                                />
                            </div>
                        )}

                        {/* Error Message */}
                        {error && (
                            <div className="bg-red-50 border border-red-200 rounded-lg p-4 text-red-700">
                                {error}
                            </div>
                        )}

                        {/* Search Button */}
                        <ThaiButton
                            type="submit"
                            disabled={!selectedImage || searching}
                            className="w-full bg-blue-600 hover:bg-blue-700 text-white disabled:bg-gray-300"
                        >
                            {searching ? (
                                <>
                                    <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                                    กำลังค้นหา...
                                </>
                            ) : (
                                <>
                                    <Search className="w-5 h-5 mr-2" />
                                    ค้นหา
                                </>
                            )}
                        </ThaiButton>
                    </div>
                </form>

                {/* Results */}
                {results.length > 0 && (
                    <div className="space-y-4">
                        <h2 className="text-2xl font-bold text-gray-900">
                            ผลการค้นหา ({results.length} รายการ)
                        </h2>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                            {results.map((result) => (
                                <div
                                    key={result.photo_id}
                                    className="bg-white rounded-xl shadow-md overflow-hidden hover:shadow-lg transition-shadow"
                                >
                                    <div className="relative h-64">
                                        <img
                                            src={result.image_url}
                                            alt="Match"
                                            className="w-full h-full object-cover"
                                        />
                                    </div>
                                    <div className="p-4 space-y-2">
                                        <div className="flex items-center justify-between">
                                            <span className="text-sm font-medium text-gray-700">
                                                ความแม่นยำ
                                            </span>
                                            <span className="text-lg font-bold text-blue-600">
                                                {(result.similarity * 100).toFixed(1)}%
                                            </span>
                                        </div>
                                        {result.uploaded_at && (
                                            <div className="text-xs text-gray-500">
                                                <span className="font-medium">เวลาที่อัพโหลด:</span>{' '}
                                                {new Date(result.uploaded_at).toLocaleString('th-TH', {
                                                    dateStyle: 'short',
                                                    timeStyle: 'short'
                                                })}
                                            </div>
                                        )}
                                        {result.uploaded_by && result.uploaded_by !== 'anonymous' && (
                                            <div className="text-xs text-gray-500">
                                                <span className="font-medium">อัพโหลดโดย:</span> {result.uploaded_by}
                                            </div>
                                        )}
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>
                )}

                {results.length === 0 && !searching && imagePreview && !error && (
                    <div className="text-center py-12 bg-white rounded-xl shadow-md">
                        <User className="w-16 h-16 mx-auto mb-4 text-gray-400" />
                        <p className="text-gray-600">ไม่พบผลการค้นหาที่ตรงกัน</p>
                    </div>
                )}
            </div>
        </div>
    );
}
