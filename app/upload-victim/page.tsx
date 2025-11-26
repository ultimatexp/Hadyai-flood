"use client";

import { useState, useRef, useEffect } from "react";
import { detectFaceAndGetDescriptor, loadModels } from "@/lib/face-api";
import { Upload, Loader2, Check, X } from "lucide-react";
import { ThaiButton } from "@/components/ui/thai-button";

export default function UploadVictimPage() {
    const [selectedImages, setSelectedImages] = useState<File[]>([]);
    const [imagePreviews, setImagePreviews] = useState<string[]>([]);
    const [uploading, setUploading] = useState(false);
    const [success, setSuccess] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [uploadedCount, setUploadedCount] = useState(0);
    const [modelsLoaded, setModelsLoaded] = useState(false);
    const [loadingModels, setLoadingModels] = useState(true);

    // Load face-api models on mount
    useEffect(() => {
        async function loadFaceModels() {
            try {
                setLoadingModels(true);
                await loadModels();
                setModelsLoaded(true);
                setLoadingModels(false);
            } catch (err) {
                console.error("Failed to load face detection models:", err);
                setError("ไม่สามารถโหลดโมเดลตรวจจับใบหน้าได้");
                setLoadingModels(false);
            }
        }
        loadFaceModels();
    }, []);

    const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        const files = Array.from(e.target.files || []);

        // Validate file sizes
        const oversizedFiles = files.filter(f => f.size > 10 * 1024 * 1024);
        if (oversizedFiles.length > 0) {
            setError(`${oversizedFiles.length} ไฟล์มีขนาดเกิน 10MB`);
            return;
        }

        setSelectedImages(files);
        setError(null);
        setSuccess(false);

        // Generate previews for all files
        const previews: string[] = [];
        let loadedCount = 0;
        files.forEach(file => {
            const reader = new FileReader();
            reader.onloadend = () => {
                previews.push(reader.result as string);
                loadedCount++;
                if (loadedCount === files.length) {
                    setImagePreviews(previews);
                }
            };
            reader.readAsDataURL(file);
        });
    };

    const handleUpload = async (e: React.FormEvent) => {
        e.preventDefault();

        if (selectedImages.length === 0) {
            setError("กรุณาเลือกรูปภาพอย่างน้อย 1 รูป");
            return;
        }

        setUploading(true);
        setError(null);
        setUploadedCount(0);

        try {
            let successCount = 0;

            // Process each image
            for (let i = 0; i < selectedImages.length; i++) {
                const file = selectedImages[i];

                // Create temporary image element to extract face descriptor
                const img = new Image();
                // const imageBitmap = await createImageBitmap(file); // createImageBitmap is not directly used here
                img.src = URL.createObjectURL(file);
                await new Promise(resolve => img.onload = resolve);

                // Extract face embedding
                const descriptor = await detectFaceAndGetDescriptor(img);

                if (!descriptor) {
                    console.warn(`No face detected in image ${i + 1}`);
                    continue; // Skip this image if no face detected
                }

                // Upload to API
                const formData = new FormData();
                formData.append('image', file);
                formData.append('embedding', JSON.stringify(Array.from(descriptor)));

                const response = await fetch('/api/upload-victim-photo', {
                    method: 'POST',
                    body: formData,
                });

                const data = await response.json();

                if (data.success) {
                    successCount++;
                    setUploadedCount(successCount);
                }

                // Clean up
                URL.revokeObjectURL(img.src);
            }

            if (successCount > 0) {
                setSuccess(true);
                setSelectedImages([]);
                setImagePreviews([]);
                setError(successCount < selectedImages.length
                    ? `อัพโหลดสำเร็จ ${successCount} จาก ${selectedImages.length} รูป (บางรูปไม่พบใบหน้า)`
                    : null);
            } else {
                setError("ไม่พบใบหน้าในรูปภาพที่เลือก กรุณาอัพโหลดรูปที่เห็นใบหน้าชัดเจน");
            }
        } catch (err: any) {
            setError(err.message || "เกิดข้อผิดพลาดในการอัพโหลด");
        } finally {
            setUploading(false);
        }
    };

    if (loadingModels) {
        return (
            <div className="min-h-screen flex items-center justify-center flex-col gap-4">
                <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
                {loadingModels && <p className="text-gray-600">กำลังโหลดโมเดลตรวจจับใบหน้า...</p>}
            </div>
        );
    }

    return (
        <div className="min-h-screen bg-gradient-to-b from-blue-50 to-white py-8 px-4">
            <div className="max-w-2xl mx-auto">
                <div className="text-center mb-8">
                    <h1 className="text-3xl font-bold text-gray-900 mb-2">อัพโหลดรูปผู้ได้รับผลกระทบ</h1>
                    <p className="text-gray-600">อัพโหลดรูปภาพผู้ได้รับผลกระทบเพื่อให้ครอบครัวสามารถค้นหาได้</p>
                </div>

                <form onSubmit={handleUpload} className="bg-white rounded-xl shadow-lg p-6 space-y-6">
                    {/* Image Upload */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-2">
                            รูปภาพ (เลือกได้หลายรูป)
                        </label>
                        <div className="border-2 border-dashed border-gray-300 rounded-lg p-6 text-center hover:border-blue-500 transition-colors">
                            <input
                                type="file"
                                accept="image/*"
                                multiple
                                onChange={handleImageSelect}
                                className="hidden"
                                id="image-upload"
                            />
                            <label htmlFor="image-upload" className="cursor-pointer">
                                <Upload className="w-12 h-12 mx-auto mb-2 text-gray-400" />
                                <span className="text-gray-600">คลิกเพื่อเลือกรูปภาพ (หลายรูป)</span>
                                {selectedImages.length > 0 && (
                                    <p className="text-sm text-blue-600 mt-2">เลือกแล้ว {selectedImages.length} รูป</p>
                                )}
                            </label>
                        </div>
                    </div>

                    {/* Image Previews */}
                    {imagePreviews.length > 0 && (
                        <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                            {imagePreviews.map((preview, index) => (
                                <div key={index} className="relative">
                                    <img
                                        src={preview}
                                        alt={`Preview ${index + 1}`}
                                        className="w-full h-32 object-cover rounded-lg shadow-md"
                                    />
                                </div>
                            ))}
                        </div>
                    )}

                    {/* Success Message */}
                    {success && (
                        <div className="bg-green-50 border border-green-200 rounded-lg p-4 flex items-center gap-2 text-green-700">
                            <Check className="w-5 h-5" />
                            อัพโหลดสำเร็จ!
                        </div>
                    )}

                    {/* Error Message */}
                    {error && (
                        <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-center gap-2 text-red-700">
                            <X className="w-5 h-5" />
                            {error}
                        </div>
                    )}

                    {/* Upload Button */}
                    <ThaiButton
                        type="submit"
                        disabled={selectedImages.length === 0 || uploading}
                        className="w-full bg-blue-600 hover:bg-blue-700 text-white disabled:bg-gray-300"
                    >
                        {uploading ? (
                            <>
                                <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                                กำลังอัพโหลด... ({uploadedCount}/{selectedImages.length})
                            </>
                        ) : (
                            <>
                                <Upload className="w-5 h-5 mr-2" />
                                อัพโหลด {selectedImages.length > 0 ? `${selectedImages.length} รูป` : ''}
                            </>
                        )}
                    </ThaiButton>
                </form>
            </div>
        </div>
    );
}
